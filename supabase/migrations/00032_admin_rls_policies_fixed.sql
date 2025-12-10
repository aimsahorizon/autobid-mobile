-- ============================================================================
-- AutoBid Mobile - Migration 00032: Admin RLS Policies (FIXED)
-- Grant admin users access to view and manage all listings
-- ============================================================================

-- ============================================================================
-- PROBLEM:
-- ============================================================================
-- Admin panel cannot fetch listings because RLS policies block access to:
-- - auctions table
-- - auction_vehicles table
-- - auction_photos table
--
-- Admins need SELECT access to these tables to review and manage listings.

-- ============================================================================
-- SOLUTION: Grant admins SELECT access to auction-related tables
-- ============================================================================

-- ============================================================================
-- 1. Auctions Table - Allow admins to view all auctions
-- ============================================================================

DROP POLICY IF EXISTS "Admins can view all auctions" ON auctions;

CREATE POLICY "Admins can view all auctions"
  ON auctions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- ============================================================================
-- 2. Auction Vehicles Table - Allow admins to view all vehicle details
-- ============================================================================

CREATE POLICY "Admins can view all auction vehicles"
  ON auction_vehicles FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- ============================================================================
-- 3. Auction Photos Table - Allow admins to view all auction photos
-- ============================================================================

CREATE POLICY "Admins can view all auction photos"
  ON auction_photos FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- ============================================================================
-- 4. Auction Statuses - Allow all authenticated users to view statuses
-- ============================================================================

DROP POLICY IF EXISTS "Authenticated users can view auction statuses" ON auction_statuses;

CREATE POLICY "Authenticated users can view auction statuses"
  ON auction_statuses FOR SELECT
  TO authenticated, anon
  USING (true);

-- ============================================================================
-- 5. Admin UPDATE policies - Allow admins to update auction status
-- ============================================================================

CREATE POLICY "Admins can update auction status"
  ON auctions FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- ============================================================================
-- 6. Grant admins access to view all users
-- ============================================================================

CREATE POLICY "Admins can view all user details"
  ON users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- ============================================================================
-- DEV ADMIN SETUP (For development/testing)
-- ============================================================================
-- Create dev admin user in admin_users table

DO $$
DECLARE
  v_admin_auth_id UUID;
  v_admin_user_id UUID;
  v_super_admin_role_id UUID;
  v_admin_user_record_id UUID;
BEGIN
  -- Get admin user ID from auth.users
  SELECT id INTO v_admin_auth_id
  FROM auth.users
  WHERE email = 'admin@autobid.dev'
  LIMIT 1;

  IF v_admin_auth_id IS NULL THEN
    RAISE NOTICE 'Dev admin not found in auth.users. Please login as admin first.';
    RETURN;
  END IF;

  -- Check if user exists in users table, if not create it
  SELECT id INTO v_admin_user_id
  FROM users
  WHERE id = v_admin_auth_id;

  IF v_admin_user_id IS NULL THEN
    -- Create user record for admin
    INSERT INTO users (
      id,
      email,
      username,
      full_name,
      display_name,
      is_active,
      is_verified,
      kyc_status
    ) VALUES (
      v_admin_auth_id,
      'admin@autobid.dev',
      'admin',
      'System Admin',
      'Admin',
      TRUE,
      TRUE,
      'approved'
    )
    RETURNING id INTO v_admin_user_id;

    RAISE NOTICE 'Created user record for admin with ID: %', v_admin_user_id;
  ELSE
    RAISE NOTICE 'Admin user already exists in users table with ID: %', v_admin_user_id;
  END IF;

  -- Get super_admin role ID from admin_roles
  SELECT id INTO v_super_admin_role_id
  FROM admin_roles
  WHERE role_name = 'super_admin'
  LIMIT 1;

  IF v_super_admin_role_id IS NULL THEN
    RAISE NOTICE 'super_admin role not found in admin_roles table';
    RETURN;
  END IF;

  -- Insert into admin_users if not exists
  SELECT id INTO v_admin_user_record_id
  FROM admin_users
  WHERE user_id = v_admin_user_id;

  IF v_admin_user_record_id IS NULL THEN
    -- Insert new admin_user record
    INSERT INTO admin_users (user_id, role_id, is_active, created_by)
    VALUES (v_admin_user_id, v_super_admin_role_id, TRUE, v_admin_user_id)
    RETURNING id INTO v_admin_user_record_id;

    RAISE NOTICE 'Dev admin_users record created with ID: %', v_admin_user_record_id;
  ELSE
    RAISE NOTICE 'Admin already exists in admin_users with ID: %', v_admin_user_record_id;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Error creating admin: %', SQLERRM;
END $$;

-- ============================================================================
-- VERIFICATION QUERIES (Run these to test):
-- ============================================================================
-- 1. Check if admin user exists:
--    SELECT
--      au.email,
--      adu.is_active,
--      ar.role_name,
--      ar.display_name
--    FROM admin_users adu
--    JOIN auth.users au ON adu.user_id = au.id
--    JOIN admin_roles ar ON adu.role_id = ar.id
--    WHERE au.email = 'admin@autobid.dev';
--
-- 2. Test admin auction access (run as admin user):
--    SELECT COUNT(*) FROM auctions;
--
-- 3. Test admin vehicle access:
--    SELECT COUNT(*) FROM auction_vehicles;
--
-- 4. Test admin photo access:
--    SELECT COUNT(*) FROM auction_photos;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
