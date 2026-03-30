-- ============================================================================
-- AutoBid Mobile - Migration 00088: Fix Auctions Policy Recursion
-- ============================================================================
-- PROBLEM: 
-- The Auctions RLS policy subqueries auction_invites.
-- The auction_invites RLS policy subqueries auctions.
-- This creates an infinite recursion loop in PostgreSQL.
--
-- SOLUTION:
-- Create a security definer function to check auction ownership.
-- Security definer functions bypass RLS of the tables they query,
-- breaking the recursion loop.
-- ============================================================================

-- 1. Helper function to check if user is the owner of an auction
-- SECURITY DEFINER ensures this function can read 'auctions' table even if RLS is strict.
CREATE OR REPLACE FUNCTION public.is_auction_owner(p_auction_id uuid, p_user_id uuid)
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.auctions
    WHERE id = p_auction_id
      AND seller_id = p_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update auction_invites policies to use the helper function
-- This breaks the link where auction_invites policy would trigger auctions policy
DROP POLICY IF EXISTS "inviter manage invites" ON public.auction_invites;

CREATE POLICY "inviter manage invites"
  ON public.auction_invites
  FOR ALL
  USING (
    public.is_auction_owner(auction_id, auth.uid())
  )
  WITH CHECK (
    public.is_auction_owner(auction_id, auth.uid())
  );

-- 3. Grant permissions
GRANT EXECUTE ON FUNCTION public.is_auction_owner(uuid, uuid) TO authenticated;
