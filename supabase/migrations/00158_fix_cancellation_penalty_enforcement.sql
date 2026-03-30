-- ============================================================
-- Fix cancellation penalty enforcement:
-- 1. cancel_auction_with_penalty now calls record_penalty() for
--    immediate account suspension
-- 2. Deposit penalty: 25% deducted, only 75% returned (not 5%
--    of agreed price from wallet)
-- 3. record_penalty sets users.is_active = false for suspended
--    accounts so login is blocked immediately
-- ============================================================

-- ============================================================
-- 1. Update record_penalty to also set users.is_active = false
-- ============================================================
CREATE OR REPLACE FUNCTION record_penalty(
  p_user_id UUID,
  p_reason TEXT,
  p_transaction_id UUID DEFAULT NULL,
  p_auction_id UUID DEFAULT NULL,
  p_deduction_percentage INT DEFAULT NULL,
  p_deduction_amount NUMERIC DEFAULT NULL
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_offense_count INT;
  v_suspension_days INT;
  v_is_permanent BOOLEAN := FALSE;
  v_ends_at TIMESTAMPTZ;
  v_penalty_id UUID;
BEGIN
  -- Count offenses in 12-month rolling window
  SELECT COUNT(*) + 1 INTO v_offense_count
  FROM user_penalties
  WHERE user_id = p_user_id
    AND penalty_type IN ('suspension', 'permanent_ban')
    AND created_at > now() - INTERVAL '12 months';

  -- Determine suspension duration based on offense number
  CASE v_offense_count
    WHEN 1 THEN v_suspension_days := 3;
    WHEN 2 THEN v_suspension_days := 7;
    WHEN 3 THEN v_suspension_days := 30;
    WHEN 4 THEN v_suspension_days := 90;
    ELSE
      v_suspension_days := 0;
      v_is_permanent := TRUE;
  END CASE;

  IF v_is_permanent THEN
    v_ends_at := NULL;
  ELSE
    v_ends_at := now() + (v_suspension_days || ' days')::INTERVAL;
  END IF;

  -- Insert suspension penalty
  INSERT INTO user_penalties (
    user_id, penalty_type, reason,
    suspension_days, starts_at, ends_at,
    transaction_id, auction_id,
    offense_number, is_permanent
  ) VALUES (
    p_user_id,
    CASE WHEN v_is_permanent THEN 'permanent_ban' ELSE 'suspension' END,
    p_reason,
    v_suspension_days,
    now(),
    v_ends_at,
    p_transaction_id,
    p_auction_id,
    v_offense_count,
    v_is_permanent
  ) RETURNING id INTO v_penalty_id;

  -- If there's a deposit deduction, record separately
  IF p_deduction_percentage IS NOT NULL AND p_deduction_percentage > 0 THEN
    INSERT INTO user_penalties (
      user_id, penalty_type, reason,
      deduction_percentage, deduction_amount,
      transaction_id, auction_id,
      offense_number, is_permanent
    ) VALUES (
      p_user_id, 'deposit_deduction', p_reason,
      p_deduction_percentage, p_deduction_amount,
      p_transaction_id, p_auction_id,
      v_offense_count, FALSE
    );
  END IF;

  -- ** Immediately deactivate account so login is blocked **
  UPDATE users SET is_active = false WHERE id = p_user_id;

  RETURN json_build_object(
    'penalty_id', v_penalty_id,
    'offense_number', v_offense_count,
    'suspension_days', v_suspension_days,
    'is_permanent', v_is_permanent,
    'ends_at', v_ends_at
  );
END;
$$;

-- ============================================================
-- 2. Reactivation check: cron/edge function should call this
--    periodically to reactivate expired suspensions.
--    For now, also check at login time via is_user_suspended.
-- ============================================================
CREATE OR REPLACE FUNCTION reactivate_expired_suspensions()
RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INT;
BEGIN
  -- Reactivate users whose suspension has expired and who are not permanently banned
  WITH expired AS (
    SELECT DISTINCT up.user_id
    FROM user_penalties up
    WHERE up.user_id IN (SELECT id FROM users WHERE is_active = false)
      AND up.penalty_type = 'suspension'
      AND up.ends_at IS NOT NULL
      AND up.ends_at <= now()
      AND NOT EXISTS (
        -- Still has active/future suspension
        SELECT 1 FROM user_penalties up2
        WHERE up2.user_id = up.user_id
          AND up2.penalty_type IN ('suspension', 'permanent_ban')
          AND (up2.is_permanent = true OR up2.ends_at > now())
      )
  )
  UPDATE users SET is_active = true
  WHERE id IN (SELECT user_id FROM expired);

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

-- ============================================================
-- 3. Update cancel_auction_with_penalty:
--    - 25% deposit deduction instead of 5% agreed price
--    - Call record_penalty() for immediate suspension
--    - Return 75% of deposit to canceller
-- ============================================================
DROP FUNCTION IF EXISTS public.cancel_auction_with_penalty(UUID, TEXT);

CREATE OR REPLACE FUNCTION public.cancel_auction_with_penalty(
  p_transaction_id UUID,
  p_reason         TEXT DEFAULT ''
)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_buyer_id        UUID;
  v_seller_id       UUID;
  v_agreed_price    NUMERIC;
  v_current_user    UUID;
  v_role            TEXT;
  v_other_user      UUID;
  v_deposit         RECORD;
  v_deduction_pct   INT := 25;
  v_deduction_amt   NUMERIC;
  v_refund_amt      NUMERIC;
  v_cancelled_id    UUID;
  v_penalty_result  JSON;
BEGIN
  v_current_user := auth.uid();

  SELECT at.auction_id, at.buyer_id, at.seller_id, at.agreed_price
    INTO v_auction_id, v_buyer_id, v_seller_id, v_agreed_price
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Determine who is cancelling
  IF v_current_user = v_buyer_id THEN
    v_role := 'buyer';
    v_other_user := v_seller_id;
  ELSIF v_current_user = v_seller_id THEN
    v_role := 'seller';
    v_other_user := v_buyer_id;
  ELSE
    RAISE EXCEPTION 'Only buyer or seller can cancel';
  END IF;

  -- Find the canceller's active deposit
  SELECT id, amount INTO v_deposit
  FROM deposits
  WHERE auction_id = v_auction_id
    AND user_id = v_current_user
    AND is_refunded = FALSE
  LIMIT 1;

  -- Calculate 25% deduction from deposit
  IF v_deposit.id IS NOT NULL THEN
    v_deduction_amt := ROUND(v_deposit.amount * v_deduction_pct / 100.0, 2);
    v_refund_amt := v_deposit.amount - v_deduction_amt;

    -- Return 75% of deposit to canceller's wallet
    IF v_refund_amt > 0 THEN
      PERFORM wallet_credit(
        v_current_user,
        v_refund_amt,
        'deposit_return',
        v_auction_id::TEXT,
        format('Partial deposit refund (75%%) after cancellation penalty. 25%% (₱%s) deducted as penalty.',
               v_deduction_amt::TEXT)
      );
    END IF;

    -- Mark deposit as refunded (the 25% stays with platform)
    UPDATE deposits
    SET is_refunded = TRUE, refunded_at = NOW()
    WHERE id = v_deposit.id;
  ELSE
    v_deduction_amt := 0;
    v_refund_amt := 0;
  END IF;

  -- Record in cancellation_penalties table for stats
  INSERT INTO public.cancellation_penalties (
    transaction_id, auction_id, user_id, role, penalty_amount, reason
  ) VALUES (
    p_transaction_id, v_auction_id, v_current_user, v_role, v_deduction_amt, p_reason
  );

  -- ** Record penalty with suspension via record_penalty() **
  -- This also sets users.is_active = false
  v_penalty_result := record_penalty(
    p_user_id := v_current_user,
    p_reason := format('Cancelled transaction as %s. Reason: %s', v_role, COALESCE(NULLIF(p_reason, ''), 'No reason provided')),
    p_transaction_id := p_transaction_id,
    p_auction_id := v_auction_id,
    p_deduction_percentage := v_deduction_pct,
    p_deduction_amount := v_deduction_amt
  );

  -- ** REFUND the non-cancelling party's deposit in full **
  PERFORM refund_deposit(v_auction_id, v_other_user);

  -- Update transaction to deal_failed
  UPDATE public.auction_transactions
     SET status = 'deal_failed',
         updated_at = now()
   WHERE id = p_transaction_id;

  -- Set rejection reason and who cancelled
  IF v_role = 'buyer' THEN
    UPDATE public.auction_transactions
       SET buyer_rejection_reason = p_reason,
           buyer_acceptance_status = 'rejected'
     WHERE id = p_transaction_id;
  ELSE
    UPDATE public.auction_transactions
       SET seller_rejection_reason = p_reason
     WHERE id = p_transaction_id;
  END IF;

  -- Update auction status to cancelled
  SELECT id INTO v_cancelled_id
    FROM public.auction_statuses
   WHERE status_name = 'cancelled'
   LIMIT 1;

  IF v_cancelled_id IS NOT NULL THEN
    UPDATE public.auctions
       SET status_id = v_cancelled_id,
           updated_at = now()
     WHERE id = v_auction_id;
  END IF;

  -- Add timeline event
  INSERT INTO public.transaction_timeline (
    transaction_id, event_type, title, description, actor_id
  ) VALUES (
    p_transaction_id,
    'cancelled',
    'Transaction Cancelled with Penalty',
    format('%s cancelled the deal. 25%% deposit deduction (₱%s). Account suspended. Reason: %s',
           initcap(v_role), v_deduction_amt::text, COALESCE(NULLIF(p_reason, ''), 'No reason provided')),
    v_current_user
  );

  RETURN v_penalty_result;
END;
$$;

-- ============================================================
-- 4. Update is_user_suspended to also reactivate expired
--    suspensions at check time (self-healing)
-- ============================================================
CREATE OR REPLACE FUNCTION is_user_suspended(p_user_id UUID)
RETURNS TABLE(
  is_suspended BOOLEAN,
  suspension_ends_at TIMESTAMPTZ,
  reason TEXT,
  is_permanent BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- Check permanent ban first
  IF EXISTS (
    SELECT 1 FROM user_penalties
    WHERE user_id = p_user_id
      AND is_permanent = TRUE
      AND penalty_type IN ('permanent_ban', 'suspension')
  ) THEN
    RETURN QUERY
    SELECT TRUE, NULL::TIMESTAMPTZ,
           up.reason, TRUE
    FROM user_penalties up
    WHERE up.user_id = p_user_id AND up.is_permanent = TRUE
    ORDER BY up.created_at DESC LIMIT 1;
    RETURN;
  END IF;

  -- Check active suspension
  IF EXISTS (
    SELECT 1 FROM user_penalties
    WHERE user_id = p_user_id
      AND penalty_type = 'suspension'
      AND ends_at > now()
  ) THEN
    RETURN QUERY
    SELECT TRUE, up.ends_at, up.reason, FALSE
    FROM user_penalties up
    WHERE up.user_id = p_user_id
      AND up.penalty_type = 'suspension'
      AND up.ends_at > now()
    ORDER BY up.ends_at DESC LIMIT 1;
    RETURN;
  END IF;

  -- No active suspension — reactivate account if it was deactivated
  UPDATE users SET is_active = true
  WHERE id = p_user_id AND is_active = false
    AND NOT EXISTS (
      SELECT 1 FROM user_penalties
      WHERE user_id = p_user_id
        AND (is_permanent = true OR (penalty_type = 'suspension' AND ends_at > now()))
    );

  RETURN QUERY SELECT FALSE, NULL::TIMESTAMPTZ, NULL::TEXT, FALSE;
END;
$$;
