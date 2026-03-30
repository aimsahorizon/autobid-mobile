-- Add scheduling columns to listing_drafts table
ALTER TABLE listing_drafts
  ADD COLUMN IF NOT EXISTS schedule_live_mode TEXT DEFAULT 'auto_live',
  ADD COLUMN IF NOT EXISTS auction_start_date TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS auction_duration_hours INT;
