-- ============================================================================
-- AUCTION DEPOSITS SCHEMA
-- Manages auction participation deposits and refunds
-- ============================================================================

-- Deposit transactions table
CREATE TABLE IF NOT EXISTS auction_deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Deposit details
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'refunded', 'forfeited')),

    -- Payment information
    payment_intent_id TEXT, -- Stripe payment intent ID
    payment_method TEXT DEFAULT 'stripe',

    -- Timestamps
    paid_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ,
    forfeited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Unique constraint: one deposit per user per auction
    UNIQUE(auction_id, user_id)
);

-- Add deposit_amount to auctions table if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'auctions' AND column_name = 'deposit_amount'
    ) THEN
        ALTER TABLE auctions ADD COLUMN deposit_amount DECIMAL(12, 2) DEFAULT 50000 CHECK (deposit_amount >= 0);
    END IF;
END $$;

-- Add requires_deposit to auctions table if not exists
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'auctions' AND column_name = 'requires_deposit'
    ) THEN
        ALTER TABLE auctions ADD COLUMN requires_deposit BOOLEAN DEFAULT true;
    END IF;
END $$;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_auction_deposits_user ON auction_deposits(user_id);
CREATE INDEX IF NOT EXISTS idx_auction_deposits_auction ON auction_deposits(auction_id);
CREATE INDEX IF NOT EXISTS idx_auction_deposits_status ON auction_deposits(status);

-- RLS Policies
ALTER TABLE auction_deposits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own deposits"
    ON auction_deposits FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own deposits"
    ON auction_deposits FOR INSERT
    WITH CHECK (user_id = auth.uid());

CREATE POLICY "System can update deposits"
    ON auction_deposits FOR UPDATE
    USING (user_id = auth.uid());

-- Function to check if user has deposited for an auction
CREATE OR REPLACE FUNCTION has_user_deposited(p_auction_id UUID, p_user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    v_deposit_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM auction_deposits
        WHERE auction_id = p_auction_id
        AND user_id = p_user_id
        AND status = 'paid'
    ) INTO v_deposit_exists;

    RETURN v_deposit_exists;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create deposit record
CREATE OR REPLACE FUNCTION create_deposit(
    p_auction_id UUID,
    p_user_id UUID,
    p_amount DECIMAL,
    p_payment_intent_id TEXT
)
RETURNS UUID AS $$
DECLARE
    v_deposit_id UUID;
BEGIN
    -- Insert or update deposit record
    INSERT INTO auction_deposits (auction_id, user_id, amount, status, payment_intent_id, paid_at)
    VALUES (p_auction_id, p_user_id, p_amount, 'paid', p_payment_intent_id, NOW())
    ON CONFLICT (auction_id, user_id)
    DO UPDATE SET
        amount = EXCLUDED.amount,
        status = 'paid',
        payment_intent_id = EXCLUDED.payment_intent_id,
        paid_at = NOW(),
        updated_at = NOW()
    RETURNING id INTO v_deposit_id;

    RETURN v_deposit_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to refund deposit (when user doesn't win)
CREATE OR REPLACE FUNCTION refund_deposit(
    p_auction_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE auction_deposits
    SET status = 'refunded',
        refunded_at = NOW(),
        updated_at = NOW()
    WHERE auction_id = p_auction_id
    AND user_id = p_user_id
    AND status = 'paid';

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to forfeit deposit (when user wins but doesn't complete)
CREATE OR REPLACE FUNCTION forfeit_deposit(
    p_auction_id UUID,
    p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
    UPDATE auction_deposits
    SET status = 'forfeited',
        forfeited_at = NOW(),
        updated_at = NOW()
    WHERE auction_id = p_auction_id
    AND user_id = p_user_id
    AND status = 'paid';

    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to auto-update updated_at
CREATE TRIGGER update_auction_deposits_updated_at
    BEFORE UPDATE ON auction_deposits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Function to get user's deposit for an auction
CREATE OR REPLACE FUNCTION get_user_deposit(p_auction_id UUID, p_user_id UUID)
RETURNS TABLE (
    id UUID,
    amount DECIMAL,
    status TEXT,
    paid_at TIMESTAMPTZ,
    refunded_at TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ad.id,
        ad.amount,
        ad.status,
        ad.paid_at,
        ad.refunded_at
    FROM auction_deposits ad
    WHERE ad.auction_id = p_auction_id
    AND ad.user_id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
