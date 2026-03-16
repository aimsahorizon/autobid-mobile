-- ============================================================================
-- AutoBid Mobile - Migration 00128: Forward fix for subscription plans and
-- token balance guards on existing databases.
--
-- Purpose:
-- 1. Migrate legacy pro_* plan values to silver/gold values.
-- 2. Replace the user_subscriptions plan constraint for existing databases.
-- 3. Harden token RPCs so missing balance rows are auto-created before use.
-- ============================================================================

-- Replace existing plan check constraints first so normalization can run safely.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT conname
    FROM pg_constraint
    WHERE conrelid = 'user_subscriptions'::regclass
      AND contype = 'c'
      AND pg_get_constraintdef(oid) ILIKE '%plan%'
  LOOP
    EXECUTE format('ALTER TABLE user_subscriptions DROP CONSTRAINT %I', r.conname);
  END LOOP;
END $$;

-- Temporary mixed constraint (legacy + new values) to support safe transition.
ALTER TABLE user_subscriptions
  ADD CONSTRAINT user_subscriptions_plan_check
  CHECK (
    plan IN (
      'free',
      'pro_basic_monthly',
      'pro_basic_yearly',
      'pro_plus_monthly',
      'pro_plus_yearly',
      'silver_monthly',
      'silver_yearly',
      'gold_monthly',
      'gold_yearly'
    )
  );

-- Normalize existing subscription plan values.
UPDATE user_subscriptions
SET plan = CASE plan
  WHEN 'pro_basic_monthly' THEN 'silver_monthly'
  WHEN 'pro_basic_yearly' THEN 'silver_yearly'
  WHEN 'pro_plus_monthly' THEN 'gold_monthly'
  WHEN 'pro_plus_yearly' THEN 'gold_yearly'
  ELSE plan
END
WHERE plan IN (
  'pro_basic_monthly',
  'pro_basic_yearly',
  'pro_plus_monthly',
  'pro_plus_yearly'
);

-- Tighten to new plan values only after data normalization.
ALTER TABLE user_subscriptions
  DROP CONSTRAINT IF EXISTS user_subscriptions_plan_check;

ALTER TABLE user_subscriptions
  ADD CONSTRAINT user_subscriptions_plan_check
  CHECK (plan IN ('free', 'silver_monthly', 'silver_yearly', 'gold_monthly', 'gold_yearly'));

-- Backfill any users still missing token balances or active subscriptions.
INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
SELECT u.id, 10, 1
FROM users u
WHERE NOT EXISTS (
  SELECT 1 FROM user_token_balances utb WHERE utb.user_id = u.id
)
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
SELECT u.id, 'free', TRUE, NOW()
FROM users u
WHERE NOT EXISTS (
  SELECT 1
  FROM user_subscriptions us
  WHERE us.user_id = u.id AND us.is_active = TRUE
)
ON CONFLICT DO NOTHING;

CREATE OR REPLACE FUNCTION consume_listing_token(p_user_id UUID, p_reference_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_balance INT;
BEGIN
  INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
  VALUES (p_user_id, 10, 1)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT listing_tokens INTO v_current_balance
  FROM user_token_balances
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_current_balance IS NULL OR v_current_balance < 1 THEN
    RETURN FALSE;
  END IF;

  UPDATE user_token_balances
  SET listing_tokens = listing_tokens - 1,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  INSERT INTO token_transactions (user_id, token_type, amount, transaction_type, reference_id)
  VALUES (p_user_id, 'listing', -1, 'consumed', p_reference_id);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION consume_listing_token TO authenticated;

CREATE OR REPLACE FUNCTION consume_bidding_token(p_user_id UUID, p_reference_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_balance INT;
BEGIN
  INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
  VALUES (p_user_id, 10, 1)
  ON CONFLICT (user_id) DO NOTHING;

  SELECT bidding_tokens INTO v_current_balance
  FROM user_token_balances
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_current_balance IS NULL OR v_current_balance < 1 THEN
    RETURN FALSE;
  END IF;

  UPDATE user_token_balances
  SET bidding_tokens = bidding_tokens - 1,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  INSERT INTO token_transactions (user_id, token_type, amount, transaction_type, reference_id)
  VALUES (p_user_id, 'bidding', -1, 'consumed', p_reference_id);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION consume_bidding_token TO authenticated;

CREATE OR REPLACE FUNCTION add_tokens(
  p_user_id UUID,
  p_token_type TEXT,
  p_amount INT,
  p_price DECIMAL,
  p_transaction_type TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  IF p_token_type NOT IN ('bidding', 'listing') THEN
    RETURN FALSE;
  END IF;

  INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
  VALUES (p_user_id, 10, 1)
  ON CONFLICT (user_id) DO NOTHING;

  IF p_token_type = 'bidding' THEN
    UPDATE user_token_balances
    SET bidding_tokens = bidding_tokens + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;
  ELSE
    UPDATE user_token_balances
    SET listing_tokens = listing_tokens + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;

  INSERT INTO token_transactions (user_id, token_type, amount, price, transaction_type)
  VALUES (p_user_id, p_token_type, p_amount, p_price, p_transaction_type);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION add_tokens TO authenticated;

CREATE OR REPLACE FUNCTION renew_subscription_tokens()
RETURNS VOID AS $$
DECLARE
  v_subscription RECORD;
  v_bidding_tokens INT;
  v_listing_tokens INT;
BEGIN
  FOR v_subscription IN
    SELECT * FROM user_subscriptions
    WHERE is_active = TRUE
      AND plan != 'free'
      AND end_date IS NOT NULL
      AND end_date <= NOW()
  LOOP
    CASE v_subscription.plan
      WHEN 'silver_monthly', 'silver_yearly' THEN
        v_bidding_tokens := 60;
        v_listing_tokens := 3;
      WHEN 'gold_monthly', 'gold_yearly' THEN
        v_bidding_tokens := 250;
        v_listing_tokens := 10;
      ELSE
        v_bidding_tokens := 0;
        v_listing_tokens := 0;
    END CASE;

    PERFORM add_tokens(v_subscription.user_id, 'bidding', v_bidding_tokens, 0, 'subscription');
    PERFORM add_tokens(v_subscription.user_id, 'listing', v_listing_tokens, 0, 'subscription');

    UPDATE user_subscriptions
    SET end_date = CASE
      WHEN plan LIKE '%yearly%' THEN end_date + INTERVAL '1 year'
      ELSE end_date + INTERVAL '1 month'
    END,
    updated_at = NOW()
    WHERE id = v_subscription.id;

    INSERT INTO subscription_renewals (subscription_id, next_billing_date, amount, status)
    VALUES (
      v_subscription.id,
      CASE
        WHEN v_subscription.plan LIKE '%yearly%' THEN NOW() + INTERVAL '1 year'
        ELSE NOW() + INTERVAL '1 month'
      END,
      0,
      'success'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;