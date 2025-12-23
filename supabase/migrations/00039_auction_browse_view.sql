-- ============================================================================
-- AutoBid Mobile - Migration 00039: Auction Browse View
-- Provides live auctions with photo details for browse module
-- ============================================================================

-- ============================================================================
-- Create view for browse module with auction details and photos
-- This enables efficient fetching of live auctions with all required display data
-- ============================================================================

DROP VIEW IF EXISTS auction_browse_listings CASCADE;

CREATE VIEW auction_browse_listings AS
SELECT
  a.id,
  a.title,
  a.description,
  a.starting_price,
  a.current_price,
  a.reserve_price,
  a.deposit_amount,
  a.bid_increment,
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
  -- Vehicle data from auctions table (if available)
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
-- Grant SELECT permissions on the view
-- ============================================================================
GRANT SELECT ON auction_browse_listings TO anon, authenticated;

-- ============================================================================
-- Create index on end_time for ordering by time (important for browse UX)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_end_time 
ON auctions(end_time DESC);

-- ============================================================================
-- Create index for faster status filtering
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_status_id 
ON auctions(status_id);

-- ============================================================================
-- Create composite index for live auctions (status + end_time)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_status_end_time 
ON auctions(status_id, end_time DESC);

-- ============================================================================
-- Create index for search by title
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_title_search 
ON auctions USING GIN(to_tsvector('english', title));

-- ============================================================================
-- Create index for search by description
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_description_search 
ON auctions USING GIN(to_tsvector('english', description));

-- ============================================================================
-- Create index on price range queries
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_auctions_current_price 
ON auctions(current_price DESC);
