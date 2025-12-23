-- ============================================================================
-- AutoBid Mobile - Migration 00062: Add Anti-Snipe Guard Columns to Auctions
-- ============================================================================
-- 
-- PURPOSE:
-- Implements anti-bidding snipe protection that extends auction end time
-- when bids are placed near the deadline. This prevents last-second sniping.
--
-- BUSINESS LOGIC:
-- - If a bid is placed within X seconds of auction end (threshold)
-- - The auction end_time extends by Y seconds (extend_seconds)
-- - Default: 300 seconds (5 minutes) threshold and extension
-- - Can be configured per auction by seller
--
-- EXAMPLE:
-- Auction ends at 10:00:00 PM
-- Threshold: 300 seconds (5 minutes)
-- Extend: 300 seconds (5 minutes)
-- 
-- If someone bids at 9:58:00 PM (2 minutes before end):
-- - New end time: 10:05:00 PM (extended by 5 minutes)
-- - This gives others fair chance to counter-bid
-- ============================================================================

-- Add snipe guard configuration columns to auctions table
ALTER TABLE auctions
ADD COLUMN IF NOT EXISTS snipe_guard_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS snipe_guard_threshold_seconds INTEGER DEFAULT 300 
  CHECK (snipe_guard_threshold_seconds >= 0 AND snipe_guard_threshold_seconds <= 3600),
ADD COLUMN IF NOT EXISTS snipe_guard_extend_seconds INTEGER DEFAULT 300 
  CHECK (snipe_guard_extend_seconds >= 60 AND snipe_guard_extend_seconds <= 3600),
ADD COLUMN IF NOT EXISTS snipe_guard_last_applied_at TIMESTAMPTZ;

-- Add same columns to listing_drafts for seller configuration in Step 8
ALTER TABLE listing_drafts
ADD COLUMN IF NOT EXISTS snipe_guard_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS snipe_guard_threshold_seconds INTEGER DEFAULT 300 
  CHECK (snipe_guard_threshold_seconds >= 0 AND snipe_guard_threshold_seconds <= 3600),
ADD COLUMN IF NOT EXISTS snipe_guard_extend_seconds INTEGER DEFAULT 300 
  CHECK (snipe_guard_extend_seconds >= 60 AND snipe_guard_extend_seconds <= 3600);

-- Index for efficient snipe guard checks (auctions ending soon)
CREATE INDEX IF NOT EXISTS idx_auctions_snipe_guard_active
  ON auctions(end_time)
  WHERE snipe_guard_enabled = TRUE;

-- Add helpful comments
COMMENT ON COLUMN auctions.snipe_guard_enabled IS 
  'When TRUE, auction end time extends if bid placed within threshold seconds of end';

COMMENT ON COLUMN auctions.snipe_guard_threshold_seconds IS 
  'If bid placed within this many seconds of end_time, auction extends (default 300 = 5 minutes)';

COMMENT ON COLUMN auctions.snipe_guard_extend_seconds IS 
  'How many seconds to extend end_time when snipe guard triggers (default 300 = 5 minutes)';

COMMENT ON COLUMN auctions.snipe_guard_last_applied_at IS 
  'Timestamp of when snipe guard was last triggered for this auction';

COMMENT ON COLUMN listing_drafts.snipe_guard_enabled IS 
  'Seller configures whether to enable anti-snipe protection (recommended: TRUE)';

COMMENT ON COLUMN listing_drafts.snipe_guard_threshold_seconds IS 
  'Seller configures snipe guard trigger window in seconds (recommended: 300 = 5 minutes)';

COMMENT ON COLUMN listing_drafts.snipe_guard_extend_seconds IS 
  'Seller configures how much time to add when triggered (recommended: 300 = 5 minutes)';

-- ============================================================================
-- MIGRATION NOTES
-- ============================================================================
--
-- 1. DEFAULT VALUES (5-minute anti-snipe):
--    - snipe_guard_enabled: TRUE (enabled by default)
--    - snipe_guard_threshold_seconds: 300 (last 5 minutes)
--    - snipe_guard_extend_seconds: 300 (extend by 5 minutes)
--
-- 2. VALIDATION CONSTRAINTS:
--    - threshold_seconds: 0 to 3600 (0 = disabled, max 1 hour)
--    - extend_seconds: 60 to 3600 (min 1 minute, max 1 hour)
--
-- 3. BACKEND INTEGRATION:
--    - Flutter datasource already has _maybeApplySnipeGuard() method
--    - This migration makes that method functional with DB persistence
--    - Frontend defaults updated from 60s to 300s to match
--
-- 4. EXISTING AUCTIONS:
--    - All existing auctions will get default values (enabled, 300s, 300s)
--    - No data migration needed as snipe_guard_last_applied_at can be NULL
--
-- 5. SELLER CONFIGURATION:
--    - Sellers can configure these in Step 8 of listing creation
--    - Values copy from listing_drafts to auctions on submission
--    - Can be updated in submit_listing_from_draft RPC
--
-- ============================================================================
