-- ============================================================================
-- STORAGE BUCKETS AND POLICIES
-- Simple, conflict-free, production-ready
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
-- STEP 2: USER AVATARS POLICIES (PUBLIC BUCKET)
-- Profile photos added AFTER KYC approval - NOT during registration
-- ============================================================================

-- Anyone can view avatars
CREATE POLICY "avatar_select_all"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-avatars');

-- Approved users can upload avatar
CREATE POLICY "avatar_insert_approved"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND status = 'approved'
      AND deleted_at IS NULL
  )
);

-- Approved users can update avatar
CREATE POLICY "avatar_update_approved"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'user-avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND status = 'approved'
      AND deleted_at IS NULL
  )
);

-- Users can delete their own avatar
CREATE POLICY "avatar_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- STEP 3: USER COVERS POLICIES (PUBLIC BUCKET)
-- Cover photos added AFTER KYC approval - NOT during registration
-- ============================================================================

-- Anyone can view covers
CREATE POLICY "cover_select_all"
ON storage.objects FOR SELECT
USING (bucket_id = 'user-covers');

-- Approved users can upload cover
CREATE POLICY "cover_insert_approved"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND status = 'approved'
      AND deleted_at IS NULL
  )
);

-- Approved users can update cover
CREATE POLICY "cover_update_approved"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'user-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
      AND status = 'approved'
      AND deleted_at IS NULL
  )
);

-- Users can delete their own cover
CREATE POLICY "cover_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-covers'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- STEP 4: KYC DOCUMENTS POLICIES (PRIVATE BUCKET)
-- KYC documents uploaded DURING registration (pending users can upload)
-- ============================================================================

-- Users can view their own KYC documents
CREATE POLICY "kyc_select_own"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Authenticated users can upload KYC documents (even if pending)
CREATE POLICY "kyc_insert_authenticated"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'kyc-documents'
  AND auth.role() = 'authenticated'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can update their own KYC documents (for re-upload)
CREATE POLICY "kyc_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Users can delete their own KYC documents
CREATE POLICY "kyc_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'kyc-documents'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- ADMIN ACCESS TO KYC DOCUMENTS
-- Admins use service_role key (bypasses RLS) to view all KYC documents
-- This prevents RLS recursion issues
-- ============================================================================

-- ============================================================================
-- FOLDER STRUCTURE
-- ============================================================================
-- user-avatars/{user_id}/avatar.jpg (AFTER approval)
-- user-covers/{user_id}/cover.jpg (AFTER approval)
-- kyc-documents/{user_id}/national_id_front.jpg (DURING registration)
-- kyc-documents/{user_id}/national_id_back.jpg
-- kyc-documents/{user_id}/selfie_with_id.jpg
-- kyc-documents/{user_id}/secondary_gov_id_front.jpg
-- kyc-documents/{user_id}/secondary_gov_id_back.jpg
-- kyc-documents/{user_id}/proof_of_address.pdf

-- ============================================================================
-- STORAGE SETUP COMPLETE
-- Database is ready for authentication module
-- ============================================================================
