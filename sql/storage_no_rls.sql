-- ============================================================================
-- STORAGE - NO RLS AT ALL
-- Maximum permissiveness - zero security restrictions
-- FOR DEVELOPMENT/TESTING ONLY
-- ============================================================================

-- ============================================================================
-- STEP 1: Create storage buckets (all public for easy access)
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  (
    'user-avatars',
    'user-avatars',
    true,
    5242880, -- 5MB
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
  ),
  (
    'user-covers',
    'user-covers',
    true,
    10485760, -- 10MB
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp']
  ),
  (
    'kyc-documents',
    'kyc-documents',
    true, -- Made public for testing
    10485760, -- 10MB
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'application/pdf']
  )
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ============================================================================
-- STEP 2: DROP ALL EXISTING STORAGE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "avatar_select_all" ON storage.objects;
DROP POLICY IF EXISTS "avatar_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "avatar_insert_approved" ON storage.objects;
DROP POLICY IF EXISTS "avatar_update_own" ON storage.objects;
DROP POLICY IF EXISTS "avatar_update_approved" ON storage.objects;
DROP POLICY IF EXISTS "avatar_delete_own" ON storage.objects;

DROP POLICY IF EXISTS "cover_select_all" ON storage.objects;
DROP POLICY IF EXISTS "cover_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "cover_insert_approved" ON storage.objects;
DROP POLICY IF EXISTS "cover_update_own" ON storage.objects;
DROP POLICY IF EXISTS "cover_update_approved" ON storage.objects;
DROP POLICY IF EXISTS "cover_delete_own" ON storage.objects;

DROP POLICY IF EXISTS "kyc_select_own" ON storage.objects;
DROP POLICY IF EXISTS "kyc_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "kyc_insert_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "kyc_update_own" ON storage.objects;
DROP POLICY IF EXISTS "kyc_delete_own" ON storage.objects;

DROP POLICY IF EXISTS "public_read_all" ON storage.objects;
DROP POLICY IF EXISTS "public_insert_all" ON storage.objects;
DROP POLICY IF EXISTS "public_update_all" ON storage.objects;
DROP POLICY IF EXISTS "public_delete_all" ON storage.objects;

-- ============================================================================
-- STEP 3: CREATE WIDE-OPEN POLICIES
-- RLS stays enabled, but policies allow everything
-- ============================================================================

-- Allow everyone to read everything
CREATE POLICY "public_read_all"
ON storage.objects FOR SELECT
USING (true);

-- Allow everyone to insert anything
CREATE POLICY "public_insert_all"
ON storage.objects FOR INSERT
WITH CHECK (true);

-- Allow everyone to update anything
CREATE POLICY "public_update_all"
ON storage.objects FOR UPDATE
USING (true);

-- Allow everyone to delete anything
CREATE POLICY "public_delete_all"
ON storage.objects FOR DELETE
USING (true);

-- ============================================================================
-- STORAGE COMPLETELY OPEN
-- No restrictions, no RLS violations possible
-- ============================================================================
