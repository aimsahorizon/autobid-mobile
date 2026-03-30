-- Migration: Policy acceptance, penalty system, reputation tracking, seller deposits
-- Implements the full policy enforcement framework for transaction safety

-- ============================================================
-- 1. Policy Acceptances — track when users accept policy versions
-- ============================================================
CREATE TABLE IF NOT EXISTS policy_acceptances (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  policy_type TEXT NOT NULL, -- 'bidding_rules', 'listing_rules', 'transaction_rules'
  policy_version INT NOT NULL DEFAULT 1,
  accepted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id, policy_type, policy_version)
);

CREATE INDEX IF NOT EXISTS idx_policy_acceptances_user
  ON policy_acceptances(user_id, policy_type);

-- ============================================================
-- 2. User Penalties — track suspensions and deposit deductions
-- ============================================================
CREATE TABLE IF NOT EXISTS user_penalties (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  penalty_type TEXT NOT NULL, -- 'suspension', 'deposit_deduction', 'permanent_ban'
  reason TEXT NOT NULL,
  -- For suspensions
  suspension_days INT,
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ,
  -- For deposit deductions
  deduction_percentage INT, -- 25, 50, 75, 100
  deduction_amount NUMERIC(12,2),
  -- Context
  transaction_id UUID,
  auction_id UUID,
  offense_number INT NOT NULL DEFAULT 1,
  is_permanent BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_penalties_user
  ON user_penalties(user_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_user_penalties_active
  ON user_penalties(user_id, ends_at)
  WHERE penalty_type = 'suspension';

-- ============================================================
-- 3. Unresponsive Reports — for response timer enforcement
-- ============================================================
CREATE TABLE IF NOT EXISTS unresponsive_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL,
  reporter_id UUID NOT NULL REFERENCES auth.users(id),
  reported_user_id UUID NOT NULL REFERENCES auth.users(id),
  reported_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  response_deadline TIMESTAMPTZ NOT NULL, -- reporter_at + 24h
  responded BOOLEAN NOT NULL DEFAULT FALSE,
  responded_at TIMESTAMPTZ,
  auto_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
  UNIQUE(transaction_id, reporter_id) -- one report per party per transaction
);

CREATE INDEX IF NOT EXISTS idx_unresponsive_reports_deadline
  ON unresponsive_reports(response_deadline)
  WHERE responded = FALSE AND auto_cancelled = FALSE;

-- ============================================================
-- 4. Transaction Activity Tracking — for inactivity detection
-- ============================================================
ALTER TABLE auction_transactions
  ADD COLUMN IF NOT EXISTS buyer_last_activity_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS seller_last_activity_at TIMESTAMPTZ;

-- ============================================================
-- 5. RPC: Check if user has accepted a policy version
-- ============================================================
CREATE OR REPLACE FUNCTION has_accepted_policy(
  p_user_id UUID,
  p_policy_type TEXT,
  p_policy_version INT DEFAULT 1
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM policy_acceptances
    WHERE user_id = p_user_id
      AND policy_type = p_policy_type
      AND policy_version = p_policy_version
  );
END;
$$;

-- ============================================================
-- 6. RPC: Accept a policy
-- ============================================================
CREATE OR REPLACE FUNCTION accept_policy(
  p_user_id UUID,
  p_policy_type TEXT,
  p_policy_version INT DEFAULT 1
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO policy_acceptances (user_id, policy_type, policy_version)
  VALUES (p_user_id, p_policy_type, p_policy_version)
  ON CONFLICT (user_id, policy_type, policy_version) DO NOTHING;
  RETURN TRUE;
END;
$$;

-- ============================================================
-- 7. RPC: Check if user is currently suspended
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

  RETURN QUERY SELECT FALSE, NULL::TIMESTAMPTZ, NULL::TEXT, FALSE;
END;
$$;

-- ============================================================
-- 8. RPC: Record a penalty with escalation logic (12-month rolling)
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
-- 9. RPC: Get user reputation stats (visible cross-role only)
-- ============================================================
CREATE OR REPLACE FUNCTION get_user_reputation(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total_bids INT;
  v_total_wins INT;
  v_bid_rate NUMERIC;
  v_total_transactions INT;
  v_completed_transactions INT;
  v_cancelled_transactions INT;
  v_success_rate NUMERIC;
  v_total_penalties INT;
  v_lifetime_penalties INT;
BEGIN
  -- Bidding stats (buyer)
  SELECT COUNT(*) INTO v_total_bids
  FROM bids WHERE user_id = p_user_id;

  SELECT COUNT(*) INTO v_total_wins
  FROM auction_transactions WHERE buyer_id = p_user_id;

  v_bid_rate := CASE WHEN v_total_bids > 0
    THEN ROUND((v_total_wins::NUMERIC / v_total_bids) * 100, 1)
    ELSE 0 END;

  -- Transaction stats (buyer + seller)
  SELECT COUNT(*) INTO v_total_transactions
  FROM auction_transactions
  WHERE buyer_id = p_user_id OR seller_id = p_user_id;

  SELECT COUNT(*) INTO v_completed_transactions
  FROM auction_transactions
  WHERE (buyer_id = p_user_id OR seller_id = p_user_id)
    AND status = 'sold';

  SELECT COUNT(*) INTO v_cancelled_transactions
  FROM auction_transactions
  WHERE (buyer_id = p_user_id OR seller_id = p_user_id)
    AND status = 'deal_failed';

  v_success_rate := CASE WHEN v_total_transactions > 0
    THEN ROUND((v_completed_transactions::NUMERIC / v_total_transactions) * 100, 1)
    ELSE 0 END;

  -- Penalty history (lifetime — always marked on reputation)
  SELECT COUNT(*) INTO v_lifetime_penalties
  FROM user_penalties
  WHERE user_id = p_user_id
    AND penalty_type IN ('suspension', 'permanent_ban');

  -- 12-month rolling penalties
  SELECT COUNT(*) INTO v_total_penalties
  FROM user_penalties
  WHERE user_id = p_user_id
    AND penalty_type IN ('suspension', 'permanent_ban')
    AND created_at > now() - INTERVAL '12 months';

  RETURN json_build_object(
    'total_bids', v_total_bids,
    'total_wins', v_total_wins,
    'bid_rate', v_bid_rate,
    'total_transactions', v_total_transactions,
    'completed_transactions', v_completed_transactions,
    'cancelled_transactions', v_cancelled_transactions,
    'success_rate', v_success_rate,
    'recent_penalties', v_total_penalties,
    'lifetime_penalties', v_lifetime_penalties
  );
END;
$$;

-- ============================================================
-- 10. RPC: Report unresponsive user
-- ============================================================
CREATE OR REPLACE FUNCTION report_unresponsive(
  p_transaction_id UUID,
  p_reporter_id UUID,
  p_reported_user_id UUID
) RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_report_id UUID;
  v_deadline TIMESTAMPTZ;
BEGIN
  v_deadline := now() + INTERVAL '24 hours';

  INSERT INTO unresponsive_reports (
    transaction_id, reporter_id, reported_user_id, response_deadline
  ) VALUES (
    p_transaction_id, p_reporter_id, p_reported_user_id, v_deadline
  )
  ON CONFLICT (transaction_id, reporter_id)
  DO UPDATE SET
    reported_at = now(),
    response_deadline = v_deadline,
    responded = FALSE,
    responded_at = NULL,
    auto_cancelled = FALSE
  RETURNING id INTO v_report_id;

  RETURN json_build_object(
    'report_id', v_report_id,
    'deadline', v_deadline
  );
END;
$$;

-- ============================================================
-- 11. RPC: Mark user as responded (clears unresponsive report)
-- ============================================================
CREATE OR REPLACE FUNCTION mark_user_responded(
  p_transaction_id UUID,
  p_user_id UUID
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE unresponsive_reports
  SET responded = TRUE, responded_at = now()
  WHERE transaction_id = p_transaction_id
    AND reported_user_id = p_user_id
    AND responded = FALSE;

  RETURN FOUND;
END;
$$;

-- ============================================================
-- 12. RLS Policies
-- ============================================================
ALTER TABLE policy_acceptances ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_penalties ENABLE ROW LEVEL SECURITY;
ALTER TABLE unresponsive_reports ENABLE ROW LEVEL SECURITY;

-- Users can read their own acceptances
CREATE POLICY policy_acceptances_read ON policy_acceptances
  FOR SELECT USING (auth.uid() = user_id);

-- Users can read their own penalties
CREATE POLICY user_penalties_read ON user_penalties
  FOR SELECT USING (auth.uid() = user_id);

-- Users can read reports they're involved in
CREATE POLICY unresponsive_reports_read ON unresponsive_reports
  FOR SELECT USING (
    auth.uid() = reporter_id OR auth.uid() = reported_user_id
  );
