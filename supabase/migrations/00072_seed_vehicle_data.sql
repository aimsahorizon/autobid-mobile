-- Seed Vehicle Brands
INSERT INTO vehicle_brands (id, name, logo_url) VALUES 
('11111111-1111-1111-1111-111111111111', 'Toyota', NULL),
('22222222-2222-2222-2222-222222222222', 'Honda', NULL),
('33333333-3333-3333-3333-333333333333', 'Ford', NULL),
('44444444-4444-4444-4444-444444444444', 'Mitsubishi', NULL),
('55555555-5555-5555-5555-555555555555', 'Nissan', NULL)
ON CONFLICT (name) DO NOTHING;

-- Seed Vehicle Models (Toyota)
INSERT INTO vehicle_models (brand_id, name, body_type) VALUES
('11111111-1111-1111-1111-111111111111', 'Vios', 'Sedan'),
('11111111-1111-1111-1111-111111111111', 'Fortuner', 'SUV'),
('11111111-1111-1111-1111-111111111111', 'Wigo', 'Hatchback'),
('11111111-1111-1111-1111-111111111111', 'Innova', 'MPV')
ON CONFLICT (brand_id, name) DO NOTHING;

-- Seed Vehicle Models (Honda)
INSERT INTO vehicle_models (brand_id, name, body_type) VALUES
('22222222-2222-2222-2222-222222222222', 'Civic', 'Sedan'),
('22222222-2222-2222-2222-222222222222', 'City', 'Sedan'),
('22222222-2222-2222-2222-222222222222', 'CR-V', 'SUV')
ON CONFLICT (brand_id, name) DO NOTHING;

-- Seed Vehicle Models (Ford)
INSERT INTO vehicle_models (brand_id, name, body_type) VALUES
('33333333-3333-3333-3333-333333333333', 'Ranger', 'Pickup'),
('33333333-3333-3333-3333-333333333333', 'Everest', 'SUV')
ON CONFLICT (brand_id, name) DO NOTHING;

-- Seed Vehicle Variants (Toyota Vios)
-- We need to fetch model IDs first in a real scenario, but here we can't easily. 
-- For SQL seed, we can use subqueries.

INSERT INTO vehicle_variants (model_id, name, transmission, fuel_type)
SELECT id, '1.3 E', 'Automatic', 'Gasoline' FROM vehicle_models WHERE name = 'Vios' AND brand_id = '11111111-1111-1111-1111-111111111111'
ON CONFLICT (model_id, name) DO NOTHING;

INSERT INTO vehicle_variants (model_id, name, transmission, fuel_type)
SELECT id, '1.3 J', 'Manual', 'Gasoline' FROM vehicle_models WHERE name = 'Vios' AND brand_id = '11111111-1111-1111-1111-111111111111'
ON CONFLICT (model_id, name) DO NOTHING;

INSERT INTO vehicle_variants (model_id, name, transmission, fuel_type)
SELECT id, '1.5 G', 'Automatic', 'Gasoline' FROM vehicle_models WHERE name = 'Vios' AND brand_id = '11111111-1111-1111-1111-111111111111'
ON CONFLICT (model_id, name) DO NOTHING;

-- Seed Variants (Honda Civic)
INSERT INTO vehicle_variants (model_id, name, transmission, fuel_type)
SELECT id, 'RS Turbo', 'CVT', 'Gasoline' FROM vehicle_models WHERE name = 'Civic' AND brand_id = '22222222-2222-2222-2222-222222222222'
ON CONFLICT (model_id, name) DO NOTHING;

INSERT INTO vehicle_variants (model_id, name, transmission, fuel_type)
SELECT id, 'V Turbo', 'CVT', 'Gasoline' FROM vehicle_models WHERE name = 'Civic' AND brand_id = '22222222-2222-2222-2222-222222222222'
ON CONFLICT (model_id, name) DO NOTHING;
