-- ============================================================================
-- AutoBid Mobile - Complete KYC Schema Fix
-- Adds all missing fields to support full KYC registration flow
-- Fixes normalization inconsistencies between Flutter model and database
-- ============================================================================

-- ============================================================================
-- SECTION 1: USERS TABLE - Add Personal Information Fields
-- ============================================================================

-- Add username (unique identifier for login)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Add name components (normalized from full_name)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS first_name TEXT,
ADD COLUMN IF NOT EXISTS last_name TEXT,
ADD COLUMN IF NOT EXISTS middle_name TEXT;

-- Add date of birth (plain text for UI display, separate from encrypted version)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS date_of_birth DATE;

-- Add biological sex
ALTER TABLE users
ADD COLUMN IF NOT EXISTS sex TEXT CHECK (sex IN ('male', 'female'));

-- Add plain text phone number (for UI display, separate from encrypted version)
ALTER TABLE users
ADD COLUMN IF NOT EXISTS phone_number TEXT;

-- Add legal acceptance timestamps
ALTER TABLE users
ADD COLUMN IF NOT EXISTS accepted_terms_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS accepted_privacy_at TIMESTAMPTZ;

-- Make critical fields NOT NULL after adding them
-- (Will fail if there's existing data without these fields - intentional)
-- Comment out if migrating existing data
ALTER TABLE users
ALTER COLUMN username SET NOT NULL,
ALTER COLUMN first_name SET NOT NULL,
ALTER COLUMN last_name SET NOT NULL,
ALTER COLUMN date_of_birth SET NOT NULL,
ALTER COLUMN sex SET NOT NULL;

-- Create index on username for fast lookup during login
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);

-- Create index on phone_number for searching
CREATE INDEX IF NOT EXISTS idx_users_phone_number ON users(phone_number);

-- ============================================================================
-- SECTION 2: USER_ADDRESSES TABLE - Add Complete Address Fields
-- ============================================================================

-- Add region (first-level administrative division)
ALTER TABLE user_addresses
ADD COLUMN IF NOT EXISTS region TEXT;

-- Add barangay (smallest administrative division in Philippines)
ALTER TABLE user_addresses
ADD COLUMN IF NOT EXISTS barangay TEXT;

-- Rename columns for consistency with Flutter model
-- Check if old columns exist before renaming
DO $$
BEGIN
  -- Rename address_line1 to street_address
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_addresses' AND column_name = 'address_line1'
  ) THEN
    ALTER TABLE user_addresses RENAME COLUMN address_line1 TO street_address;
  END IF;

  -- Rename postal_code to zipcode
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_addresses' AND column_name = 'postal_code'
  ) THEN
    ALTER TABLE user_addresses RENAME COLUMN postal_code TO zipcode;
  END IF;
END $$;

-- Make region and barangay NOT NULL
ALTER TABLE user_addresses
ALTER COLUMN region SET NOT NULL,
ALTER COLUMN barangay SET NOT NULL;

-- ============================================================================
-- SECTION 3: KYC_DOCUMENTS TABLE - Add All Document Fields
-- ============================================================================

-- National ID fields
ALTER TABLE kyc_documents
ADD COLUMN IF NOT EXISTS national_id_number TEXT,
ADD COLUMN IF NOT EXISTS national_id_front_url TEXT,
ADD COLUMN IF NOT EXISTS national_id_back_url TEXT;

-- Secondary Government ID fields
ALTER TABLE kyc_documents
ADD COLUMN IF NOT EXISTS secondary_gov_id_type TEXT,
ADD COLUMN IF NOT EXISTS secondary_gov_id_number TEXT,
ADD COLUMN IF NOT EXISTS secondary_gov_id_front_url TEXT,
ADD COLUMN IF NOT EXISTS secondary_gov_id_back_url TEXT;

-- Proof of Address fields
ALTER TABLE kyc_documents
ADD COLUMN IF NOT EXISTS proof_of_address_type TEXT,
ADD COLUMN IF NOT EXISTS proof_of_address_url TEXT;

-- Admin notes for review process
ALTER TABLE kyc_documents
ADD COLUMN IF NOT EXISTS admin_notes TEXT;

-- Rename selfie_url to selfie_with_id_url for clarity
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'kyc_documents' AND column_name = 'selfie_url'
  ) THEN
    ALTER TABLE kyc_documents RENAME COLUMN selfie_url TO selfie_with_id_url;
  END IF;
END $$;

-- Add CHECK constraints for valid document types
ALTER TABLE kyc_documents
ADD CONSTRAINT check_secondary_gov_id_type
  CHECK (secondary_gov_id_type IS NULL OR secondary_gov_id_type IN (
    'drivers_license', 'passport', 'umid', 'philhealth', 'sss', 'gsis', 'voters_id', 'prc_id', 'postal_id'
  ));

ALTER TABLE kyc_documents
ADD CONSTRAINT check_proof_of_address_type
  CHECK (proof_of_address_type IS NULL OR proof_of_address_type IN (
    'utility_bill', 'bank_statement', 'government_issued_document', 'barangay_certificate', 'lease_contract'
  ));

-- Make required KYC document fields NOT NULL
ALTER TABLE kyc_documents
ALTER COLUMN national_id_front_url SET NOT NULL,
ALTER COLUMN national_id_back_url SET NOT NULL,
ALTER COLUMN selfie_with_id_url SET NOT NULL;

-- ============================================================================
-- SECTION 4: UPDATE EXISTING RLS POLICIES (if needed)
-- ============================================================================

-- RLS policies already exist from 00003_rls_policies.sql
-- No changes needed - existing policies cover new columns automatically

-- ============================================================================
-- SECTION 5: CREATE HELPER FUNCTION FOR REGISTRATION
-- ============================================================================

-- Function to insert complete KYC registration across 3 tables atomically
CREATE OR REPLACE FUNCTION register_user_with_kyc(
  p_user_id UUID,
  p_email TEXT,
  p_username TEXT,
  p_phone_number TEXT,
  p_first_name TEXT,
  p_last_name TEXT,
  p_middle_name TEXT,
  p_date_of_birth DATE,
  p_sex TEXT,
  p_region TEXT,
  p_province TEXT,
  p_city TEXT,
  p_barangay TEXT,
  p_street_address TEXT,
  p_zipcode TEXT,
  p_national_id_number TEXT,
  p_national_id_front_url TEXT,
  p_national_id_back_url TEXT,
  p_secondary_gov_id_type TEXT,
  p_secondary_gov_id_number TEXT,
  p_secondary_gov_id_front_url TEXT,
  p_secondary_gov_id_back_url TEXT,
  p_proof_of_address_type TEXT,
  p_proof_of_address_url TEXT,
  p_selfie_with_id_url TEXT,
  p_accepted_terms_at TIMESTAMPTZ,
  p_accepted_privacy_at TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  v_user_role_id UUID;
  v_kyc_status_id UUID;
  v_user_address_id UUID;
  v_kyc_document_id UUID;
BEGIN
  -- Get buyer role ID (default for new registrations)
  SELECT id INTO v_user_role_id FROM user_roles WHERE role_name = 'buyer';

  -- Get pending KYC status ID
  SELECT id INTO v_kyc_status_id FROM kyc_statuses WHERE status_name = 'pending';

  -- Insert into users table
  INSERT INTO users (
    id, email, username, phone_number,
    full_name, first_name, last_name, middle_name,
    date_of_birth, sex,
    role_id, is_verified, is_active,
    accepted_terms_at, accepted_privacy_at
  ) VALUES (
    p_user_id, p_email, p_username, p_phone_number,
    CONCAT_WS(' ', p_first_name, p_middle_name, p_last_name),
    p_first_name, p_last_name, p_middle_name,
    p_date_of_birth, p_sex,
    v_user_role_id, FALSE, TRUE,
    p_accepted_terms_at, p_accepted_privacy_at
  );

  -- Insert into user_addresses table
  INSERT INTO user_addresses (
    user_id, region, province, city, barangay,
    street_address, zipcode, country, is_default
  ) VALUES (
    p_user_id, p_region, p_province, p_city, p_barangay,
    p_street_address, p_zipcode, 'Philippines', TRUE
  )
  RETURNING id INTO v_user_address_id;

  -- Insert into kyc_documents table
  INSERT INTO kyc_documents (
    user_id, status_id, document_type,
    national_id_number,
    national_id_front_url, national_id_back_url,
    secondary_gov_id_type, secondary_gov_id_number,
    secondary_gov_id_front_url, secondary_gov_id_back_url,
    proof_of_address_type, proof_of_address_url,
    selfie_with_id_url,
    submitted_at
  ) VALUES (
    p_user_id, v_kyc_status_id, 'national_id',
    p_national_id_number,
    p_national_id_front_url, p_national_id_back_url,
    p_secondary_gov_id_type, p_secondary_gov_id_number,
    p_secondary_gov_id_front_url, p_secondary_gov_id_back_url,
    p_proof_of_address_type, p_proof_of_address_url,
    p_selfie_with_id_url,
    NOW()
  )
  RETURNING id INTO v_kyc_document_id;

  -- Add to KYC review queue
  INSERT INTO kyc_review_queue (
    kyc_document_id,
    priority,
    sla_deadline
  ) VALUES (
    v_kyc_document_id,
    0,
    NOW() + INTERVAL '48 hours'
  );

  -- Return success with IDs
  RETURN json_build_object(
    'success', TRUE,
    'user_id', p_user_id,
    'address_id', v_user_address_id,
    'kyc_document_id', v_kyc_document_id
  );

EXCEPTION
  WHEN unique_violation THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Username or email already exists'
    );
  WHEN foreign_key_violation THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Invalid reference data'
    );
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SECTION 6: GRANT PERMISSIONS
-- ============================================================================

-- Grant execute permission on registration function to authenticated users
GRANT EXECUTE ON FUNCTION register_user_with_kyc TO authenticated;

-- ============================================================================
-- SECTION 7: VALIDATION QUERIES (Run manually to verify)
-- ============================================================================

-- Verify all new columns in users table
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'users'
-- AND column_name IN (
--   'username', 'first_name', 'last_name', 'middle_name',
--   'date_of_birth', 'sex', 'phone_number',
--   'accepted_terms_at', 'accepted_privacy_at'
-- )
-- ORDER BY column_name;

-- Verify all new columns in user_addresses table
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'user_addresses'
-- AND column_name IN ('region', 'barangay', 'street_address', 'zipcode')
-- ORDER BY column_name;

-- Verify all new columns in kyc_documents table
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'kyc_documents'
-- AND column_name IN (
--   'national_id_number', 'national_id_front_url', 'national_id_back_url',
--   'secondary_gov_id_type', 'secondary_gov_id_number',
--   'secondary_gov_id_front_url', 'secondary_gov_id_back_url',
--   'proof_of_address_type', 'proof_of_address_url',
--   'selfie_with_id_url', 'admin_notes'
-- )
-- ORDER BY column_name;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
