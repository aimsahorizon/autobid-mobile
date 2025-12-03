-- ============================================================================
-- STORAGE BUCKETS AND POLICIES - FINAL FIX
-- NO RLS recursion - NO status checks - WORKS during registration
-- ============================================================================

-- ============================================================================
-- STEP 1: Create storage buckets
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
    false, -- Private bucket
    10485760, -- 10MB
    ARRAY['image/jpeg', 'image/png', 'image/jpg', 'image/webp', 'application/pdf']
  );

-- ============================================================================
-- DROP ALL EXISTING STORAGE POLICIES
-- ============================================================================

DROP POLICY IF EXISTS "avatar_select_all" ON storage.objects;
DROP POLICY IF EXISTS "avatar_insert_approved" ON storage.objects;
DROP POLICY IF EXISTS "avatar_update_approved" ON storage.objects;
DROP POLICY IF EXISTS "avatar_delete_own" ON storage.objects;

DROP POLICY IF EXISTS "cover_select_all" ON storage.objects;
DROP POLICY IF EXISTS "cover_insert_approved" ON storage.objects;
DROP POLICY IF EXISTS "cover_update_approved" ON storage.objects;
DROP POLICY IF EXISTS "cover_delete_own" ON storage.objects;

DROP POLICY IF EXISTS "kyc_select_own" ON storage.objects;
DROP POLICY IF EXISTS "kyc_insert_authenticated" ON storage.objects;
DROP POLICY IF EXISTS "kyc_update_own" ON storage.objects;
DROP POLICY IF EXISTS "kyc_delete_own" ON storage.objects;

-- ============================================================================
-- USER AVATARS POLICIES - SIMPLE, NO STATUS CHECKS
-- ============================================================================

CREATE POLICY "avatar_select_all"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-avatars');

CREATE POLICY "avatar_insert_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "avatar_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'user-avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "avatar_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- USER COVERS POLICIES - SIMPLE, NO STATUS CHECKS
-- ============================================================================

CREATE POLICY "cover_select_all"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-covers');

CREATE POLICY "cover_insert_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "cover_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'user-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "cover_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- KYC DOCUMENTS POLICIES - SIMPLE, NO STATUS CHECKS
-- ============================================================================

CREATE POLICY "kyc_select_own"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "kyc_insert_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "kyc_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "kyc_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- STORAGE COMPLETE - NO RLS RECURSION POSSIBLE
-- All authenticated users can upload to their own folders
-- No status checks, no table queries
-- ============================================================================
