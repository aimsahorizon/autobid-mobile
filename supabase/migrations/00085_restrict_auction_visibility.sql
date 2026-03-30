-- ============================================================================
-- AutoBid Mobile - Migration 00085: Restrict Private Auction Visibility
-- ============================================================================
-- Ensures private auctions are only visible to:
-- 1. The seller (owner)
-- 2. Users with an ACCEPTED invite for that auction
-- Public auctions remain visible to everyone.
-- ============================================================================

-- 1. Drop existing select policy if it exists to avoid conflicts/redundancy
DROP POLICY IF EXISTS "Public auctions are viewable by everyone" ON public.auctions;
DROP POLICY IF EXISTS "Auctions view policy" ON public.auctions;
DROP POLICY IF EXISTS "Auctions visibility policy" ON public.auctions;

-- 2. Create comprehensive visibility policy
CREATE POLICY "Auctions visibility policy"
ON public.auctions
FOR SELECT
USING (
  -- Case 1: Auction is public (visible to everyone)
  visibility = 'public'
  
  OR 
  
  -- Case 2: User is the seller (owner sees everything)
  seller_id = auth.uid()
  
  OR
  
  -- Case 3: User has an ACCEPTED invite for this private auction
  EXISTS (
    SELECT 1 
    FROM public.auction_invites ai
    WHERE ai.auction_id = auctions.id
      AND ai.invitee_user_id = auth.uid()
      AND ai.status = 'accepted'
  )
);

-- Ensure RLS is enabled
ALTER TABLE public.auctions ENABLE ROW LEVEL SECURITY;
