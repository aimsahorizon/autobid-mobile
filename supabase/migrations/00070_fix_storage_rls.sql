-- Fix storage RLS to allow uploads for drafts and fix invites logic

-- 1. Update storage RLS for auction-images
-- We need to allow uploads if the folder name matches a draft ID owned by the user
DROP POLICY IF EXISTS "Sellers can upload auction images" ON storage.objects;

CREATE POLICY "Sellers can upload auction images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'auction-images' AND
  (
    -- Allow if path starts with user ID (legacy/profile)
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Allow if path starts with an auction ID owned by user
    EXISTS (
      SELECT 1 FROM public.auctions
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
    OR
    -- Allow if path starts with a draft ID owned by user
    EXISTS (
      SELECT 1 FROM public.listing_drafts
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
  )
);

-- Ensure update/delete policies also cover drafts
DROP POLICY IF EXISTS "Sellers can delete auction images" ON storage.objects;

CREATE POLICY "Sellers can delete auction images"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'auction-images' AND
  (
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    EXISTS (
      SELECT 1 FROM public.auctions
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
    OR
    EXISTS (
      SELECT 1 FROM public.listing_drafts
      WHERE id::text = (storage.foldername(name))[1]
      AND seller_id = auth.uid()
    )
  )
);

-- 2. No changes needed for notifications as they are handled by 00053 and 00051 correctly.
