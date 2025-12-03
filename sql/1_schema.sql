-- ============================================================================
-- AUTOBID AUTHENTICATION SCHEMA
-- Single users table - clean, simple, production-ready
-- Fresh database - no conflicts
-- ============================================================================

CREATE TABLE users (
  -- Auth reference (links to Supabase auth.users)
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Account credentials
  username TEXT UNIQUE NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone_number TEXT UNIQUE NOT NULL,

  -- Personal information
  first_name TEXT NOT NULL,
  middle_name TEXT,
  last_name TEXT NOT NULL,
  date_of_birth DATE NOT NULL,
  sex CHAR(1) NOT NULL CHECK (sex IN ('M', 'F')),

  -- Address information
  region TEXT NOT NULL,
  province TEXT NOT NULL,
  city TEXT NOT NULL,
  barangay TEXT NOT NULL,
  street_address TEXT NOT NULL,
  zipcode TEXT NOT NULL,

  -- National ID (Primary government-issued ID)
  national_id_number TEXT NOT NULL,
  national_id_front_url TEXT NOT NULL,
  national_id_back_url TEXT NOT NULL,
  selfie_with_id_url TEXT NOT NULL,

  -- Secondary government ID
  secondary_gov_id_type TEXT NOT NULL,
  secondary_gov_id_number TEXT NOT NULL,
  secondary_gov_id_front_url TEXT NOT NULL,
  secondary_gov_id_back_url TEXT NOT NULL,

  -- Proof of address
  proof_of_address_type TEXT NOT NULL,
  proof_of_address_url TEXT NOT NULL,

  -- Legal acceptance timestamps
  accepted_terms_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accepted_privacy_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Public profile (added after approval)
  avatar_url TEXT,
  cover_url TEXT,
  bio TEXT,
  display_name TEXT,

  -- KYC verification status
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'rejected')),
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES auth.users(id),
  rejection_reason TEXT,
  admin_notes TEXT,

  -- User role and account status
  role TEXT NOT NULL DEFAULT 'user'
    CHECK (role IN ('user', 'admin', 'moderator')),
  account_status TEXT NOT NULL DEFAULT 'active'
    CHECK (account_status IN ('active', 'suspended', 'banned')),
  is_verified BOOLEAN DEFAULT FALSE,

  -- Future features (prepared for next modules)
  subscription_tier TEXT DEFAULT 'free',
  total_bids INTEGER DEFAULT 0,
  total_listings INTEGER DEFAULT 0,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- INDEXES for performance
-- ============================================================================

CREATE INDEX idx_users_username ON users(username) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_email ON users(email) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_phone ON users(phone_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_status ON users(status) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(role) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_public_active ON users(status, account_status)
  WHERE status = 'approved' AND account_status = 'active' AND deleted_at IS NULL;

-- ============================================================================
-- AUTO-UPDATE updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- ADMIN APPROVAL FUNCTIONS
-- ============================================================================

CREATE OR REPLACE FUNCTION approve_kyc(user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET
    status = 'approved',
    reviewed_at = NOW(),
    reviewed_by = auth.uid(),
    is_verified = TRUE
  WHERE id = user_id AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION reject_kyc(user_id UUID, reason TEXT, notes TEXT DEFAULT NULL)
RETURNS VOID AS $$
BEGIN
  UPDATE users
  SET
    status = 'rejected',
    reviewed_at = NOW(),
    reviewed_by = auth.uid(),
    rejection_reason = reason,
    admin_notes = notes
  WHERE id = user_id AND status = 'pending';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ADMIN VIEW for pending KYC reviews
-- ============================================================================

CREATE OR REPLACE VIEW admin_pending_kyc AS
SELECT
  id,
  username,
  email,
  phone_number,
  first_name,
  middle_name,
  last_name,
  date_of_birth,
  sex,
  region,
  province,
  city,
  barangay,
  street_address,
  zipcode,
  national_id_number,
  national_id_front_url,
  national_id_back_url,
  selfie_with_id_url,
  secondary_gov_id_type,
  secondary_gov_id_number,
  secondary_gov_id_front_url,
  secondary_gov_id_back_url,
  proof_of_address_type,
  proof_of_address_url,
  status,
  submitted_at,
  created_at
FROM users
WHERE status = 'pending' AND deleted_at IS NULL
ORDER BY submitted_at ASC;

-- ============================================================================
-- SCHEMA COMPLETE
-- Next: Run 2_rls.sql for security policies
-- ============================================================================
