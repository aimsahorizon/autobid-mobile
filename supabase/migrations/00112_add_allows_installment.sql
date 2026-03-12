-- Add allows_installment column to listing_drafts
ALTER TABLE listing_drafts
ADD COLUMN IF NOT EXISTS allows_installment BOOLEAN DEFAULT FALSE;

-- Also add to auctions table for consistency
ALTER TABLE auctions
ADD COLUMN IF NOT EXISTS allows_installment BOOLEAN DEFAULT FALSE;