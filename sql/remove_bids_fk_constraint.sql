-- ============================================================================
-- REMOVE FOREIGN KEY CONSTRAINT ON BIDS TABLE
-- This allows bids to be placed without requiring user to exist in users table
-- ============================================================================

-- Remove the foreign key constraint
ALTER TABLE bids DROP CONSTRAINT IF EXISTS bids_bidder_id_fkey;

-- Verify the constraint is removed
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'bids'::regclass;

-- Test: You should now be able to place bids
-- The bid will store the UUID even if the user doesn't exist in users table
