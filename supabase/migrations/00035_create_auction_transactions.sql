-- ============================================================================
-- AutoBid Mobile - Migration 00035: Create Auction Transactions Table
-- ============================================================================
-- Creates a dedicated table to track seller-buyer transactions for auctions
-- Links to auction and buyer, tracks transaction lifecycle and timestamps
-- ============================================================================

-- ============================================================================
-- 1. Create Auction Transactions Table
-- ============================================================================

CREATE TABLE auction_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL UNIQUE REFERENCES auctions(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  agreed_price NUMERIC(12, 2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'in_transaction' CHECK (status IN ('in_transaction', 'sold', 'deal_failed')),
  
  -- Communication & Forms
  seller_form_submitted BOOLEAN DEFAULT FALSE,
  buyer_form_submitted BOOLEAN DEFAULT FALSE,
  seller_confirmed BOOLEAN DEFAULT FALSE,
  buyer_confirmed BOOLEAN DEFAULT FALSE,
  admin_approved BOOLEAN DEFAULT FALSE,
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ,
  admin_approved_at TIMESTAMPTZ
);

-- ============================================================================
-- 2. Create Indexes
-- ============================================================================

-- Index for querying transactions by seller
CREATE INDEX idx_auction_transactions_seller_id 
  ON auction_transactions(seller_id);

-- Index for querying transactions by buyer
CREATE INDEX idx_auction_transactions_buyer_id 
  ON auction_transactions(buyer_id);

-- Index for querying by status
CREATE INDEX idx_auction_transactions_status 
  ON auction_transactions(status);

-- Index for recent transactions
CREATE INDEX idx_auction_transactions_created_at 
  ON auction_transactions(created_at DESC);

-- ============================================================================
-- 3. Create RLS Policies
-- ============================================================================

ALTER TABLE auction_transactions ENABLE ROW LEVEL SECURITY;

-- Sellers can view their own transactions
CREATE POLICY "Sellers view own transactions"
  ON auction_transactions
  FOR SELECT
  USING (seller_id = auth.uid());

-- Buyers can view their own transactions
CREATE POLICY "Buyers view own transactions"
  ON auction_transactions
  FOR SELECT
  USING (buyer_id = auth.uid());

-- Sellers can update their own transaction forms
CREATE POLICY "Sellers update own transactions"
  ON auction_transactions
  FOR UPDATE
  USING (seller_id = auth.uid())
  WITH CHECK (seller_id = auth.uid());

-- Buyers can update their own transaction forms
CREATE POLICY "Buyers update own transactions"
  ON auction_transactions
  FOR UPDATE
  USING (buyer_id = auth.uid())
  WITH CHECK (buyer_id = auth.uid());

-- ============================================================================
-- 4. Create Trigger to Auto-Create Transaction Record
-- ============================================================================

-- Function to create transaction when auction moves to in_transaction
CREATE OR REPLACE FUNCTION create_auction_transaction()
RETURNS TRIGGER AS $$
DECLARE
  highest_bidder_id UUID;
BEGIN
  -- Only create transaction when status changes to 'in_transaction'
  IF NEW.status_id = (SELECT id FROM auction_statuses WHERE status_name = 'in_transaction')
    AND OLD.status_id != NEW.status_id THEN
    
    -- Get the highest bidder (buyer)
    SELECT user_id INTO highest_bidder_id
    FROM bids
    WHERE auction_id = NEW.id
    ORDER BY bid_amount DESC
    LIMIT 1;
    
    -- Only create transaction if there's a buyer
    IF highest_bidder_id IS NOT NULL THEN
      INSERT INTO auction_transactions (
        auction_id,
        seller_id,
        buyer_id,
        agreed_price,
        status,
        created_at
      ) VALUES (
        NEW.id,
        NEW.seller_id,
        highest_bidder_id,
        (SELECT bid_amount FROM bids WHERE auction_id = NEW.id ORDER BY bid_amount DESC LIMIT 1),
        'in_transaction',
        NOW()
      )
      ON CONFLICT (auction_id) DO UPDATE SET
        status = 'in_transaction',
        updated_at = NOW();
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger on auctions table
CREATE TRIGGER auction_status_to_transaction_trigger
  AFTER UPDATE ON auctions
  FOR EACH ROW
  EXECUTE FUNCTION create_auction_transaction();

-- ============================================================================
-- 5. Create Trigger for Updated_At Timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_auction_transactions_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER auction_transactions_timestamp_trigger
  BEFORE UPDATE ON auction_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_auction_transactions_timestamp();

-- ============================================================================
-- MIGRATION COMPLETE
-- ============================================================================
