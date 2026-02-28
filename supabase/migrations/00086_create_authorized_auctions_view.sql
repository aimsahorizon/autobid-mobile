-- ============================================================================
-- AutoBid Mobile - Migration 00086: Create Authorized Auctions View
-- ============================================================================
-- Creates a view that filters auctions based on visibility rules.
-- This serves as a convenient interface for the application to query 
-- "all auctions I am allowed to see".
-- ============================================================================

DROP VIEW IF EXISTS public.authorized_auctions CASCADE;

CREATE OR REPLACE VIEW public.authorized_auctions AS
SELECT a.*
FROM public.auctions a
WHERE 
  -- 1. Public auctions
  a.visibility = 'public'
  
  OR 
  
  -- 2. Auctions owned by current user
  a.seller_id = auth.uid()
  
  OR 
  
  -- 3. Private auctions with accepted invite
  EXISTS (
    SELECT 1 
    FROM public.auction_invites ai
    WHERE ai.auction_id = a.id
      AND ai.invitee_user_id = auth.uid()
      AND ai.status = 'accepted'
  );

-- Grant access to authenticated users
GRANT SELECT ON public.authorized_auctions TO authenticated;
