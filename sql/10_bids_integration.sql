-- ============================================================================
-- BIDS INTEGRATION WITH LISTINGS
-- Updates bids table and functions to work with listings table
-- ============================================================================

-- Drop old tables/functions if they exist
DROP TABLE IF EXISTS bids CASCADE;
DROP FUNCTION IF EXISTS get_user_active_bids CASCADE;
DROP FUNCTION IF EXISTS update_auction_after_bid CASCADE;

-- Create bids table that references listings
CREATE TABLE bids (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References listings table instead of auctions
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  bidder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Bid details
  amount DECIMAL(12, 2) NOT NULL CHECK (amount > 0),

  -- Auto-bid configuration (null if manual bid)
  is_auto_bid BOOLEAN NOT NULL DEFAULT FALSE,
  max_auto_bid DECIMAL(12, 2),
  auto_bid_increment DECIMAL(12, 2),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_bids_listing ON bids(listing_id);
CREATE INDEX idx_bids_bidder ON bids(bidder_id);
CREATE INDEX idx_bids_listing_amount ON bids(listing_id, amount DESC);
CREATE INDEX idx_user_active_bids ON bids(bidder_id, listing_id, created_at DESC);

-- ============================================================================
-- FUNCTION: Update listing after bid is placed
-- ============================================================================

CREATE OR REPLACE FUNCTION update_listing_after_bid()
RETURNS TRIGGER AS $$
DECLARE
  unique_bidders INTEGER;
BEGIN
  -- Update current bid to the new bid amount
  UPDATE listings
  SET
    current_bid = NEW.amount,
    updated_at = NOW()
  WHERE id = NEW.listing_id;

  -- Count unique bidders for this listing
  SELECT COUNT(DISTINCT bidder_id) INTO unique_bidders
  FROM bids
  WHERE listing_id = NEW.listing_id;

  -- Update total bids count
  UPDATE listings
  SET total_bids = unique_bidders
  WHERE id = NEW.listing_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update listing when new bid is placed
CREATE TRIGGER after_bid_insert
AFTER INSERT ON bids
FOR EACH ROW
EXECUTE FUNCTION update_listing_after_bid();

-- ============================================================================
-- FUNCTION: Get user's active bids
-- Returns user's bids on active auctions
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_active_bids(user_id UUID)
RETURNS TABLE (
  listing_id UUID,
  bid_id UUID,
  amount NUMERIC,
  is_winning BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ON (b.listing_id)
    b.listing_id,
    b.id as bid_id,
    b.amount,
    (b.amount = l.current_bid) as is_winning,
    b.created_at
  FROM bids b
  JOIN listings l ON b.listing_id = l.id
  WHERE
    b.bidder_id = user_id
    AND l.status = 'active'
    AND l.auction_end_time > NOW()
    AND l.deleted_at IS NULL
  ORDER BY b.listing_id, b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RLS POLICIES FOR BIDS
-- ============================================================================

ALTER TABLE bids ENABLE ROW LEVEL SECURITY;

-- Authenticated users can view all bids
CREATE POLICY "Authenticated users can view bids"
ON bids FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can place bids
CREATE POLICY "Authenticated users can place bids"
ON bids FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = bidder_id);

-- ============================================================================
-- BIDS INTEGRATION COMPLETE
-- Bids now work with listings table
-- ============================================================================
