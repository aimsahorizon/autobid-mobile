-- ============================================================================
-- AUCTIONS AND BIDS SCHEMA
-- Simple schema for auction and bidding functionality
-- Links to existing users table
-- ============================================================================

-- Auctions table stores all car auction listings
CREATE TABLE auctions (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Car details
  car_image_url TEXT NOT NULL,
  year INTEGER NOT NULL CHECK (year >= 1900 AND year <= 2100),
  make TEXT NOT NULL,
  model TEXT NOT NULL,

  -- Bidding information
  starting_bid NUMERIC(12, 2) NOT NULL CHECK (starting_bid > 0),
  current_bid NUMERIC(12, 2) NOT NULL CHECK (current_bid >= starting_bid),
  bid_increment NUMERIC(12, 2) NOT NULL DEFAULT 1000 CHECK (bid_increment > 0),

  -- Auction timing
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_time TIMESTAMPTZ NOT NULL,

  -- Seller information (references users table)
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Counters
  watchers_count INTEGER NOT NULL DEFAULT 0 CHECK (watchers_count >= 0),
  bidders_count INTEGER NOT NULL DEFAULT 0 CHECK (bidders_count >= 0),

  -- Status tracking
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('draft', 'active', 'completed', 'cancelled')),

  -- Winner tracking (set when auction ends)
  winner_id UUID REFERENCES users(id) ON DELETE SET NULL,
  winning_bid NUMERIC(12, 2),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Ensure end_time is after start_time
  CONSTRAINT valid_auction_time CHECK (end_time > start_time)
);

-- Bids table stores all bid history
CREATE TABLE bids (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  bidder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Bid details
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),

  -- Auto-bid configuration (null if manual bid)
  is_auto_bid BOOLEAN NOT NULL DEFAULT FALSE,
  max_auto_bid NUMERIC(12, 2),
  auto_bid_increment NUMERIC(12, 2),

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent negative or zero bids
  CONSTRAINT positive_amount CHECK (amount > 0)
);

-- ============================================================================
-- INDEXES for performance
-- ============================================================================

-- Auctions indexes
CREATE INDEX idx_auctions_status ON auctions(status) WHERE status = 'active';
CREATE INDEX idx_auctions_seller ON auctions(seller_id);
CREATE INDEX idx_auctions_end_time ON auctions(end_time) WHERE status = 'active';
CREATE INDEX idx_auctions_winner ON auctions(winner_id) WHERE winner_id IS NOT NULL;

-- Bids indexes
CREATE INDEX idx_bids_auction ON bids(auction_id);
CREATE INDEX idx_bids_bidder ON bids(bidder_id);
CREATE INDEX idx_bids_auction_amount ON bids(auction_id, amount DESC);
CREATE INDEX idx_bids_created ON bids(created_at DESC);

-- Composite index for user's active bids
CREATE INDEX idx_user_active_bids ON bids(bidder_id, auction_id, created_at DESC);

-- ============================================================================
-- AUTO-UPDATE updated_at timestamp for auctions
-- ============================================================================

CREATE TRIGGER set_auctions_updated_at
BEFORE UPDATE ON auctions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- FUNCTION: Update auction current_bid and bidders_count
-- ============================================================================

CREATE OR REPLACE FUNCTION update_auction_after_bid()
RETURNS TRIGGER AS $$
DECLARE
  unique_bidders INTEGER;
BEGIN
  -- Update current bid to the new bid amount
  UPDATE auctions
  SET
    current_bid = NEW.amount,
    updated_at = NOW()
  WHERE id = NEW.auction_id;

  -- Count unique bidders for this auction
  SELECT COUNT(DISTINCT bidder_id) INTO unique_bidders
  FROM bids
  WHERE auction_id = NEW.auction_id;

  -- Update bidders count
  UPDATE auctions
  SET bidders_count = unique_bidders
  WHERE id = NEW.auction_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update auction when new bid is placed
CREATE TRIGGER after_bid_insert
AFTER INSERT ON bids
FOR EACH ROW
EXECUTE FUNCTION update_auction_after_bid();

-- ============================================================================
-- FUNCTION: Get user's active bids (latest bid per auction)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_user_active_bids(user_id UUID)
RETURNS TABLE (
  auction_id UUID,
  bid_id UUID,
  amount NUMERIC,
  is_winning BOOLEAN,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT ON (b.auction_id)
    b.auction_id,
    b.id as bid_id,
    b.amount,
    (b.amount = a.current_bid) as is_winning,
    b.created_at
  FROM bids b
  JOIN auctions a ON b.auction_id = a.id
  WHERE
    b.bidder_id = user_id
    AND a.status = 'active'
    AND a.end_time > NOW()
  ORDER BY b.auction_id, b.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VIEW: Active auctions with current bid info
-- ============================================================================

CREATE OR REPLACE VIEW active_auctions_view AS
SELECT
  a.id,
  a.car_image_url,
  a.year,
  a.make,
  a.model,
  a.current_bid,
  a.watchers_count,
  a.bidders_count,
  a.end_time,
  a.seller_id,
  a.created_at
FROM auctions a
WHERE
  a.status = 'active'
  AND a.end_time > NOW()
ORDER BY a.end_time ASC;

-- ============================================================================
-- SCHEMA COMPLETE
-- Next: Run 8_auctions_bids_rls.sql for security policies
-- ============================================================================
