-- ============================================================================
-- Migration: Add checklist photo proof columns for delivery steps
-- ============================================================================

-- Photo proof URLs for each delivery step
ALTER TABLE auction_transactions
  ADD COLUMN IF NOT EXISTS seller_prep_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS seller_transit_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS seller_delivery_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS buyer_delivery_photo_url TEXT;
