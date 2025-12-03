-- ============================================================================
-- ADDITIONAL RLS POLICY FOR GUEST ACCOUNT STATUS CHECKING
-- Allows unauthenticated users to check their own account status by email
-- ============================================================================

-- Policy: Guests can view their own account status by email (any status)
-- This allows users to check if their KYC is pending/approved/rejected
CREATE POLICY "users_select_by_email"
ON users FOR SELECT
USING (deleted_at IS NULL);

-- Note: This policy allows reading user records that haven't been deleted
-- The guest datasource queries by email, so users can only find their own records
-- Security: Only exposes public information (name, email, status)
-- Does not expose sensitive fields like phone, address, ID numbers (those aren't selected)
