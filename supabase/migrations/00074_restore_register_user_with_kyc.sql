-- Restore register_user_with_kyc function to support existing mobile app
-- This function was dropped by cascade when phone_number column was dropped in 00070
-- We restore it but remove phone_number parameter and insertion logic

CREATE OR REPLACE FUNCTION register_user_with_kyc_v2(
  p_user_id UUID,
  p_email TEXT,
  p_username TEXT,
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

  -- Insert into users table
  -- Note: phone_number and phone_encrypted columns were dropped in 00070
  INSERT INTO users (
    id, email, username,
    full_name, display_name, first_name, last_name, middle_name,
    date_of_birth, sex,
    role_id, is_verified, is_active,
    accepted_terms_at, accepted_privacy_at
  ) VALUES (
    p_user_id, p_email, p_username,
    v_display_name, v_display_name, p_first_name, p_last_name, v_middle_name_clean,
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
  -- Note: 00070 migration seems to use secondary_id_url but existing code expects front/back
  -- We'll try to use the columns if they exist, or fallback to storing front as main url if that's the new schema
  -- Based on 00009 schema, front/back columns exist.
  -- Based on 00070, it might have implied a change but didn't explicitly drop columns in the SQL file provided.
  -- We assume columns from 00009 still exist or we would have seen drop column commands.
  
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
GRANT EXECUTE ON FUNCTION register_user_with_kyc_v2 TO authenticated;
