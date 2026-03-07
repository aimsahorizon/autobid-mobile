-- ============================================================================
-- AutoBid Mobile - Migration 00120: Harden Browse Visibility + Seller Fields
-- ============================================================================
-- Goals:
-- 1) Ensure browse views never expose private auctions to non-invited users.
-- 2) Keep sellers able to see their own auctions.
-- 3) Expose seller display metadata for browse cards.
-- 4) Expose visibility/bidding_type so client can filter public/private auctions.
-- ============================================================================

DROP VIEW IF EXISTS public.auction_browse_listings CASCADE;
DROP VIEW IF EXISTS public.auction_browse_simple CASCADE;
DROP VIEW IF EXISTS public.authorized_auctions CASCADE;

CREATE OR REPLACE VIEW public.auction_browse_listings AS
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
  a.visibility,
  a.bidding_type,
  a.is_active,
  a.created_at,
  a.updated_at,
  COALESCE(
    (SELECT photo_url FROM public.auction_photos
     WHERE auction_id = a.id AND is_primary = true
     LIMIT 1),
    (SELECT photo_url FROM public.auction_photos
     WHERE auction_id = a.id
     ORDER BY display_order ASC
     LIMIT 1),
    ''
  ) AS primary_image_url,
  COALESCE((SELECT COUNT(*) FROM public.auction_watchers aw WHERE aw.auction_id = a.id), 0) AS watchers_count,
  COALESCE(av.year, 0) AS vehicle_year,
  COALESCE(av.brand, '') AS vehicle_make,
  COALESCE(av.model, '') AS vehicle_model,
  COALESCE(av.variant, '') AS vehicle_variant,
  COALESCE(u.display_name, u.full_name, 'Seller') AS seller_display_name,
  COALESCE(u.profile_image_url, '') AS seller_profile_image_url
FROM public.auctions a
LEFT JOIN public.auction_vehicles av ON a.id = av.auction_id
LEFT JOIN public.users u ON u.id = a.seller_id
WHERE
  a.status_id = (SELECT id FROM public.auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW()
  AND a.is_active = true
  AND (
    a.visibility = 'public'
    OR a.seller_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.auction_invites ai
      WHERE ai.auction_id = a.id
        AND ai.invitee_user_id = auth.uid()
        AND ai.status = 'accepted'
    )
  );

CREATE OR REPLACE VIEW public.auction_browse_simple AS
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
  a.visibility,
  a.bidding_type,
  a.is_active,
  a.created_at,
  0 AS vehicle_year,
  '' AS vehicle_make,
  '' AS vehicle_model,
  '' AS vehicle_variant,
  '' AS primary_image_url,
  0 AS watchers_count,
  COALESCE(u.display_name, u.full_name, 'Seller') AS seller_display_name,
  COALESCE(u.profile_image_url, '') AS seller_profile_image_url
FROM public.auctions a
LEFT JOIN public.users u ON u.id = a.seller_id
WHERE
  a.status_id = (SELECT id FROM public.auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW()
  AND a.is_active = true
  AND (
    a.visibility = 'public'
    OR a.seller_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.auction_invites ai
      WHERE ai.auction_id = a.id
        AND ai.invitee_user_id = auth.uid()
        AND ai.status = 'accepted'
    )
  );

CREATE OR REPLACE VIEW public.authorized_auctions AS
SELECT *
FROM public.auction_browse_listings;

GRANT SELECT ON public.auction_browse_listings TO authenticated, service_role;
GRANT SELECT ON public.auction_browse_simple TO anon, authenticated, service_role;
GRANT SELECT ON public.authorized_auctions TO anon, authenticated, service_role;
