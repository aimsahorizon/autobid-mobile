-- Fix RLS policies for location tables to allow admins to manage them

-- 1. Regions
DROP POLICY IF EXISTS "Admin full access" ON addr_regions;
CREATE POLICY "Admin full access" ON addr_regions 
  FOR ALL 
  TO authenticated, service_role
  USING (
    auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- 2. Provinces
DROP POLICY IF EXISTS "Admin full access" ON addr_provinces;
CREATE POLICY "Admin full access" ON addr_provinces 
  FOR ALL 
  TO authenticated, service_role
  USING (
    auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- 3. Cities
DROP POLICY IF EXISTS "Admin full access" ON addr_cities;
CREATE POLICY "Admin full access" ON addr_cities 
  FOR ALL 
  TO authenticated, service_role
  USING (
    auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );

-- 4. Barangays
DROP POLICY IF EXISTS "Admin full access" ON addr_barangays;
CREATE POLICY "Admin full access" ON addr_barangays 
  FOR ALL 
  TO authenticated, service_role
  USING (
    auth.role() = 'service_role' OR EXISTS (
      SELECT 1 FROM admin_users
      WHERE admin_users.user_id = auth.uid()
      AND admin_users.is_active = TRUE
    )
  );
