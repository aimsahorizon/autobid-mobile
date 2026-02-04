-- ============================================================================
-- AutoBid Mobile - Migration 00073: Add is_plate_valid column to listing_drafts
-- Adds validation flag to drafts to persist plate validation status
-- ============================================================================

ALTER TABLE listing_drafts 
ADD COLUMN IF NOT EXISTS is_plate_valid BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN listing_drafts.is_plate_valid IS 'Tracks if the plate number has been validated against external APIs';
