-- ============================================================================
-- AutoBid Mobile - Create Admin Account Script
-- Creates a complete admin account with proper authentication and RLS access
-- ============================================================================

-- Usage: Run this in Supabase SQL Editor to create admin@autobid.dev account
-- This script is idempotent - safe to run multiple times

-- ============================================================================
-- STEP 1: Ensure admin user exists in auth.users
-- ============================================================================
-- NOTE: This cannot be done via SQL - admin must sign up once via app
-- The DevAdminAuth.quickAdminLogin() will create the auth user automatically

-- ============================================================================
-- STEP 2: Create admin_users record for existing auth user
-- ============================================================================

DO $$
DECLARE
  v_admin_auth_id UUID;
  v_admin_user_id UUID;
  v_super_admin_role_id UUID;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Starting Admin Account Setup';
  RAISE NOTICE '========================================';

  -- Get admin user ID from auth.users
  SELECT id INTO v_admin_auth_id
  FROM auth.users
  WHERE email = 'admin@autobid.dev'
  LIMIT 1;

  IF v_admin_auth_id IS NULL THEN
    RAISE NOTICE '❌ Admin user not found in auth.users';
    RAISE NOTICE '➡️  Please login via app first using DevAdminAuth.quickAdminLogin()';
    RAISE NOTICE '➡️  Then run this script again';
    RETURN;
  END IF;

  RAISE NOTICE '✅ Found auth user: %', v_admin_auth_id;

  -- Check if user exists in users table, if not create it
  SELECT id INTO v_admin_user_id
  FROM users
  WHERE id = v_admin_auth_id;

  IF v_admin_user_id IS NULL THEN
    RAISE NOTICE '➡️  Creating users table record...';

    INSERT INTO users (
      id,
      email,
      full_name,
      is_active,
      is_verified
    ) VALUES (
      v_admin_auth_id,
      'admin@autobid.dev',
      'System Administrator',
      TRUE,
      TRUE
    )
    RETURNING id INTO v_admin_user_id;

    RAISE NOTICE '✅ Created users record: %', v_admin_user_id;
  ELSE
    RAISE NOTICE '✅ Users record already exists: %', v_admin_user_id;
  END IF;

  -- Get super_admin role ID
  SELECT id INTO v_super_admin_role_id
  FROM admin_roles
  WHERE role_name = 'super_admin'
  LIMIT 1;

  IF v_super_admin_role_id IS NULL THEN
    RAISE NOTICE '❌ super_admin role not found in admin_roles table';
    RAISE NOTICE '➡️  Please run initial schema migrations first';
    RETURN;
  END IF;

  RAISE NOTICE '✅ Found super_admin role: %', v_super_admin_role_id;

  -- Check if admin_users record exists
  IF EXISTS (SELECT 1 FROM admin_users WHERE user_id = v_admin_user_id) THEN
    RAISE NOTICE '✅ Admin already exists in admin_users table';

    -- Update to ensure is_active = TRUE
    UPDATE admin_users
    SET is_active = TRUE,
        updated_at = NOW()
    WHERE user_id = v_admin_user_id;

    RAISE NOTICE '✅ Updated admin_users record (ensured active)';
  ELSE
    RAISE NOTICE '➡️  Creating admin_users record...';

    INSERT INTO admin_users (user_id, role_id, is_active, created_by)
    VALUES (v_admin_user_id, v_super_admin_role_id, TRUE, v_admin_user_id);

    RAISE NOTICE '✅ Created admin_users record';
  END IF;

  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Admin Account Setup Complete!';
  RAISE NOTICE '========================================';
  RAISE NOTICE 'Admin Details:';
  RAISE NOTICE '  Email: admin@autobid.dev';
  RAISE NOTICE '  User ID: %', v_admin_user_id;
  RAISE NOTICE '  Role: super_admin';
  RAISE NOTICE '  Status: Active';
  RAISE NOTICE '========================================';

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE '❌ Error creating admin: %', SQLERRM;
    RAISE EXCEPTION 'Admin setup failed: %', SQLERRM;
END $$;

-- ============================================================================
-- STEP 3: Verify admin account
-- ============================================================================

DO $$
DECLARE
  v_admin_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_admin_count
  FROM admin_users au
  JOIN users u ON au.user_id = u.id
  JOIN admin_roles ar ON au.role_id = ar.id
  WHERE u.email = 'admin@autobid.dev'
  AND au.is_active = TRUE
  AND ar.role_name = 'super_admin';

  IF v_admin_count > 0 THEN
    RAISE NOTICE '========================================';
    RAISE NOTICE '✅ VERIFICATION PASSED';
    RAISE NOTICE '   Admin account is properly configured';
    RAISE NOTICE '   You can now access the admin panel';
    RAISE NOTICE '========================================';
  ELSE
    RAISE NOTICE '========================================';
    RAISE NOTICE '❌ VERIFICATION FAILED';
    RAISE NOTICE '   Admin account not found or not active';
    RAISE NOTICE '========================================';
  END IF;
END $$;

-- ============================================================================
-- Optional: View admin account details
-- ============================================================================

SELECT
  u.id as user_id,
  u.email,
  u.username,
  u.full_name,
  ar.role_name,
  ar.display_name as role_display_name,
  au.is_active,
  au.created_at as admin_since
FROM admin_users au
JOIN users u ON au.user_id = u.id
JOIN admin_roles ar ON au.role_id = ar.id
WHERE u.email = 'admin@autobid.dev';

-- ============================================================================
-- END OF SCRIPT
-- ============================================================================
