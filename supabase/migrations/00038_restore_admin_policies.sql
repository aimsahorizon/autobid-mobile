-- ============================================================================
-- AutoBid Mobile - Migration 00038: Restore Admin RLS Policies (fixed)
-- ============================================================================
-- This script is idempotent: it drops each named policy if it exists, then
-- creates the policy with the intended logic.
-- ============================================================================

-- 1. Auctions Table - Allow admins to view all auctions
DROP POLICY IF EXISTS "Admins can view all auctions" ON public.auctions;

CREATE POLICY "Admins can view all auctions"
  ON public.auctions
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  );

-- 2. Auction Vehicles Table - Allow admins to view all vehicle details
DROP POLICY IF EXISTS "Admins can view all auction vehicles" ON public.auction_vehicles;

CREATE POLICY "Admins can view all auction vehicles"
  ON public.auction_vehicles
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  );

-- 3. Auction Photos Table - Allow admins to view all auction photos
DROP POLICY IF EXISTS "Admins can view all auction photos" ON public.auction_photos;

CREATE POLICY "Admins can view all auction photos"
  ON public.auction_photos
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  );

-- 4. Admin UPDATE policy - Allow admins to update auction status
DROP POLICY IF EXISTS "Admins can update auction status" ON public.auctions;

CREATE POLICY "Admins can update auction status"
  ON public.auctions
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  );

-- 5. Admin UPDATE policy for auction vehicles
DROP POLICY IF EXISTS "Admins can update auction vehicles" ON public.auction_vehicles;

CREATE POLICY "Admins can update auction vehicles"
  ON public.auction_vehicles
  FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  );

-- 6. Admins can view all users
DROP POLICY IF EXISTS "Admins can view all user details" ON public.users;

CREATE POLICY "Admins can view all user details"
  ON public.users
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.admin_users
      WHERE admin_users.user_id = auth.uid()
        AND admin_users.is_active = TRUE
    )
  );

-- ============================================================================
-- Validation hints:
--  - Verify policies exist: SELECT * FROM pg_policies WHERE tablename IN ('auctions','auction_vehicles','auction_photos','users');
--  - Test with an admin JWT and a non-admin JWT to confirm behavior.
-- ============================================================================