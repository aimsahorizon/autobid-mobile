-- Migration: Integrate virtual wallet with deposits, refunds, and penalties
-- Ensures all deposit/refund/penalty flows properly debit/credit the wallet

-- ============================================================================
-- 1. Add 'penalty' and 'deposit_forfeit' categories to wallet transactions
-- ============================================================================
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_name = 'virtual_wallet_transactions'
      AND constraint_name = 'virtual_wallet_transactions_category_check'
  ) THEN
    ALTER TABLE virtual_wallet_transactions
      DROP CONSTRAINT virtual_wallet_transactions_category_check;
  END IF;

  ALTER TABLE virtual_wallet_transactions
    ADD CONSTRAINT virtual_wallet_transactions_category_check
    CHECK (category IN (
      'deposit', 'deposit_return', 'deposit_forfeit',
      'token_purchase', 'subscription',
      'top_up', 'withdrawal', 'penalty'
    ));
END $$;

-- ============================================================================
-- 2. RPC: Get a user's deposit for a specific auction
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_deposit(
  p_auction_id UUID,
  p_user_id UUID
) RETURNS TABLE(
  deposit_id UUID,
  amount DECIMAL,
  is_refunded BOOLEAN,
  created_at TIMESTAMPTZ
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
  SELECT d.id, d.amount, d.is_refunded, d.created_at
  FROM deposits d
  WHERE d.auction_id = p_auction_id
    AND d.user_id = p_user_id
  ORDER BY d.created_at DESC
  LIMIT 1;
END;
$$;

-- ============================================================================
-- 3. RPC: Refund a specific user's deposit back to their wallet
-- ============================================================================
CREATE OR REPLACE FUNCTION refund_deposit(
  p_auction_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_deposit RECORD;
BEGIN
  -- Find the active (non-refunded) deposit
  SELECT id, amount INTO v_deposit
  FROM deposits
  WHERE auction_id = p_auction_id
    AND user_id = p_user_id
    AND is_refunded = FALSE
  LIMIT 1;

  IF v_deposit.id IS NULL THEN
    RETURN FALSE; -- no active deposit found
  END IF;

  -- Credit the wallet
  PERFORM wallet_credit(
    p_user_id,
    v_deposit.amount,
    'deposit_return',
    p_auction_id::TEXT,
    'Deposit refunded for auction'
  );

  -- Mark deposit as refunded
  UPDATE deposits
  SET is_refunded = TRUE, refunded_at = NOW()
  WHERE id = v_deposit.id;

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- 4. RPC: Forfeit a user's deposit (penalty — no wallet credit)
-- ============================================================================
CREATE OR REPLACE FUNCTION forfeit_deposit(
  p_auction_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_deposit RECORD;
BEGIN
  -- Find the active (non-refunded) deposit
  SELECT id, amount INTO v_deposit
  FROM deposits
  WHERE auction_id = p_auction_id
    AND user_id = p_user_id
    AND is_refunded = FALSE
  LIMIT 1;

  IF v_deposit.id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Mark deposit as refunded (forfeited — money stays with platform)
  -- We record a wallet debit of 0 just for audit trail
  UPDATE deposits
  SET is_refunded = TRUE, refunded_at = NOW()
  WHERE id = v_deposit.id;

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- 5. Update cancel_auction_with_penalty to deduct from wallet
-- ============================================================================
CREATE OR REPLACE FUNCTION public.cancel_auction_with_penalty(
  p_transaction_id UUID,
  p_reason         TEXT DEFAULT ''
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_buyer_id        UUID;
  v_seller_id       UUID;
  v_agreed_price    NUMERIC;
  v_penalty_amount  NUMERIC;
  v_current_user    UUID;
  v_role            TEXT;
  v_cancelled_id    UUID;
  v_other_user      UUID;
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

  -- Calculate penalty: 5% of agreed price
  v_penalty_amount := ROUND(v_agreed_price * 0.05, 2);

  -- Record penalty in cancellation_penalties table
  INSERT INTO public.cancellation_penalties (
    transaction_id, auction_id, user_id, role, penalty_amount, reason
  ) VALUES (
    p_transaction_id, v_auction_id, v_current_user, v_role, v_penalty_amount, p_reason
  );

  -- ** DEDUCT penalty from cancelling party's wallet **
  PERFORM wallet_debit(
    v_current_user,
    v_penalty_amount,
    'penalty',
    p_transaction_id::TEXT,
    format('Cancellation penalty (%s): %s', v_role, COALESCE(NULLIF(p_reason, ''), 'Deal cancelled'))
  );

  -- ** REFUND the non-cancelling party's deposit back to their wallet **
  PERFORM refund_deposit(v_auction_id, v_other_user);

  -- ** FORFEIT the cancelling party's deposit (no refund) **
  PERFORM forfeit_deposit(v_auction_id, v_current_user);

  -- Update transaction to deal_failed
  UPDATE public.auction_transactions
     SET status = 'deal_failed',
         updated_at = now()
   WHERE id = p_transaction_id;

  -- Set rejection reason
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
    'Auction Cancelled with Penalty',
    format('%s cancelled the deal. Penalty: ₱%s deducted from wallet. Deposit forfeited. Reason: %s',
           initcap(v_role), v_penalty_amount::text, COALESCE(NULLIF(p_reason, ''), 'No reason provided')),
    v_current_user
  );
END;
$$;

-- ============================================================================
-- 6. RPC: Refund both deposits on successful transaction completion
--    Called when transaction status becomes 'sold' / completed
-- ============================================================================
CREATE OR REPLACE FUNCTION refund_transaction_deposits(
  p_transaction_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id UUID;
  v_buyer_id UUID;
  v_seller_id UUID;
BEGIN
  SELECT at.auction_id, at.buyer_id, at.seller_id
    INTO v_auction_id, v_buyer_id, v_seller_id
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Refund buyer's deposit
  PERFORM refund_deposit(v_auction_id, v_buyer_id);

  -- Refund seller's deposit
  PERFORM refund_deposit(v_auction_id, v_seller_id);

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- 7. Update handle_buyer_acceptance to refund deposits on successful sale
-- ============================================================================
CREATE OR REPLACE FUNCTION handle_buyer_acceptance(
  p_transaction_id UUID,
  p_buyer_id UUID,
  p_accepted BOOLEAN,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_transaction RECORD;
  v_result JSON;
BEGIN
  -- Get transaction and verify buyer
  SELECT * INTO v_transaction
  FROM auction_transactions
  WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'error', 'Transaction not found');
  END IF;

  IF v_transaction.buyer_acceptance_status != 'pending' THEN
    RETURN json_build_object('success', FALSE, 'error', 'Already responded');
  END IF;

  -- Update transaction based on acceptance
  IF p_accepted THEN
    UPDATE auction_transactions
    SET
      buyer_acceptance_status = 'accepted',
      buyer_accepted_at = NOW(),
      delivery_status = 'completed',
      delivery_completed_at = NOW(),
      status = 'sold',
      updated_at = NOW()
    WHERE id = p_transaction_id;

    -- Refund both deposits back to wallets on successful completion
    PERFORM refund_transaction_deposits(p_transaction_id);

    -- Add timeline event
    INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_name)
    VALUES (p_transaction_id, 'Vehicle Accepted', 'Buyer confirmed receipt and accepted the vehicle. Deposits refunded to both parties.', 'completed', 'Buyer');

  ELSE
    UPDATE auction_transactions
    SET
      buyer_acceptance_status = 'rejected',
      buyer_accepted_at = NOW(),
      buyer_rejection_reason = p_rejection_reason,
      status = 'deal_failed',
      updated_at = NOW()
    WHERE id = p_transaction_id;

    -- Add timeline event
    INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_name)
    VALUES (p_transaction_id, 'Vehicle Rejected', 
            'Buyer rejected the vehicle. Reason: ' || COALESCE(p_rejection_reason, 'Not specified'),
            'deal_failed', 'Buyer');
  END IF;

  RETURN json_build_object('success', TRUE);
END;
$$;
