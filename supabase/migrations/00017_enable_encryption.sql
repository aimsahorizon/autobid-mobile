-- ============================================================================
-- AutoBid Mobile - Migration 00016: Enable Encryption for Sensitive Fields
-- Populate phone_encrypted and date_of_birth_encrypted during registration
-- ============================================================================

-- ============================================================================
-- SECTION 1: Update RPC Function to Include Encryption
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS register_user_with_kyc;

-- Recreate function with encryption support
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
  v_middle_name_clean TEXT;
  v_encryption_key TEXT;
  v_phone_encrypted BYTEA;
  v_dob_encrypted BYTEA;
  v_display_name TEXT;
BEGIN
  -- Get buyer role ID (default for new registrations)
  SELECT id INTO v_user_role_id FROM user_roles WHERE role_name = 'buyer';

  -- Get pending KYC status ID
  SELECT id INTO v_kyc_status_id FROM kyc_statuses WHERE status_name = 'pending';

  -- Clean middle name (convert empty string to NULL)
  v_middle_name_clean := NULLIF(TRIM(p_middle_name), '');

  -- Build display name (first + last, or first + middle + last)
  IF v_middle_name_clean IS NOT NULL THEN
    v_display_name := CONCAT_WS(' ', p_first_name, v_middle_name_clean, p_last_name);
  ELSE
    v_display_name := CONCAT_WS(' ', p_first_name, p_last_name);
  END IF;

  -- Get encryption key from Supabase app settings
  -- In production, this should come from Supabase Vault or environment variable
  -- For now, using a placeholder - YOU MUST SET THIS in your Supabase project settings
  v_encryption_key := current_setting('app.encryption_key', true);

  -- If encryption key is not set, use a default (NOT RECOMMENDED for production)
  IF v_encryption_key IS NULL OR v_encryption_key = '' THEN
    v_encryption_key := 'CHANGE_THIS_IN_PRODUCTION';
    RAISE WARNING 'Using default encryption key. Set app.encryption_key in Supabase settings for production.';
  END IF;

  -- Encrypt sensitive fields
  v_phone_encrypted := encrypt_field(p_phone_number, v_encryption_key);
  v_dob_encrypted := encrypt_field(p_date_of_birth::TEXT, v_encryption_key);

  -- Insert into users table (with both encrypted and plain text versions)
  INSERT INTO users (
    id, email, username,
    phone_number, phone_encrypted,
    full_name, display_name, first_name, last_name, middle_name,
    date_of_birth, date_of_birth_encrypted, sex,
    role_id, is_verified, is_active,
    accepted_terms_at, accepted_privacy_at
  ) VALUES (
    p_user_id, p_email, p_username,
    p_phone_number, v_phone_encrypted,
    v_display_name, v_display_name, p_first_name, p_last_name, v_middle_name_clean,
    p_date_of_birth, v_dob_encrypted, p_sex,
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
    NULLIF(TRIM(p_secondary_gov_id_type), ''), NULLIF(TRIM(p_secondary_gov_id_number), ''),
    NULLIF(TRIM(p_secondary_gov_id_front_url), ''), NULLIF(TRIM(p_secondary_gov_id_back_url), ''),
    NULLIF(TRIM(p_proof_of_address_type), ''), NULLIF(TRIM(p_proof_of_address_url), ''),
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

  -- Note: auth.users metadata sync happens automatically via trigger from migration 00015

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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION register_user_with_kyc TO authenticated;

-- ============================================================================
-- SECTION 2: Set Encryption Key (REQUIRED MANUAL STEP)
-- ============================================================================

-- IMPORTANT: After running this migration, you MUST set the encryption key
-- in your Supabase project settings:
--
-- Option 1: Using Supabase Dashboard
-- 1. Go to Project Settings > API
-- 2. Add custom config: app.encryption_key = 'your-strong-random-key-here'
--
-- Option 2: Using SQL (temporary session variable, resets on restart)
-- ALTER DATABASE postgres SET app.encryption_key = 'your-strong-random-key-here';
--
-- Option 3: Generate a strong random key
-- SELECT encode(gen_random_bytes(32), 'base64');

-- ============================================================================
-- SECTION 3: Verification Queries
-- ============================================================================

-- Verify encrypted fields are populated (run after registration test):
-- SELECT
--   id,
--   email,
--   phone_number,
--   phone_encrypted IS NOT NULL as has_encrypted_phone,
--   date_of_birth,
--   date_of_birth_encrypted IS NOT NULL as has_encrypted_dob
-- FROM users
-- LIMIT 5;

-- Test decryption (replace 'your-key' with actual key):
-- SELECT
--   email,
--   phone_number as plain_phone,
--   decrypt_field(phone_encrypted, 'your-key') as decrypted_phone,
--   date_of_birth as plain_dob,
--   decrypt_field(date_of_birth_encrypted, 'your-key') as decrypted_dob
-- FROM users
-- WHERE phone_encrypted IS NOT NULL
-- LIMIT 1;

-- ============================================================================
-- SECTION 4: Migration Notes
-- ============================================================================

-- Changes from previous version (00014):
-- 1. Added encryption for phone_number → phone_encrypted
-- 2. Added encryption for date_of_birth → date_of_birth_encrypted
-- 3. Added display_name field (synced to auth.users via trigger)
-- 4. Both plain text and encrypted versions stored for flexibility
-- 5. Encryption key retrieved from app settings

-- Security considerations:
-- - Encryption key MUST be rotated regularly
-- - Plain text versions allow UI queries without decryption overhead
-- - Encrypted versions provide compliance with data protection regulations
-- - Use Supabase Vault for document storage in future (national_id_vault_key)

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
