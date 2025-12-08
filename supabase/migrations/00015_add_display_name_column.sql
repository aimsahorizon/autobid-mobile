-- ============================================================================
-- AutoBid Mobile - Migration 00015: Add display_name Column
-- Add missing display_name column to users table before sync trigger
-- ============================================================================

-- Add display_name column to users table
ALTER TABLE users
ADD COLUMN IF NOT EXISTS display_name TEXT;

-- Backfill display_name from full_name for existing users
UPDATE users
SET display_name = full_name
WHERE display_name IS NULL AND full_name IS NOT NULL;

-- Create index for performance
CREATE INDEX IF NOT EXISTS idx_users_display_name ON users(display_name);

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
