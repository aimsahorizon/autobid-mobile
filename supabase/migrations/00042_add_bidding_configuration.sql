-- ============================================================================
-- AutoBid Mobile - Migration 00042: Add Bidding Configuration Fields
-- Adds seller-configurable bidding options: type, increments, and deposit
-- ============================================================================

-- STEP 1: Add new columns to listing_drafts table for Step 8 configuration
ALTER TABLE listing_drafts
ADD COLUMN IF NOT EXISTS bidding_type TEXT DEFAULT 'public' CHECK (bidding_type IN ('public', 'private')),
ADD COLUMN IF NOT EXISTS bid_increment NUMERIC(12, 2) NOT NULL DEFAULT 1000 CHECK (bid_increment > 0),
ADD COLUMN IF NOT EXISTS min_bid_increment NUMERIC(12, 2) NOT NULL DEFAULT 1000 CHECK (min_bid_increment > 0),
ADD COLUMN IF NOT EXISTS deposit_amount NUMERIC(12, 2) NOT NULL DEFAULT 50000 CHECK (deposit_amount > 0),
ADD COLUMN IF NOT EXISTS enable_incremental_bidding BOOLEAN DEFAULT TRUE;

-- STEP 2: Add new columns to auctions table (for live auctions)
-- These are copied from listing_drafts when auction is submitted
ALTER TABLE auctions
ADD COLUMN IF NOT EXISTS bidding_type TEXT DEFAULT 'public' CHECK (bidding_type IN ('public', 'private')),
ADD COLUMN IF NOT EXISTS min_bid_increment NUMERIC(12, 2) CHECK (min_bid_increment > 0),
ADD COLUMN IF NOT EXISTS enable_incremental_bidding BOOLEAN DEFAULT TRUE;

-- STEP 3: Create bidding_rules table for complex bid validation
-- This supports incremental bidding rules based on price ranges
CREATE TABLE IF NOT EXISTS bidding_rules (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  
  -- Price range boundaries
  price_range_min NUMERIC(12, 2) NOT NULL CHECK (price_range_min >= 0),
  price_range_max NUMERIC(12, 2) NOT NULL CHECK (price_range_max > price_range_min),
  
  -- Required increment for this price range
  required_increment NUMERIC(12, 2) NOT NULL CHECK (required_increment > 0),
  
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Ensure rules don't overlap for same auction
  UNIQUE(auction_id, price_range_min)
);

-- Index for efficient bid validation lookups
CREATE INDEX IF NOT EXISTS idx_bidding_rules_auction_price
  ON bidding_rules(auction_id, price_range_min);

-- STEP 4: Add indexes for new columns
CREATE INDEX IF NOT EXISTS idx_listing_drafts_bidding_type
  ON listing_drafts(bidding_type)
  WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_auctions_bidding_type
  ON auctions(bidding_type, status_id);

-- STEP 5: Create comprehensive comment documentation
COMMENT ON COLUMN listing_drafts.bidding_type IS 
  'Bidding visibility: public (all can see), private (invite-only)';

COMMENT ON COLUMN listing_drafts.bid_increment IS 
  'Default increment for standard bidding (will be deprecated, use min_bid_increment)';

COMMENT ON COLUMN listing_drafts.min_bid_increment IS 
  'Minimum bid increment for Step 8 configuration - base increment value';

COMMENT ON COLUMN listing_drafts.deposit_amount IS 
  'Seller-configured deposit required from buyers to bid';

COMMENT ON COLUMN listing_drafts.enable_incremental_bidding IS 
  'Whether to allow incremental bidding with custom rules (true) or use fixed increment (false)';

COMMENT ON COLUMN auctions.bidding_type IS 
  'Bidding visibility: public (all can see), private (invite-only)';

COMMENT ON COLUMN auctions.min_bid_increment IS 
  'Minimum bid increment configured by seller at listing creation';

COMMENT ON COLUMN auctions.enable_incremental_bidding IS 
  'Whether incremental bidding rules are enabled for this auction';

COMMENT ON TABLE bidding_rules IS 
  'Complex bid validation rules supporting incremental bidding by price range
   Example: ₱0-500k: ₱1k increments, ₱500k-1M: ₱5k increments, ₱1M+: ₱10k increments
   Used only when enable_incremental_bidding = true for price-aware bidding';

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
-- 
-- 1. BIDDING TYPE (public/private):
--    - public: Anyone can bid and see bid history
--    - private: Only invited buyers can bid (future feature)
--
-- 2. BID INCREMENT Strategy:
--    - Fixed increment: Use min_bid_increment for all bids
--    - Incremental (dynamic): Use bidding_rules table with price ranges
--    - Example: ₱1k for <₱500k, ₱5k for ₱500k-₱1M, ₱10k for ₱1M+
--
-- 3. DEPOSIT AMOUNT:
--    - Required from buyer before they can place a bid
--    - Seller configurable in Step 8
--    - Typical defaults: ₱50,000 for high-value cars
--
-- 4. ENABLE_INCREMENTAL_BIDDING:
--    - If TRUE: Use bidding_rules table for complex price-based increments
--    - If FALSE: Use min_bid_increment for all bids (simpler, linear)
--
-- 5. DATA MIGRATION:
--    - Existing drafts will use defaults (public, ₱1k increment, ₱50k deposit)
--    - Existing auctions: bid_increment column already has values
--    - New auctions will copy these values from listing_drafts during submission
--
-- ============================================================================
