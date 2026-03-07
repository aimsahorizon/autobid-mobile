-- Adds selected featured photo support for listing drafts.
-- The mobile app writes cover_photo_url during photo upload/selection.

ALTER TABLE public.listing_drafts
ADD COLUMN IF NOT EXISTS cover_photo_url TEXT;

COMMENT ON COLUMN public.listing_drafts.cover_photo_url IS
'Seller-selected featured photo URL used as listing cover after submission.';

-- Backfill existing drafts: choose first available photo in priority order.
UPDATE public.listing_drafts ld
SET cover_photo_url = COALESCE(
  NULLIF((ld.photo_urls -> 'exterior' ->> 0), ''),
  NULLIF((ld.photo_urls -> 'interior' ->> 0), ''),
  NULLIF((ld.photo_urls -> 'engine' ->> 0), ''),
  NULLIF((ld.photo_urls -> 'details' ->> 0), ''),
  NULLIF((ld.photo_urls -> 'documents' ->> 0), ''),
  ld.cover_photo_url
)
WHERE ld.cover_photo_url IS NULL;
