ALTER TABLE admin_users DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log DISABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view admin roles"
  ON admin_roles FOR SELECT
  TO authenticated
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users cannot insert admin roles"
  ON admin_roles FOR INSERT
  TO authenticated
  WITH CHECK (FALSE);

CREATE POLICY "Authenticated users cannot update admin roles"
  ON admin_roles FOR UPDATE
  TO authenticated
  WITH CHECK (FALSE);

CREATE POLICY "Authenticated users cannot delete admin roles"
  ON admin_roles FOR DELETE
  TO authenticated
  WITH CHECK (FALSE);