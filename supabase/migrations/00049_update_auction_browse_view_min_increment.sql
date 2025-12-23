-- Update auction_browse_listings view to expose bidding configuration
-- Includes min_bid_increment and enable_incremental_bidding so clients can enforce seller-configured increments

DROP VIEW IF EXISTS auction_browse_listings CASCADE;

CREATE VIEW auction_browse_listings AS
SELECT
  a.id,
  a.title,
  a.description,
  a.starting_price,
  a.current_price,
  a.reserve_price,
  a.bid_increment,
  a.min_bid_increment,
  a.enable_incremental_bidding,
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
  COALESCE(
    (SELECT image_url FROM auction_images
     WHERE auction_id = a.id
     ORDER BY is_primary DESC, display_order ASC, created_at ASC
     LIMIT 1),
    ''
  ) AS primary_image_url,
  COALESCE((SELECT COUNT(*) FROM auction_watchers WHERE auction_id = a.id), 0) AS watchers_count,
  0 AS vehicle_year,
  '' AS vehicle_make,
  '' AS vehicle_model,
  '' AS vehicle_variant
FROM auctions a
WHERE
  a.status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW();

GRANT SELECT ON auction_browse_listings TO anon, authenticated, service_role;
