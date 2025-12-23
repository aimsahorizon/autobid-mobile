-- ============================================================================
-- AutoBid Mobile - Migration 00040: Browse Module Diagnostics & RLS Fix
-- Ensures browse auctions are accessible to all users with proper RLS
-- ============================================================================

-- ============================================================================
-- 1. Verify auction_browse_listings view exists and has proper RLS
-- ============================================================================
-- If view doesn't exist, create it
CREATE OR REPLACE VIEW auction_browse_listings AS
SELECT
  a.id,
  a.title,
  a.description,
  a.starting_price,
  a.current_price,
  a.reserve_price,
  a.bid_increment,
  a.deposit_amount,
  a.start_time,
  a.end_time,
  a.total_bids,
  a.view_count,
  a.is_featured,
  a.seller_id,
  a.category_id,
  a.status_id,
  a.created_at,
  a.updated_at,
  -- Primary photo (first image marked as primary or first image)
  COALESCE(
    (SELECT image_url FROM auction_images 
     WHERE auction_id = a.id 
     ORDER BY is_primary DESC, display_order ASC, created_at ASC
     LIMIT 1),
    ''
  ) as primary_image_url,
  -- Count of watchers (from auction_watchers)
  COALESCE((SELECT COUNT(*) FROM auction_watchers WHERE auction_id = a.id), 0) as watchers_count,
  -- Vehicle placeholder fields (auctions table stores vehicle data differently or not at all)
  0 as vehicle_year,
  '' as vehicle_make,
  '' as vehicle_model,
  '' as vehicle_variant
FROM
  auctions a
WHERE
  -- Only show live auctions that haven't ended yet
  a.status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW();

-- ============================================================================
-- 2. Grant proper permissions on the view to all users
-- ============================================================================
GRANT SELECT ON auction_browse_listings TO anon, authenticated, service_role;

-- ============================================================================
-- 3. Enable RLS on auctions table if not already enabled
-- ============================================================================
ALTER TABLE auctions ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 4. Create a simple public SELECT policy for live auctions
-- This ensures anyone can see live auctions regardless of their role
-- ============================================================================
DROP POLICY IF EXISTS "Public can view live auctions" ON auctions;

CREATE POLICY "Public can view live auctions"
  ON auctions FOR SELECT
  TO anon, authenticated
  USING (
    status_id IN (
      SELECT id FROM auction_statuses 
      WHERE status_name IN ('live', 'scheduled', 'ended', 'sold')
    )
  );

-- ============================================================================
-- 5. Ensure indexes exist for performance
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_end_time 
ON auctions(end_time DESC);

CREATE INDEX IF NOT EXISTS idx_auctions_status_id 
ON auctions(status_id);

CREATE INDEX IF NOT EXISTS idx_auctions_status_end_time 
ON auctions(status_id, end_time DESC);

CREATE INDEX IF NOT EXISTS idx_auctions_title_tsvector 
ON auctions USING GIN(to_tsvector('english', title));

CREATE INDEX IF NOT EXISTS idx_auction_images_auction_id 
ON auction_images(auction_id, is_primary DESC, display_order ASC);

CREATE INDEX IF NOT EXISTS idx_auction_watchers_auction_id 
ON auction_watchers(auction_id);

-- ============================================================================
-- 6. Create helper function to debug auction browsing
-- ============================================================================
CREATE OR REPLACE FUNCTION debug_browse_auctions()
RETURNS TABLE (
  total_auctions BIGINT,
  live_auctions BIGINT,
  live_and_not_ended BIGINT,
  view_exists BOOLEAN,
  sample_auction_json JSONB
) AS $$
DECLARE
  v_view_exists BOOLEAN;
  v_sample_auction JSONB;
BEGIN
  -- Check if view exists
  SELECT EXISTS(
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' 
    AND table_name = 'auction_browse_listings'
  ) INTO v_view_exists;

  -- Get sample auction from browse listings if view exists
  IF v_view_exists THEN
    SELECT to_jsonb(row) INTO v_sample_auction
    FROM auction_browse_listings
    LIMIT 1;
  END IF;

  RETURN QUERY
  SELECT 
    (SELECT COUNT(*) FROM auctions),
    (SELECT COUNT(*) FROM auctions WHERE status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')),
    (SELECT COUNT(*) FROM auctions WHERE status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live') AND end_time > NOW()),
    v_view_exists,
    v_sample_auction;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Create a simpler fallback view for basic browse functionality
-- Uses only auctions table without vehicle/image joins (faster)
-- ============================================================================
DROP VIEW IF EXISTS auction_browse_simple CASCADE;

CREATE VIEW auction_browse_simple AS
SELECT
  a.id,
  a.title,
  a.description,
  a.starting_price,
  a.current_price,
  a.reserve_price,
  a.end_time,
  a.total_bids,
  a.view_count,
  a.is_featured,
  a.seller_id,
  a.created_at,
  0 as vehicle_year,
  '' as vehicle_make,
  '' as vehicle_model,
  '' as vehicle_variant,
  '' as primary_image_url,
  0 as watchers_count
FROM auctions a
WHERE
  a.status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW();

GRANT SELECT ON auction_browse_simple TO anon, authenticated, service_role;

-- ============================================================================
-- 8. Test query to verify browse data is accessible
-- ============================================================================
-- You can run this query in SQL editor to verify data is accessible:
-- SELECT COUNT(*) as total_live_auctions FROM auction_browse_listings;
-- SELECT * FROM debug_browse_auctions();
