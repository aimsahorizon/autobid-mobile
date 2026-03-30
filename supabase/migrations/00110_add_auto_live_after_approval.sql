-- Adds auto-live preference for listing drafts and auctions.

ALTER TABLE public.listing_drafts
ADD COLUMN IF NOT EXISTS auto_live_after_approval BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE public.auctions
ADD COLUMN IF NOT EXISTS auto_live_after_approval BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.listing_drafts.auto_live_after_approval IS
'Seller preference set during listing creation. If true, listing is preferred to auto-live after approval.';

COMMENT ON COLUMN public.auctions.auto_live_after_approval IS
'Persisted auto-live preference copied from listing_drafts at submission time.';
