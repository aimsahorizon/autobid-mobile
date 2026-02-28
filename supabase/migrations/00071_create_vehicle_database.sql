-- Create vehicle brands table
CREATE TABLE IF NOT EXISTS vehicle_brands (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    logo_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create vehicle models table
CREATE TABLE IF NOT EXISTS vehicle_models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_id UUID NOT NULL REFERENCES vehicle_brands(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    body_type TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(brand_id, name)
);

-- Create vehicle variants table
CREATE TABLE IF NOT EXISTS vehicle_variants (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    model_id UUID NOT NULL REFERENCES vehicle_models(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    transmission TEXT,
    fuel_type TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(model_id, name)
);

-- Enable RLS
ALTER TABLE vehicle_brands ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_models ENABLE ROW LEVEL SECURITY;
ALTER TABLE vehicle_variants ENABLE ROW LEVEL SECURITY;

-- Policies: Public Read
CREATE POLICY "Public read brands" ON vehicle_brands FOR SELECT USING (true);
CREATE POLICY "Public read models" ON vehicle_models FOR SELECT USING (true);
CREATE POLICY "Public read variants" ON vehicle_variants FOR SELECT USING (true);

-- Policies: Admin Write (Assuming 'admin' role or similar mechanism, simplified here to authenticated for now or specific admin check)
-- For simplicity in this prompt, allow all authenticated users to read, but only admins to write.
-- Assuming existsing is_admin function or similar. Using public read is fine.
-- Admin write policies:
CREATE POLICY "Admin all brands" ON vehicle_brands FOR ALL USING (
  auth.uid() IN (SELECT id FROM admin_users)
);
CREATE POLICY "Admin all models" ON vehicle_models FOR ALL USING (
  auth.uid() IN (SELECT id FROM admin_users)
);
CREATE POLICY "Admin all variants" ON vehicle_variants FOR ALL USING (
  auth.uid() IN (SELECT id FROM admin_users)
);
