-- Fix authorized_auctions view to only show live auctions
-- The view was showing all auctions regardless of status, causing browse screen to not show live auctions

DROP VIEW IF EXISTS public.authorized_auctions CASCADE;

CREATE OR REPLACE VIEW public.authorized_auctions AS
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
FROM public.auctions a
WHERE
  -- Only show live auctions that haven't ended
  a.status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW()
  -- Filter by visibility: public OR user has accepted invite
  AND (
    a.visibility = 'public'
    OR EXISTS (
      SELECT 1 FROM public.auction_invites ai
      WHERE ai.auction_id = a.id
        AND ai.status = 'accepted'
        AND ai.invitee_user_id = auth.uid()
    )
  );

GRANT SELECT ON public.authorized_auctions TO anon, authenticated, service_role;

COMMENT ON VIEW public.authorized_auctions IS 
'Shows live auctions filtered by visibility (public or user has accepted invite). 
Includes same fields as auction_browse_listings for compatibility.';
