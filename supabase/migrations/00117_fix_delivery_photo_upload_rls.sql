-- ============================================================================
-- Migration 00117: Fix delivery photo upload storage RLS
-- Allow transaction participants to upload checklist photos to auction-images bucket
-- ============================================================================

-- The existing upload policy only allows auction/draft/user-id folders.
-- Delivery photos are uploaded to 'checklist/<transaction_id>/...' which is blocked.

-- Drop and recreate the INSERT policy to also allow checklist uploads
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
    OR
    -- Allow checklist uploads for transaction participants (seller or buyer)
    (
      (storage.foldername(name))[1] = 'checklist'
      AND EXISTS (
        SELECT 1 FROM public.auction_transactions
        WHERE id::text = (storage.foldername(name))[2]
        AND (seller_id = auth.uid() OR buyer_id = auth.uid())
      )
    )
  )
);

-- Also update the delete policy so participants can replace checklist photos
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
    OR
    (
      (storage.foldername(name))[1] = 'checklist'
      AND EXISTS (
        SELECT 1 FROM public.auction_transactions
        WHERE id::text = (storage.foldername(name))[2]
        AND (seller_id = auth.uid() OR buyer_id = auth.uid())
      )
    )
  )
);

-- Also need an update policy for upsert (used by uploadChecklistPhoto with upsert: true)
DROP POLICY IF EXISTS "Sellers can update auction images" ON storage.objects;

CREATE POLICY "Sellers can update auction images"
ON storage.objects FOR UPDATE
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
    OR
    (
      (storage.foldername(name))[1] = 'checklist'
      AND EXISTS (
        SELECT 1 FROM public.auction_transactions
        WHERE id::text = (storage.foldername(name))[2]
        AND (seller_id = auth.uid() OR buyer_id = auth.uid())
      )
    )
  )
);
