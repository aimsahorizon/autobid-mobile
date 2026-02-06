-- ============================================================================
-- AutoBid Mobile - Migration 00087: Update Auction Browse Listings View
-- ============================================================================
-- Updates auction_browse_listings to:
-- 1. Join with auction_vehicles to provide real vehicle data (year, make, model)
-- 2. Respect private/public visibility rules
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
  -- Primary Image
  COALESCE(
    (SELECT photo_url FROM auction_photos
     WHERE auction_id = a.id AND is_primary = true
     LIMIT 1),
    (SELECT photo_url FROM auction_photos
     WHERE auction_id = a.id
     ORDER BY display_order ASC
     LIMIT 1),
    ''
  ) AS primary_image_url,
  -- Watchers
  COALESCE((SELECT COUNT(*) FROM auction_watchers WHERE auction_id = a.id), 0) AS watchers_count,
  -- Vehicle Details
  COALESCE(av.year, 0) AS vehicle_year,
  COALESCE(av.brand, '') AS vehicle_make,
  COALESCE(av.model, '') AS vehicle_model,
  COALESCE(av.variant, '') AS vehicle_variant
FROM auctions a
LEFT JOIN auction_vehicles av ON a.id = av.auction_id
WHERE
  -- 1. Must be LIVE and ACTIVE
  a.status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW()
  
  AND (
    -- 2. Visibility Check:
    -- Public auctions are visible to everyone
    a.visibility = 'public'
    
    OR 
    
    -- Users can see their own auctions
    a.seller_id = auth.uid()
    
    OR 
    
    -- Private auctions visible ONLY if invited and accepted
    EXISTS (
      SELECT 1 
      FROM auction_invites ai
      WHERE ai.auction_id = a.id
        AND ai.invitee_user_id = auth.uid()
        AND ai.status = 'accepted'
    )
  );

-- Grant access
GRANT SELECT ON auction_browse_listings TO authenticated, service_role;
