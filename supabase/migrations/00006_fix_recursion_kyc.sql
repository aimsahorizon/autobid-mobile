-- ============================================================================
-- AutoBid Mobile - Fix Infinite Recursion in KYC Storage Policies
-- Issue: Storage policies querying admin_users table triggers RLS recursion
-- Solution: Use SECURITY DEFINER functions to bypass RLS checks
-- ============================================================================

-- ============================================================================
-- STEP 1: DROP PROBLEMATIC STORAGE POLICIES (in reverse order)
-- ============================================================================

-- Drop all storage policies that reference admin_users
DROP POLICY IF EXISTS "Admins can view all KYC documents" ON storage.objects;
DROP POLICY IF EXISTS "Admins can manage system assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins can upload system assets" ON storage.objects;
DROP POLICY IF EXISTS "Admins can view all payment proofs" ON storage.objects;

-- ============================================================================
-- STEP 2: CREATE SECURITY DEFINER FUNCTIONS (bypass RLS)
-- ============================================================================

-- Check if current user is super admin
-- SECURITY DEFINER: Executes as table owner, bypasses RLS
CREATE OR REPLACE FUNCTION is_current_user_super_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM admin_users au
    INNER JOIN admin_roles ar ON au.role_id = ar.id
    WHERE au.user_id = auth.uid()
    AND ar.role_name = 'super_admin'
    AND au.is_active = TRUE
  );
END;
$$;

-- Check if current user is any admin
-- SECURITY DEFINER: Executes as table owner, bypasses RLS
CREATE OR REPLACE FUNCTION is_current_user_admin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1
    FROM admin_users au
    WHERE au.user_id = auth.uid()
    AND au.is_active = TRUE
  );
END;
$$;

-- ============================================================================
-- STEP 3: RECREATE STORAGE POLICIES USING FUNCTIONS
-- ============================================================================

-- KYC Documents: Admins can view all KYC documents
CREATE POLICY "Admins can view all KYC documents"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'kyc-documents' AND
    is_current_user_super_admin()
  );

-- Payment Proofs: Admins can view all payment proofs
CREATE POLICY "Admins can view all payment proofs"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'payment-proofs' AND
    is_current_user_super_admin()
  );

-- System Assets: Admins can upload system assets
CREATE POLICY "Admins can upload system assets"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'system-assets' AND
    is_current_user_super_admin()
  );

-- System Assets: Admins can manage system assets (UPDATE/DELETE)
CREATE POLICY "Admins can manage system assets"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'system-assets' AND
    is_current_user_super_admin()
  );

-- ============================================================================
-- STEP 4: GRANT EXECUTE PERMISSIONS ON FUNCTIONS
-- ============================================================================

GRANT EXECUTE ON FUNCTION is_current_user_super_admin() TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION is_current_user_admin() TO anon, authenticated, service_role;

-- ============================================================================
-- STEP 5: OPTIMIZE ADMIN_USERS TABLE QUERIES
-- ============================================================================

-- Create index for faster admin lookups (if not exists)
CREATE INDEX IF NOT EXISTS idx_admin_users_user_id_active
  ON admin_users(user_id, is_active);

CREATE INDEX IF NOT EXISTS idx_admin_roles_role_name
  ON admin_roles(role_name);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- After deploying this fix, verify the functions work:
-- SELECT is_current_user_super_admin();  -- Should return FALSE if not admin
-- SELECT is_current_user_admin();        -- Should return FALSE if not admin

-- Verify policies were recreated:
-- SELECT schemaname, tablename, policyname 
-- FROM pg_policies 
-- WHERE schemaname = 'storage' AND tablename = 'objects'
-- ORDER BY tablename, policyname;

-- ============================================================================
-- END OF FIX
-- ============================================================================
