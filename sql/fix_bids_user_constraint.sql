-- ============================================================================
-- FIX BIDS USER CONSTRAINT
-- This ensures user exists before placing bids
-- ============================================================================

-- OPTION 1: Verify user exists in database (RECOMMENDED)
-- Run this to check if your user ID exists
SELECT id, email, raw_user_meta_data->>'username' as username
FROM auth.users
WHERE id = auth.uid();

-- If the above returns nothing, it means you're not logged in or user doesn't exist
-- Make sure you're authenticated in Supabase when testing

-- ============================================================================
-- OPTION 2: Create a view to check user status (DIAGNOSTIC)
-- ============================================================================

CREATE OR REPLACE VIEW user_bid_eligibility AS
SELECT
  u.id as user_id,
  u.email,
  up.username,
  up.full_name,
  CASE
    WHEN u.id IS NULL THEN 'User does not exist'
    WHEN up.username IS NULL THEN 'Profile incomplete'
    ELSE 'Eligible to bid'
  END as status
FROM auth.users u
LEFT JOIN users up ON up.id = u.id;

-- Check your eligibility
-- SELECT * FROM user_bid_eligibility WHERE user_id = auth.uid();

-- ============================================================================
-- OPTION 3: Ensure users table sync (RUN THIS IF NEEDED)
-- This function ensures every auth.users entry has a corresponding users entry
-- ============================================================================

CREATE OR REPLACE FUNCTION sync_auth_user_to_users()
RETURNS TRIGGER AS $$
BEGIN
  -- Insert into users table if not exists
  INSERT INTO users (id, email, username, full_name, avatar_url, created_at)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email),
    NEW.raw_user_meta_data->>'avatar_url',
    NOW()
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to auto-sync on user creation
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_auth_user_to_users();

-- ============================================================================
-- OPTION 4: Manually sync existing users (RUN ONCE)
-- This will sync all existing auth.users to users table
-- ============================================================================

INSERT INTO users (id, email, username, full_name, avatar_url, created_at)
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'username', split_part(au.email, '@', 1)),
  COALESCE(au.raw_user_meta_data->>'full_name', au.email),
  au.raw_user_meta_data->>'avatar_url',
  au.created_at
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM users u WHERE u.id = au.id
)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- 1. Check if your user exists in both tables
SELECT
  'auth.users' as table_name,
  COUNT(*) as user_count
FROM auth.users
WHERE id = auth.uid()
UNION ALL
SELECT
  'users' as table_name,
  COUNT(*) as user_count
FROM users
WHERE id = auth.uid();

-- 2. Check for orphaned auth users (users in auth.users but not in users table)
SELECT
  au.id,
  au.email,
  'MISSING FROM users TABLE' as issue
FROM auth.users au
LEFT JOIN users u ON u.id = au.id
WHERE u.id IS NULL;

-- ============================================================================
-- INSTRUCTIONS
-- ============================================================================

/*
If you're getting the foreign key constraint error, follow these steps:

1. First, check if you're logged in:
   SELECT auth.uid();

   If this returns NULL, you're not authenticated. Make sure to:
   - Use Supabase client authentication in your app
   - Or run SQL queries while logged in to Supabase Dashboard

2. Check if your user exists in users table:
   SELECT * FROM users WHERE id = auth.uid();

   If this returns nothing, run OPTION 4 above to sync users

3. After syncing, verify:
   SELECT
     (SELECT COUNT(*) FROM auth.users) as auth_users,
     (SELECT COUNT(*) FROM users) as users_count;

   Both should be equal or users_count should be >= auth_users

4. Try placing a bid again

ALTERNATIVE APPROACH (NOT RECOMMENDED):
If you absolutely must bypass the constraint for testing:
- This breaks referential integrity
- Bids won't have valid user references
- Not suitable for production

Only use this if you're doing isolated testing:

ALTER TABLE bids DROP CONSTRAINT IF EXISTS bids_bidder_id_fkey;

To restore the constraint later:
ALTER TABLE bids
  ADD CONSTRAINT bids_bidder_id_fkey
  FOREIGN KEY (bidder_id)
  REFERENCES users(id)
  ON DELETE CASCADE;
*/
