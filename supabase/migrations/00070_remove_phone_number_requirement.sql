-- Remove phone_number requirement from KYC registration
-- Phone number is no longer required for account registration

-- 1. Drop phone_number column from users table
ALTER TABLE public.users DROP COLUMN IF EXISTS phone_number CASCADE;
ALTER TABLE public.users DROP COLUMN IF EXISTS phone_encrypted CASCADE;

-- 2. Drop phone_number index if exists
DROP INDEX IF EXISTS idx_users_phone_number;

-- 3. Update submit_kyc_registration function to remove phone_number parameter
CREATE OR REPLACE FUNCTION submit_kyc_registration(
  p_user_id UUID,
  p_email TEXT,
  p_username TEXT,
  p_first_name TEXT,
  p_middle_name TEXT,
  p_last_name TEXT,
  p_suffix TEXT,
  p_date_of_birth DATE,
  p_sex TEXT,
  p_address_line1 TEXT,
  p_address_line2 TEXT,
  p_city TEXT,
  p_province TEXT,
  p_postal_code TEXT,
  p_country TEXT,
  p_government_id_type TEXT,
  p_government_id_number TEXT,
  p_government_id_expiry DATE,
  p_selfie_with_id_url TEXT,
  p_government_id_front_url TEXT,
  p_government_id_back_url TEXT,
  p_secondary_id_type TEXT DEFAULT NULL,
  p_secondary_id_url TEXT DEFAULT NULL,
  p_proof_of_address_type TEXT DEFAULT NULL,
  p_proof_of_address_url TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  -- Insert/Update user record with KYC information
  INSERT INTO public.users (
    id, email, username,
    first_name, middle_name, last_name, suffix,
    date_of_birth, sex,
    address_line1, address_line2, city, province, postal_code, country,
    status, created_at, updated_at
  ) VALUES (
    p_user_id, p_email, p_username,
    p_first_name, p_middle_name, p_last_name, p_suffix,
    p_date_of_birth, p_sex,
    p_address_line1, p_address_line2, p_city, p_province, p_postal_code, p_country,
    'pending', NOW(), NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    username = EXCLUDED.username,
    first_name = EXCLUDED.first_name,
    middle_name = EXCLUDED.middle_name,
    last_name = EXCLUDED.last_name,
    suffix = EXCLUDED.suffix,
    date_of_birth = EXCLUDED.date_of_birth,
    sex = EXCLUDED.sex,
    address_line1 = EXCLUDED.address_line1,
    address_line2 = EXCLUDED.address_line2,
    city = EXCLUDED.city,
    province = EXCLUDED.province,
    postal_code = EXCLUDED.postal_code,
    country = EXCLUDED.country,
    status = 'pending',
    updated_at = NOW();

  -- Insert/Update KYC documents
  INSERT INTO public.kyc_documents (
    user_id,
    selfie_with_id_url,
    government_id_type, government_id_number, government_id_expiry,
    government_id_front_url, government_id_back_url,
    secondary_id_type, secondary_id_url,
    proof_of_address_type, proof_of_address_url,
    created_at, updated_at
  ) VALUES (
    p_user_id,
    p_selfie_with_id_url,
    p_government_id_type, p_government_id_number, p_government_id_expiry,
    p_government_id_front_url, p_government_id_back_url,
    p_secondary_id_type, p_secondary_id_url,
    p_proof_of_address_type, p_proof_of_address_url,
    NOW(), NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    selfie_with_id_url = EXCLUDED.selfie_with_id_url,
    government_id_type = EXCLUDED.government_id_type,
    government_id_number = EXCLUDED.government_id_number,
    government_id_expiry = EXCLUDED.government_id_expiry,
    government_id_front_url = EXCLUDED.government_id_front_url,
    government_id_back_url = EXCLUDED.government_id_back_url,
    secondary_id_type = EXCLUDED.secondary_id_type,
    secondary_id_url = EXCLUDED.secondary_id_url,
    proof_of_address_type = EXCLUDED.proof_of_address_type,
    proof_of_address_url = EXCLUDED.proof_of_address_url,
    updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION submit_kyc_registration TO authenticated;

COMMENT ON FUNCTION submit_kyc_registration IS 
'Submits KYC registration data without phone number requirement';

-- 4. Update sync_user_metadata trigger function to remove phone_number
CREATE OR REPLACE FUNCTION sync_user_metadata()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE auth.users
  SET raw_user_meta_data = jsonb_build_object(
    'display_name', NEW.display_name,
    'full_name', NEW.full_name,
    'username', NEW.username,
    'profile_image_url', NEW.profile_image_url
  )
  WHERE id = NEW.id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger
DROP TRIGGER IF EXISTS trigger_sync_user_metadata ON public.users;
CREATE TRIGGER trigger_sync_user_metadata
  AFTER INSERT OR UPDATE OF display_name, full_name, username, profile_image_url
  ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_metadata();
