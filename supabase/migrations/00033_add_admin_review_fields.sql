-- ============================================================================
-- AutoBid Mobile - Migration 00033: Add Admin Review Fields to Auctions
-- Add fields to track listing submission and admin review process
-- ============================================================================

-- ============================================================================
-- PROBLEM:
-- ============================================================================
-- Admin panel tries to access review fields that don't exist in auctions table:
-- - submitted_at (when seller submitted listing for review)
-- - review_notes (admin notes during review)
-- - reviewed_at (when admin reviewed the listing)
-- - reviewed_by (which admin reviewed it)

-- ============================================================================
-- SOLUTION: Add admin review tracking fields to auctions table
-- ============================================================================

-- Add admin review fields to auctions table
ALTER TABLE auctions
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS review_notes TEXT,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS reviewed_by UUID REFERENCES admin_users(id) ON DELETE SET NULL;

-- Add comment to document fields
COMMENT ON COLUMN auctions.submitted_at IS 'Timestamp when seller submitted listing for admin review';
COMMENT ON COLUMN auctions.review_notes IS 'Admin notes and feedback during listing review';
COMMENT ON COLUMN auctions.reviewed_at IS 'Timestamp when admin reviewed the listing';
COMMENT ON COLUMN auctions.reviewed_by IS 'Admin user who reviewed this listing';

-- Create index on submitted_at for filtering pending listings by submission time
CREATE INDEX IF NOT EXISTS idx_auctions_submitted_at
  ON auctions(submitted_at)
  WHERE submitted_at IS NOT NULL;

-- Create index on reviewed_by for admin activity tracking
CREATE INDEX IF NOT EXISTS idx_auctions_reviewed_by
  ON auctions(reviewed_by)
  WHERE reviewed_by IS NOT NULL;

-- ============================================================================
-- VERIFICATION QUERIES (Run these to test)
-- ============================================================================
-- 1. Check if columns were added:
--    SELECT column_name, data_type, is_nullable
--    FROM information_schema.columns
--    WHERE table_name = 'auctions'
--    AND column_name IN ('submitted_at', 'review_notes', 'reviewed_at', 'reviewed_by');
--
-- 2. Test query with new fields:
--    SELECT
--      id,
--      title,
--      status_id,
--      submitted_at,
--      reviewed_at,
--      reviewed_by,
--      review_notes
--    FROM auctions
--    LIMIT 5;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
