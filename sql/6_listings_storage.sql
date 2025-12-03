-- ============================================================================
-- STORAGE BUCKETS AND POLICIES FOR LISTINGS
-- ============================================================================

-- Create storage bucket for listing photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('listing-photos', 'listing-photos', true)
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- STORAGE POLICIES FOR LISTING PHOTOS
-- ============================================================================

-- Policy: Anyone can view listing photos (public bucket)
CREATE POLICY "listing_photos_select_public"
ON storage.objects FOR SELECT
USING (bucket_id = 'listing-photos');

-- Policy: Authenticated users can upload their own listing photos
-- Path structure: {user_id}/{listing_id}/{category}/{filename}
CREATE POLICY "listing_photos_insert_own"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'listing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can update their own listing photos
CREATE POLICY "listing_photos_update_own"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'listing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
)
WITH CHECK (
  bucket_id = 'listing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy: Users can delete their own listing photos
CREATE POLICY "listing_photos_delete_own"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'listing-photos'
  AND auth.uid()::text = (storage.foldername(name))[1]
);

-- ============================================================================
-- STORAGE POLICIES COMPLETE
-- All SQL schemas ready for deployment
-- ============================================================================
