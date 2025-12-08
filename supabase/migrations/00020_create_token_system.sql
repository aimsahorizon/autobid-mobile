-- ============================================================================
-- AutoBid Mobile - Migration 00020: Pricing and Token Management System
-- Implements listing/bidding token consumption and subscription management
-- ============================================================================

-- ============================================================================
-- SECTION 1: Create Token Tables
-- ============================================================================

-- User token balances table
CREATE TABLE IF NOT EXISTS user_token_balances (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  bidding_tokens INT DEFAULT 0 CHECK (bidding_tokens >= 0),
  listing_tokens INT DEFAULT 0 CHECK (listing_tokens >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User subscriptions table
CREATE TABLE IF NOT EXISTS user_subscriptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('free', 'pro_basic_monthly', 'pro_plus_monthly', 'pro_basic_yearly', 'pro_plus_yearly')),
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ,
  is_active BOOLEAN DEFAULT TRUE,
  cancelled_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Unique constraint: Only one active subscription per user
CREATE UNIQUE INDEX IF NOT EXISTS idx_user_subscriptions_active_user
  ON user_subscriptions(user_id)
  WHERE is_active = TRUE;

-- Token transactions log (audit trail)
CREATE TABLE IF NOT EXISTS token_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_type TEXT NOT NULL CHECK (token_type IN ('bidding', 'listing')),
  amount INT NOT NULL, -- Positive for additions, negative for consumption
  price DECIMAL(10, 2) DEFAULT 0,
  transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'subscription', 'consumed', 'refund')),
  reference_id UUID, -- Reference to listing_id or bid_id if consumed
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscription renewal history
CREATE TABLE IF NOT EXISTS subscription_renewals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  subscription_id UUID NOT NULL REFERENCES user_subscriptions(id) ON DELETE CASCADE,
  renewed_at TIMESTAMPTZ DEFAULT NOW(),
  next_billing_date TIMESTAMPTZ,
  amount DECIMAL(10, 2) NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'pending')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 2: Indexes for Performance
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id
  ON user_subscriptions(user_id);

CREATE INDEX IF NOT EXISTS idx_user_subscriptions_is_active
  ON user_subscriptions(is_active);

CREATE INDEX IF NOT EXISTS idx_token_transactions_user_id
  ON token_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_token_transactions_created_at
  ON token_transactions(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_subscription_renewals_subscription_id
  ON subscription_renewals(subscription_id);

-- ============================================================================
-- SECTION 3: Triggers for updated_at
-- ============================================================================

CREATE TRIGGER update_user_token_balances_updated_at
  BEFORE UPDATE ON user_token_balances
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_subscriptions_updated_at
  BEFORE UPDATE ON user_subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SECTION 4: Row Level Security (RLS)
-- ============================================================================

ALTER TABLE user_token_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_renewals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_token_balances
CREATE POLICY user_token_balances_select_own
  ON user_token_balances FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY user_token_balances_insert_own
  ON user_token_balances FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Note: UPDATE allowed through RPC functions only (SECURITY DEFINER bypass RLS)

-- RLS Policies for user_subscriptions
CREATE POLICY user_subscriptions_select_own
  ON user_subscriptions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY user_subscriptions_insert_own
  ON user_subscriptions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY user_subscriptions_update_own
  ON user_subscriptions FOR UPDATE
  USING (user_id = auth.uid());

-- RLS Policies for token_transactions
CREATE POLICY token_transactions_select_own
  ON token_transactions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY token_transactions_insert_own
  ON token_transactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- RLS Policies for subscription_renewals
CREATE POLICY subscription_renewals_select_own
  ON subscription_renewals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_subscriptions
      WHERE user_subscriptions.id = subscription_id
      AND user_subscriptions.user_id = auth.uid()
    )
  );

-- ============================================================================
-- SECTION 5: Function - Initialize Tokens for New Users
-- ============================================================================

-- Automatically grant new users starter tokens (10 bidding, 1 listing)
CREATE OR REPLACE FUNCTION initialize_user_tokens()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert token balance with starter tokens
  INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
  VALUES (NEW.id, 10, 1)
  ON CONFLICT (user_id) DO NOTHING;

  -- Insert free subscription
  IF NOT EXISTS (
    SELECT 1 FROM user_subscriptions
    WHERE user_id = NEW.id AND is_active = TRUE
  ) THEN
    INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
    VALUES (NEW.id, 'free', TRUE, NOW());
  END IF;

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error but don't fail user creation
    RAISE WARNING 'Failed to initialize tokens for user %: %', NEW.id, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger on auth.users INSERT
DROP TRIGGER IF EXISTS on_user_created_initialize_tokens ON auth.users;
CREATE TRIGGER on_user_created_initialize_tokens
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION initialize_user_tokens();

-- ============================================================================
-- SECTION 6: Function - Consume Listing Token
-- ============================================================================

CREATE OR REPLACE FUNCTION consume_listing_token(p_user_id UUID, p_reference_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_balance INT;
BEGIN
  -- Get current balance (with row lock to prevent race conditions)
  SELECT listing_tokens INTO v_current_balance
  FROM user_token_balances
  WHERE user_id = p_user_id
  FOR UPDATE;

  -- Return false if no balance record exists
  IF v_current_balance IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Check if user has enough tokens
  IF v_current_balance < 1 THEN
    RETURN FALSE;
  END IF;

  -- Deduct token atomically
  UPDATE user_token_balances
  SET listing_tokens = listing_tokens - 1,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Log consumption transaction
  INSERT INTO token_transactions (user_id, token_type, amount, transaction_type, reference_id)
  VALUES (p_user_id, 'listing', -1, 'consumed', p_reference_id);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION consume_listing_token TO authenticated;

-- ============================================================================
-- SECTION 7: Function - Consume Bidding Token
-- ============================================================================

CREATE OR REPLACE FUNCTION consume_bidding_token(p_user_id UUID, p_reference_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
  v_current_balance INT;
BEGIN
  -- Get current balance (with row lock)
  SELECT bidding_tokens INTO v_current_balance
  FROM user_token_balances
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_current_balance IS NULL THEN
    RETURN FALSE;
  END IF;

  IF v_current_balance < 1 THEN
    RETURN FALSE;
  END IF;

  -- Deduct token
  UPDATE user_token_balances
  SET bidding_tokens = bidding_tokens - 1,
      updated_at = NOW()
  WHERE user_id = p_user_id;

  -- Log transaction
  INSERT INTO token_transactions (user_id, token_type, amount, transaction_type, reference_id)
  VALUES (p_user_id, 'bidding', -1, 'consumed', p_reference_id);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION consume_bidding_token TO authenticated;

-- ============================================================================
-- SECTION 8: Function - Add Tokens (Purchases/Subscriptions)
-- ============================================================================

CREATE OR REPLACE FUNCTION add_tokens(
  p_user_id UUID,
  p_token_type TEXT,
  p_amount INT,
  p_price DECIMAL,
  p_transaction_type TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
  -- Validate token type
  IF p_token_type NOT IN ('bidding', 'listing') THEN
    RETURN FALSE;
  END IF;

  -- Update balance based on token type
  IF p_token_type = 'bidding' THEN
    UPDATE user_token_balances
    SET bidding_tokens = bidding_tokens + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;
  ELSIF p_token_type = 'listing' THEN
    UPDATE user_token_balances
    SET listing_tokens = listing_tokens + p_amount,
        updated_at = NOW()
    WHERE user_id = p_user_id;
  END IF;

  -- Log transaction
  INSERT INTO token_transactions (user_id, token_type, amount, price, transaction_type)
  VALUES (p_user_id, p_token_type, p_amount, p_price, p_transaction_type);

  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION add_tokens TO authenticated;

-- ============================================================================
-- SECTION 9: Function - Renew Subscription Tokens (Scheduled Job)
-- ============================================================================

-- This function should be called by a scheduled job (Supabase Edge Function + cron)
-- to renew tokens for active subscriptions monthly/yearly
CREATE OR REPLACE FUNCTION renew_subscription_tokens()
RETURNS VOID AS $$
DECLARE
  v_subscription RECORD;
  v_bidding_tokens INT;
  v_listing_tokens INT;
BEGIN
  -- Loop through active subscriptions that need renewal
  FOR v_subscription IN
    SELECT * FROM user_subscriptions
    WHERE is_active = TRUE
      AND plan != 'free'
      AND end_date IS NOT NULL
      AND end_date <= NOW()
  LOOP
    -- Determine token amounts based on plan
    CASE v_subscription.plan
      WHEN 'pro_basic_monthly', 'pro_basic_yearly' THEN
        v_bidding_tokens := 50;
        v_listing_tokens := 3;
      WHEN 'pro_plus_monthly', 'pro_plus_yearly' THEN
        v_bidding_tokens := 250;
        v_listing_tokens := 10;
      ELSE
        v_bidding_tokens := 0;
        v_listing_tokens := 0;
    END CASE;

    -- Add tokens
    PERFORM add_tokens(v_subscription.user_id, 'bidding', v_bidding_tokens, 0, 'subscription');
    PERFORM add_tokens(v_subscription.user_id, 'listing', v_listing_tokens, 0, 'subscription');

    -- Update subscription end date
    UPDATE user_subscriptions
    SET end_date = CASE
      WHEN plan LIKE '%yearly%' THEN end_date + INTERVAL '1 year'
      ELSE end_date + INTERVAL '1 month'
    END,
    updated_at = NOW()
    WHERE id = v_subscription.id;

    -- Log renewal
    INSERT INTO subscription_renewals (subscription_id, next_billing_date, amount, status)
    VALUES (
      v_subscription.id,
      CASE
        WHEN v_subscription.plan LIKE '%yearly%' THEN NOW() + INTERVAL '1 year'
        ELSE NOW() + INTERVAL '1 month'
      END,
      0, -- Amount should come from payment processor
      'success'
    );
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SECTION 10: Backfill Existing Users with Tokens
-- ============================================================================

-- Give all existing users starter tokens if they don't have any
DO $$
DECLARE
  v_user RECORD;
BEGIN
  FOR v_user IN
    SELECT id FROM users
    WHERE NOT EXISTS (
      SELECT 1 FROM user_token_balances WHERE user_id = users.id
    )
  LOOP
    INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
    VALUES (v_user.id, 10, 1);

    INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
    VALUES (v_user.id, 'free', TRUE, NOW())
    ON CONFLICT DO NOTHING;
  END LOOP;

  RAISE NOTICE 'Backfilled tokens for existing users';
END $$;

-- ============================================================================
-- SECTION 11: Verification Queries
-- ============================================================================

-- Check token balances
-- SELECT u.username, utb.bidding_tokens, utb.listing_tokens
-- FROM users u
-- JOIN user_token_balances utb ON u.id = utb.user_id
-- LIMIT 10;

-- Check subscriptions
-- SELECT u.username, us.plan, us.is_active, us.start_date, us.end_date
-- FROM users u
-- JOIN user_subscriptions us ON u.id = us.user_id
-- LIMIT 10;

-- Check recent token transactions
-- SELECT tt.*, u.username
-- FROM token_transactions tt
-- JOIN users u ON tt.user_id = u.id
-- ORDER BY tt.created_at DESC
-- LIMIT 20;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
