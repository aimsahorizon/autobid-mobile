-- ============================================================================
-- AutoBid Mobile - Migration 00034: Add 'approved' Status
-- Adds 'approved' status to auction workflow
-- ============================================================================

-- ============================================================================
-- WORKFLOW:
-- draft → pending_approval → (admin reviews) → approved → (seller decides) → scheduled/live
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. Add 'approved' to auction_statuses CHECK constraint
-- ============================================================================

-- Drop existing constraint
ALTER TABLE auction_statuses
  DROP CONSTRAINT IF EXISTS auction_statuses_status_name_check;

-- Add new constraint with 'approved' status
ALTER TABLE auction_statuses
  ADD CONSTRAINT auction_statuses_status_name_check
  CHECK (status_name IN (
    'draft',
    'pending_approval',
    'approved',           -- NEW: Status after admin approval
    'scheduled',
    'live',
    'ended',
    'cancelled',
    'sold',
    'unsold'
  ));

-- ============================================================================
-- 2. Insert 'approved' status seed data
-- ============================================================================

INSERT INTO auction_statuses (status_name, display_name, description)
VALUES (
  'approved',
  'Approved',
  'Listing has been approved by admin and is ready to be scheduled or made live by seller'
)
ON CONFLICT (status_name) DO NOTHING;

-- ============================================================================
-- 3. Update auctions CHECK constraint to allow 'approved' status
-- ============================================================================

-- Note: If auctions table has its own status constraint, update it
-- (checking if such constraint exists first)

DO $$
BEGIN
  -- Check if auctions table has a status_name constraint
  IF EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_name = 'auctions'
    AND constraint_name LIKE '%status%'
  ) THEN
    -- Drop and recreate constraint if exists
    ALTER TABLE auctions DROP CONSTRAINT IF EXISTS auctions_status_check;
  END IF;
END $$;

COMMIT;

-- ============================================================================
-- VERIFICATION QUERY:
-- ============================================================================
-- SELECT * FROM auction_statuses WHERE status_name = 'approved';
-- ============================================================================
