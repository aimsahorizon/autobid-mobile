-- ============================================================================
-- AutoBid Mobile - Migration 00012: Update Sex Constraint to Accept Multiple Values
-- Allow both short ('M', 'F') and full ('male', 'female') formats
-- ============================================================================

-- Drop existing constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_sex_check;

-- Add new constraint that accepts both formats
ALTER TABLE users ADD CONSTRAINT users_sex_check
  CHECK (sex IN ('M', 'F', 'male', 'female'));

-- Verification query
-- SELECT sex, COUNT(*) FROM users GROUP BY sex;

-- Expected values: 'M', 'F', 'male', or 'female'

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
