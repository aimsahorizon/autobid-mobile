-- Fix infinite recursion in admin_users RLS policy
-- This is critical for all other admin RLS checks (which rely on querying admin_users) to work correctly.

-- Drop the potentially recursive policy defined in 00003_rls_policies.sql
DROP POLICY IF EXISTS "Admins can view admin users" ON admin_users;

-- 1. Allow any authenticated user to read their OWN admin record.
-- This breaks the recursion: "Select * from admin_users where user_id = my_id" now passes 
-- without needing to query admin_users again to check permission.
CREATE POLICY "Users can view own admin status"
  ON admin_users FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- 2. Allow super admins to view ALL admin users.
-- This query is now safe because the inner check "Am I a super admin?" 
-- relies on reading *my own* record (allowed by policy #1) and joining admin_roles.
CREATE POLICY "Super admins can view all admin users"
  ON admin_users FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );
