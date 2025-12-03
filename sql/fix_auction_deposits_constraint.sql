-- Temporary fix: Drop and recreate auction_deposits table without foreign key constraint on auctions
-- This allows deposits to work even if auction doesn't exist in auctions table yet

-- Drop existing table and recreate without FK constraint
DROP TABLE IF EXISTS auction_deposits CASCADE;

CREATE TABLE auction_deposits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- References (removed FK constraint on auction_id)
    auction_id UUID NOT NULL, -- No FK constraint - allows any UUID
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Deposit details
    amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'refunded', 'forfeited')),

    -- Payment information
    payment_intent_id TEXT,
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

-- Indexes
CREATE INDEX idx_auction_deposits_user ON auction_deposits(user_id);
CREATE INDEX idx_auction_deposits_auction ON auction_deposits(auction_id);
CREATE INDEX idx_auction_deposits_status ON auction_deposits(status);

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

-- Recreate trigger
CREATE TRIGGER update_auction_deposits_updated_at
    BEFORE UPDATE ON auction_deposits
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Recreate all functions (they were dropped with CASCADE)

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
