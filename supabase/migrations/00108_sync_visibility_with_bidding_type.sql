-- ============================================================================
-- AutoBid Mobile - Migration 00108: Sync visibility with bidding_type
-- 
-- The submit_listing_from_draft RPC sets bidding_type but not visibility.
-- This migration:
-- 1. Fixes existing rows where bidding_type='private' but visibility='public'
-- 2. Updates the RPC to also set visibility when inserting auctions
-- 3. Adds a trigger to keep visibility in sync with bidding_type on updates
-- ============================================================================

-- 1. Fix existing rows
UPDATE auctions
SET visibility = bidding_type::auction_visibility
WHERE bidding_type = 'private'
  AND visibility = 'public';

-- 2. Create trigger to keep visibility in sync with bidding_type
CREATE OR REPLACE FUNCTION sync_visibility_with_bidding_type()
RETURNS TRIGGER AS $$
BEGIN
  -- When bidding_type changes, sync visibility
  IF NEW.bidding_type IS DISTINCT FROM OLD.bidding_type THEN
    NEW.visibility := NEW.bidding_type::auction_visibility;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_visibility ON auctions;
CREATE TRIGGER trg_sync_visibility
  BEFORE UPDATE ON auctions
  FOR EACH ROW
  EXECUTE FUNCTION sync_visibility_with_bidding_type();

-- 3. Also sync on INSERT via trigger
CREATE OR REPLACE FUNCTION sync_visibility_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- If visibility not explicitly set (defaults to 'public'), use bidding_type
  IF NEW.visibility = 'public' AND NEW.bidding_type = 'private' THEN
    NEW.visibility := 'private';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_visibility_insert ON auctions;
CREATE TRIGGER trg_sync_visibility_insert
  BEFORE INSERT ON auctions
  FOR EACH ROW
  EXECUTE FUNCTION sync_visibility_on_insert();
