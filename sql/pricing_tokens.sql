-- Pricing and Token Management System

-- User token balances
CREATE TABLE IF NOT EXISTS user_token_balances (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    bidding_tokens INT DEFAULT 0 CHECK (bidding_tokens >= 0),
    listing_tokens INT DEFAULT 0 CHECK (listing_tokens >= 0),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User subscriptions
CREATE TABLE IF NOT EXISTS user_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan TEXT NOT NULL CHECK (plan IN ('free', 'pro_basic_monthly', 'pro_plus_monthly', 'pro_basic_yearly', 'pro_plus_yearly')),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    cancelled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, is_active)
);

-- Token transactions log
CREATE TABLE IF NOT EXISTS token_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    token_type TEXT NOT NULL CHECK (token_type IN ('bidding', 'listing')),
    amount INT NOT NULL,
    price DECIMAL(10, 2) DEFAULT 0,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'subscription', 'consumed', 'refund')),
    reference_id UUID, -- Reference to listing_id or bid_id if consumed
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Subscription renewal history
CREATE TABLE IF NOT EXISTS subscription_renewals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id UUID NOT NULL REFERENCES user_subscriptions(id) ON DELETE CASCADE,
    renewed_at TIMESTAMPTZ DEFAULT NOW(),
    next_billing_date TIMESTAMPTZ,
    amount DECIMAL(10, 2) NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('success', 'failed', 'pending')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_user_id ON user_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_subscriptions_is_active ON user_subscriptions(is_active);
CREATE INDEX IF NOT EXISTS idx_token_transactions_user_id ON token_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_token_transactions_created_at ON token_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscription_renewals_subscription_id ON subscription_renewals(subscription_id);

-- Triggers for updated_at
CREATE TRIGGER update_user_token_balances_updated_at
    BEFORE UPDATE ON user_token_balances
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_user_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Row Level Security (RLS)
ALTER TABLE user_token_balances ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE token_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_renewals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_token_balances
CREATE POLICY "Users can view their own token balance"
    ON user_token_balances FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can update their own token balance"
    ON user_token_balances FOR UPDATE
    USING (user_id = auth.uid());

CREATE POLICY "System can insert token balance"
    ON user_token_balances FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- RLS Policies for user_subscriptions
CREATE POLICY "Users can view their own subscriptions"
    ON user_subscriptions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own subscriptions"
    ON user_subscriptions FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update their own subscriptions"
    ON user_subscriptions FOR UPDATE
    USING (user_id = auth.uid());

-- RLS Policies for token_transactions
CREATE POLICY "Users can view their own transactions"
    ON token_transactions FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own transactions"
    ON token_transactions FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- RLS Policies for subscription_renewals
CREATE POLICY "Users can view their subscription renewals"
    ON subscription_renewals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM user_subscriptions
            WHERE user_subscriptions.id = subscription_id
            AND user_subscriptions.user_id = auth.uid()
        )
    );

-- Function to initialize token balance for new user
CREATE OR REPLACE FUNCTION initialize_user_tokens()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert token balance (ignore if already exists)
    INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
    VALUES (NEW.id, 10, 1)
    ON CONFLICT (user_id) DO NOTHING;

    -- Insert free subscription (ignore if already exists)
    -- Note: The UNIQUE constraint is on (user_id, is_active) but only when is_active = true
    -- So we check if subscription already exists before inserting
    IF NOT EXISTS (
        SELECT 1 FROM user_subscriptions
        WHERE user_id = NEW.id AND is_active = true
    ) THEN
        INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
        VALUES (NEW.id, 'free', true, NOW());
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail user creation
        RAISE WARNING 'Failed to initialize tokens for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to initialize tokens for new users
CREATE TRIGGER on_user_created_initialize_tokens
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_tokens();

-- Function to consume bidding token
CREATE OR REPLACE FUNCTION consume_bidding_token(p_user_id UUID, p_reference_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_balance INT;
BEGIN
    -- Get current balance
    SELECT bidding_tokens INTO v_current_balance
    FROM user_token_balances
    WHERE user_id = p_user_id;

    -- Check if user has enough tokens
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

-- Function to consume listing token
CREATE OR REPLACE FUNCTION consume_listing_token(p_user_id UUID, p_reference_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_current_balance INT;
BEGIN
    -- Get current balance
    SELECT listing_tokens INTO v_current_balance
    FROM user_token_balances
    WHERE user_id = p_user_id;

    -- Check if user has enough tokens
    IF v_current_balance < 1 THEN
        RETURN FALSE;
    END IF;

    -- Deduct token
    UPDATE user_token_balances
    SET listing_tokens = listing_tokens - 1,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    -- Log transaction
    INSERT INTO token_transactions (user_id, token_type, amount, transaction_type, reference_id)
    VALUES (p_user_id, 'listing', -1, 'consumed', p_reference_id);

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add tokens (for purchases)
CREATE OR REPLACE FUNCTION add_tokens(
    p_user_id UUID,
    p_token_type TEXT,
    p_amount INT,
    p_price DECIMAL,
    p_transaction_type TEXT
)
RETURNS BOOLEAN AS $$
BEGIN
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
    ELSE
        RETURN FALSE;
    END IF;

    -- Log transaction
    INSERT INTO token_transactions (user_id, token_type, amount, price, transaction_type)
    VALUES (p_user_id, p_token_type, p_amount, p_price, p_transaction_type);

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to renew subscription tokens monthly
CREATE OR REPLACE FUNCTION renew_subscription_tokens()
RETURNS void AS $$
DECLARE
    v_subscription RECORD;
    v_bidding_tokens INT;
    v_listing_tokens INT;
BEGIN
    -- Loop through active subscriptions that need renewal
    FOR v_subscription IN
        SELECT * FROM user_subscriptions
        WHERE is_active = true
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
        END
        WHERE id = v_subscription.id;
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
