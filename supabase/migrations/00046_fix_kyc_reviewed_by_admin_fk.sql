-- ============================================================================
-- AutoBid Mobile - Migration 00046: Fix KYC reviewed_by FK to admin_users
-- Aligns KYC review metadata with admin_users table and updates RPC helpers
-- to accept admin_users.id instead of auth user id.
-- ============================================================================

-- 1) Backfill reviewed_by values from user_id -> admin_users.id
UPDATE kyc_documents kd
SET reviewed_by = au.id
FROM admin_users au
WHERE kd.reviewed_by = au.user_id;

-- 2) Null out any reviewed_by values that cannot map to admin_users.id
UPDATE kyc_documents kd
SET reviewed_by = NULL
WHERE reviewed_by IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM admin_users au WHERE au.id = kd.reviewed_by
  );

-- 3) Rebuild FK to point to admin_users instead of users
ALTER TABLE kyc_documents DROP CONSTRAINT IF EXISTS kyc_documents_reviewed_by_fkey;

ALTER TABLE kyc_documents
  ADD CONSTRAINT kyc_documents_reviewed_by_fkey
  FOREIGN KEY (reviewed_by) REFERENCES admin_users(id) ON DELETE SET NULL;

-- Helpful index for admin lookups
CREATE INDEX IF NOT EXISTS idx_kyc_documents_reviewed_by
  ON kyc_documents(reviewed_by)
  WHERE reviewed_by IS NOT NULL;

-- 4) Update admin helper functions to accept admin_users.id
-- Drop old signatures that used user_uuid to avoid parameter name mismatch
DROP FUNCTION IF EXISTS is_admin(uuid);
DROP FUNCTION IF EXISTS is_super_admin(uuid);

CREATE OR REPLACE FUNCTION is_admin(admin_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users WHERE id = admin_uuid AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_super_admin(admin_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users au
    JOIN admin_roles ar ON au.role_id = ar.id
    WHERE au.id = admin_uuid AND ar.role_name = 'super_admin' AND au.is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5) Update KYC RPCs to use admin_users.id consistently
CREATE OR REPLACE FUNCTION approve_kyc(
  p_kyc_document_id UUID,
  p_admin_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_approved_status_id UUID;
  v_user_id UUID;
BEGIN
  -- Validate admin privileges using admin_users.id
  IF NOT is_super_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  SELECT id INTO v_approved_status_id FROM kyc_statuses WHERE status_name = 'approved';

  UPDATE kyc_documents
  SET
    status_id = v_approved_status_id,
    reviewed_at = NOW(),
    reviewed_by = p_admin_id,
    expires_at = NOW() + INTERVAL '1 year'
  WHERE id = p_kyc_document_id
  RETURNING user_id INTO v_user_id;

  UPDATE users SET is_verified = TRUE WHERE id = v_user_id;

  DELETE FROM kyc_review_queue WHERE kyc_document_id = p_kyc_document_id;

  RETURN json_build_object('success', TRUE, 'user_id', v_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION reject_kyc(
  p_kyc_document_id UUID,
  p_admin_id UUID,
  p_reason TEXT
)
RETURNS JSON AS $$
DECLARE
  v_rejected_status_id UUID;
  v_user_id UUID;
BEGIN
  -- Validate admin privileges using admin_users.id
  IF NOT is_super_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  SELECT id INTO v_rejected_status_id FROM kyc_statuses WHERE status_name = 'rejected';

  UPDATE kyc_documents
  SET
    status_id = v_rejected_status_id,
    reviewed_at = NOW(),
    reviewed_by = p_admin_id,
    rejection_reason = p_reason
  WHERE id = p_kyc_document_id
  RETURNING user_id INTO v_user_id;

  DELETE FROM kyc_review_queue WHERE kyc_document_id = p_kyc_document_id;

  RETURN json_build_object('success', TRUE, 'user_id', v_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
