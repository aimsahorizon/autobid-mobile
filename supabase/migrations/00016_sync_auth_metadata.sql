-- ============================================================================
-- AutoBid Mobile - Migration 00015: Sync Auth Metadata Trigger
-- Auto-sync public.users changes to auth.users.raw_user_meta_data
-- ============================================================================

-- ============================================================================
-- SECTION 1: Create Trigger Function
-- ============================================================================

-- Function to sync user metadata from public.users to auth.users
CREATE OR REPLACE FUNCTION sync_user_metadata_to_auth()
RETURNS TRIGGER AS $$
BEGIN
  -- Update auth.users.raw_user_meta_data with latest info from public.users
  -- This keeps auth metadata in sync with the source of truth (public.users)
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
    'display_name', NEW.display_name,
    'full_name', NEW.full_name,
    'username', NEW.username,
    'phone_number', NEW.phone_number,
    'profile_image_url', NEW.profile_image_url
  )
  WHERE id = NEW.id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SECTION 2: Create Trigger on public.users
-- ============================================================================

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS trigger_sync_user_metadata ON users;

-- Create trigger that fires after INSERT or UPDATE on public.users
CREATE TRIGGER trigger_sync_user_metadata
  AFTER INSERT OR UPDATE OF display_name, full_name, username, phone_number, profile_image_url
  ON users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_metadata_to_auth();

-- ============================================================================
-- SECTION 3: Backfill Existing Users (One-time)
-- ============================================================================

-- Sync existing users' metadata to auth.users
DO $$
DECLARE
  user_record RECORD;
BEGIN
  FOR user_record IN
    SELECT id, display_name, full_name, username, phone_number, profile_image_url
    FROM users
    WHERE display_name IS NOT NULL OR full_name IS NOT NULL
  LOOP
    UPDATE auth.users
    SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb) || jsonb_build_object(
      'display_name', user_record.display_name,
      'full_name', user_record.full_name,
      'username', user_record.username,
      'phone_number', user_record.phone_number,
      'profile_image_url', user_record.profile_image_url
    )
    WHERE id = user_record.id;
  END LOOP;

  RAISE NOTICE 'Backfilled metadata for existing users';
END $$;

-- ============================================================================
-- SECTION 4: Verification Query
-- ============================================================================

-- Uncomment to verify sync is working:
-- SELECT
--   u.id,
--   u.display_name as public_display_name,
--   u.full_name as public_full_name,
--   au.raw_user_meta_data->>'display_name' as auth_display_name,
--   au.raw_user_meta_data->>'full_name' as auth_full_name
-- FROM users u
-- JOIN auth.users au ON u.id = au.id
-- LIMIT 5;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
