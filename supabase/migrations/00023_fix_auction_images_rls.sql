-- ============================================================================
-- AutoBid Mobile - Migration 00023: Fix auction-images Bucket RLS for Drafts
-- Allow sellers to upload photos during draft creation (before auction exists)
-- ============================================================================

-- ============================================================================
-- SECTION 1: Drop Old Restrictive Policy
-- ============================================================================

-- Drop the old policy that only allowed uploads to existing auctions
DROP POLICY IF EXISTS "Sellers can upload auction images" ON storage.objects;

-- ============================================================================
-- SECTION 2: Create New Flexible Policy for Drafts and Auctions
-- ============================================================================

-- Policy: Allow sellers to upload images for their own listing drafts OR auctions
CREATE POLICY "Sellers can upload auction and draft images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'auction-images' AND (
      -- Allow if first path segment matches a listing_draft owned by user
      EXISTS (
        SELECT 1 FROM listing_drafts
        WHERE id::text = (storage.foldername(name))[1]
        AND seller_id = auth.uid()
        AND deleted_at IS NULL
      )
      OR
      -- Allow if first path segment matches an auction owned by user
      EXISTS (
        SELECT 1 FROM auctions
        WHERE id::text = (storage.foldername(name))[1]
        AND seller_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- SECTION 3: Update Policy for Reading Images
-- ============================================================================

-- Drop old policy if exists
DROP POLICY IF EXISTS "Anyone can view auction images" ON storage.objects;

-- Policy: Public can view all images in auction-images bucket
CREATE POLICY "Public can view auction images"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'auction-images');

-- ============================================================================
-- SECTION 4: Update Policy for Deleting Images
-- ============================================================================

-- Drop old delete policy if exists
DROP POLICY IF EXISTS "Sellers can delete auction images" ON storage.objects;

-- Policy: Sellers can delete their own listing/auction images
CREATE POLICY "Sellers can delete their auction and draft images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'auction-images' AND (
      -- Allow if path matches a listing_draft owned by user
      EXISTS (
        SELECT 1 FROM listing_drafts
        WHERE id::text = (storage.foldername(name))[1]
        AND seller_id = auth.uid()
      )
      OR
      -- Allow if path matches an auction owned by user
      EXISTS (
        SELECT 1 FROM auctions
        WHERE id::text = (storage.foldername(name))[1]
        AND seller_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- SECTION 5: Update Policy for Updating Images
-- ============================================================================

-- Drop old update policy if exists
DROP POLICY IF EXISTS "Sellers can update auction images" ON storage.objects;

-- Policy: Sellers can update (replace) their own listing/auction images
CREATE POLICY "Sellers can update their auction and draft images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'auction-images' AND (
      EXISTS (
        SELECT 1 FROM listing_drafts
        WHERE id::text = (storage.foldername(name))[1]
        AND seller_id = auth.uid()
        AND deleted_at IS NULL
      )
      OR
      EXISTS (
        SELECT 1 FROM auctions
        WHERE id::text = (storage.foldername(name))[1]
        AND seller_id = auth.uid()
      )
    )
  );

-- ============================================================================
-- SECTION 6: Verification Query
-- ============================================================================

-- View all policies on storage.objects for auction-images bucket
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE schemaname = 'storage' AND tablename = 'objects'
-- AND policyname LIKE '%auction%';

-- ============================================================================
-- NOTES
-- ============================================================================

-- Storage path format: {listing_draft_id}/{category}/{filename}
-- Example: "123e4567-e89b-12d3-a456-426614174000/exterior/exterior_1234567890.jpg"
--
-- The RLS policy extracts the first path segment (listing_draft_id or auction_id)
-- using storage.foldername(name)[1] and checks if it exists in listing_drafts
-- or auctions table with seller_id = auth.uid()
--
-- This allows:
-- - Sellers to upload photos during draft creation (before auction exists)
-- - Sellers to upload photos to live auctions
-- - Public to view all photos (listings are public)
-- - Sellers to delete/update only their own photos

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
