-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- Simple, non-recursive, production-ready
-- ============================================================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE users FORCE ROW LEVEL SECURITY;

-- ============================================================================
-- SELECT POLICIES (Reading data)
-- ============================================================================

-- Policy 1: Users can view their own data
CREATE POLICY "users_select_own"
ON users FOR SELECT
USING (auth.uid() = id AND deleted_at IS NULL);

-- Policy 2: Public can view approved active users (for listings, bids, profiles)
CREATE POLICY "users_select_public"
ON users FOR SELECT
USING (
  status = 'approved'
  AND account_status = 'active'
  AND deleted_at IS NULL
);

-- Policy 3: Admins can view all users (using service_role key in admin dashboard)
-- No policy needed - admins use service_role which bypasses RLS

-- ============================================================================
-- INSERT POLICIES (Creating new records)
-- ============================================================================

-- Policy 4: Authenticated users can insert their own data (during KYC registration)
CREATE POLICY "users_insert_own"
ON users FOR INSERT
WITH CHECK (auth.uid() = id);

-- ============================================================================
-- UPDATE POLICIES (Modifying existing records)
-- ============================================================================

-- Policy 5: Users can update their own data (profile fields only)
CREATE POLICY "users_update_own"
ON users FOR UPDATE
USING (auth.uid() = id AND deleted_at IS NULL)
WITH CHECK (auth.uid() = id AND deleted_at IS NULL);

-- Note: Trigger below prevents users from changing protected fields
-- (status, role, is_verified, account_status)

-- Policy 6: Admins can update any user (using service_role key)
-- No policy needed - admins use service_role which bypasses RLS

-- ============================================================================
-- DELETE POLICIES (Soft delete only)
-- ============================================================================

-- Policy 7: Users can soft-delete their own account
CREATE POLICY "users_delete_own"
ON users FOR UPDATE
USING (auth.uid() = id AND deleted_at IS NULL)
WITH CHECK (auth.uid() = id AND deleted_at IS NOT NULL);

-- ============================================================================
-- TRIGGER: Prevent privilege escalation
-- Users cannot change their own: status, role, is_verified, account_status
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_privilege_escalation()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow if using service_role (admins)
  IF current_setting('request.jwt.claims', true)::json->>'role' = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Prevent users from changing protected fields
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    RAISE EXCEPTION 'Cannot change KYC status';
  END IF;

  IF NEW.role IS DISTINCT FROM OLD.role THEN
    RAISE EXCEPTION 'Cannot change user role';
  END IF;

  IF NEW.is_verified IS DISTINCT FROM OLD.is_verified THEN
    RAISE EXCEPTION 'Cannot change verification status';
  END IF;

  IF NEW.account_status IS DISTINCT FROM OLD.account_status THEN
    RAISE EXCEPTION 'Cannot change account status';
  END IF;

  IF NEW.reviewed_at IS DISTINCT FROM OLD.reviewed_at THEN
    RAISE EXCEPTION 'Cannot change review timestamp';
  END IF;

  IF NEW.reviewed_by IS DISTINCT FROM OLD.reviewed_by THEN
    RAISE EXCEPTION 'Cannot change reviewer';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER prevent_self_escalation
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION prevent_privilege_escalation();

-- ============================================================================
-- RLS POLICIES COMPLETE
-- Next: Run 3_storage.sql for file upload policies
-- ============================================================================
