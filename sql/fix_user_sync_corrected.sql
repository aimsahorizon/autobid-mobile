-- ============================================================================
-- FIX USER SYNC - CORRECTED VERSION
-- Syncs auth.users to users table with proper column names
-- ============================================================================

-- First, check what columns exist in your users table
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- ============================================================================
-- OPTION 1: Simple Sync (RECOMMENDED FOR TESTING)
-- This creates minimal user records to unblock bidding
-- ============================================================================

INSERT INTO users (
  id,
  username,
  email,
  phone_number,
  first_name,
  last_name,
  date_of_birth,
  sex,
  region,
  province,
  city,
  barangay
)
SELECT
  au.id,
  COALESCE(au.raw_user_meta_data->>'username', split_part(au.email, '@', 1)),
  au.email,
  COALESCE(au.phone, '09000000000'), -- Default phone if not set
  COALESCE(au.raw_user_meta_data->>'first_name', 'Test'),
  COALESCE(au.raw_user_meta_data->>'last_name', 'User'),
  COALESCE((au.raw_user_meta_data->>'date_of_birth')::DATE, '2000-01-01'::DATE),
  COALESCE(au.raw_user_meta_data->>'sex', 'M'),
  COALESCE(au.raw_user_meta_data->>'region', 'NCR'),
  COALESCE(au.raw_user_meta_data->>'province', 'Metro Manila'),
  COALESCE(au.raw_user_meta_data->>'city', 'Manila'),
  COALESCE(au.raw_user_meta_data->>'barangay', 'Unknown')
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM users u WHERE u.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- OPTION 2: Auto-Sync Trigger (FOR FUTURE USERS)
-- This ensures new auth users are automatically synced
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_auth_user_to_users()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO users (
    id,
    username,
    email,
    phone_number,
    first_name,
    last_name,
    date_of_birth,
    sex,
    region,
    province,
    city,
    barangay
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    NEW.email,
    COALESCE(NEW.phone, '09000000000'),
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Test'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'User'),
    COALESCE((NEW.raw_user_meta_data->>'date_of_birth')::DATE, '2000-01-01'::DATE),
    COALESCE(NEW.raw_user_meta_data->>'sex', 'M'),
    COALESCE(NEW.raw_user_meta_data->>'region', 'NCR'),
    COALESCE(NEW.raw_user_meta_data->>'province', 'Metro Manila'),
    COALESCE(NEW.raw_user_meta_data->>'city', 'Manila'),
    COALESCE(NEW.raw_user_meta_data->>'barangay', 'Unknown')
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_auth_user_to_users();

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- 1. Check if sync worked
SELECT
  'auth.users' as table_name,
  COUNT(*) as user_count
FROM auth.users
UNION ALL
SELECT
  'users' as table_name,
  COUNT(*) as user_count
FROM users;

-- 2. Check your current user
SELECT
  u.id,
  u.username,
  u.email,
  u.first_name,
  u.last_name
FROM users u
WHERE u.id = auth.uid();

-- 3. Find any missing users
SELECT
  au.id,
  au.email,
  'MISSING FROM users TABLE' as status
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
WHERE u.id IS NULL;

-- ============================================================================
-- QUICK FIX: If you just want to test bidding NOW
-- ============================================================================

-- This bypasses the constraint temporarily (NOT for production!)
-- Run this only if you need immediate testing:

-- ALTER TABLE bids DROP CONSTRAINT IF EXISTS bids_bidder_id_fkey;

-- After testing, restore the constraint:
-- ALTER TABLE bids
--   ADD CONSTRAINT bids_bidder_id_fkey
--   FOREIGN KEY (bidder_id)
--   REFERENCES users(id)
--   ON DELETE CASCADE;

-- ============================================================================
-- INSTRUCTIONS
-- ============================================================================

/*
1. Run OPTION 1 first to sync existing users
2. Run OPTION 2 to enable auto-sync for new users
3. Run verification queries to confirm
4. Try bidding again - it should work now

If you're still getting errors, it means the user record needs more fields.
Check what's missing with:

SELECT * FROM users WHERE id = auth.uid();

Then manually update the missing fields or contact support.
*/
