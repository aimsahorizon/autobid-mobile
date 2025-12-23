-- ============================================================================
-- AutoBid Mobile - Migration 00013: Fix All Constraint Issues
-- Comprehensive fix for registration constraints
-- ============================================================================

-- ============================================================================
-- SECTION 1: Fix NOT NULL Constraints
-- ============================================================================

-- Make middle_name nullable (users may not have middle names)
ALTER TABLE users ALTER COLUMN middle_name DROP NOT NULL;

-- ============================================================================
-- SECTION 2: Fix CHECK Constraints - Remove Restrictive Enums
-- ============================================================================

-- Drop existing restrictive CHECK constraints on document types
ALTER TABLE kyc_documents DROP CONSTRAINT IF EXISTS check_secondary_gov_id_type;
ALTER TABLE kyc_documents DROP CONSTRAINT IF EXISTS check_proof_of_address_type;

-- Add lenient constraints (just ensure non-empty if provided)
-- This allows frontend to send any valid document type without DB rejection
ALTER TABLE kyc_documents ADD CONSTRAINT check_secondary_gov_id_type
  CHECK (secondary_gov_id_type IS NULL OR LENGTH(TRIM(secondary_gov_id_type)) > 0);

ALTER TABLE kyc_documents ADD CONSTRAINT check_proof_of_address_type
  CHECK (proof_of_address_type IS NULL OR LENGTH(TRIM(proof_of_address_type)) > 0);

-- Note: Validation should happen in Flutter UI, not database constraints
-- This prevents deployment issues when adding new document types

-- ============================================================================
-- SECTION 3: Verify Sex Constraint is Updated
-- ============================================================================

-- Ensure sex constraint accepts both formats (from migration 00012)
-- If migration 00012 wasn't run, this will update it
DO $$
BEGIN
  -- Drop old constraint if exists
  ALTER TABLE users DROP CONSTRAINT IF EXISTS users_sex_check;

  -- Add new constraint accepting both short and full formats
  ALTER TABLE users ADD CONSTRAINT users_sex_check
    CHECK (sex IN ('m', 'f', 'male', 'female'));
END $$;

-- ============================================================================
-- SECTION 4: Add Missing Indexes for Performance
-- ============================================================================

-- Index on secondary_gov_id_type for admin searches
CREATE INDEX IF NOT EXISTS idx_kyc_documents_secondary_gov_id_type
  ON kyc_documents(secondary_gov_id_type) WHERE secondary_gov_id_type IS NOT NULL;

-- Index on proof_of_address_type for admin searches
CREATE INDEX IF NOT EXISTS idx_kyc_documents_proof_of_address_type
  ON kyc_documents(proof_of_address_type) WHERE proof_of_address_type IS NOT NULL;

-- ============================================================================
-- SECTION 5: Validation Queries
-- ============================================================================

-- Verify constraints were updated
-- SELECT constraint_name, check_clause
-- FROM information_schema.check_constraints
-- WHERE constraint_schema = 'public'
-- AND constraint_name LIKE '%kyc_documents%';

-- Verify NOT NULL status
-- SELECT column_name, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'users'
-- AND column_name IN ('middle_name', 'first_name', 'last_name');

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
