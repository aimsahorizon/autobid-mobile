-- ============================================================================
-- AutoBid Mobile - Migration 00021: Create auction_vehicles Table
-- Stores detailed vehicle specifications for auction listings
-- ============================================================================

-- ============================================================================
-- SECTION 1: Create auction_vehicles Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS auction_vehicles (
  -- Primary key links to auctions table
  auction_id UUID PRIMARY KEY REFERENCES auctions(id) ON DELETE CASCADE,

  -- Step 1: Basic Vehicle Information
  brand TEXT,
  model TEXT,
  variant TEXT,
  year INT CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM NOW()) + 1),

  -- Step 2: Mechanical Specifications
  engine_type TEXT,
  engine_displacement DOUBLE PRECISION, -- in liters
  cylinder_count INT CHECK (cylinder_count > 0),
  horsepower INT CHECK (horsepower > 0),
  torque INT CHECK (torque > 0), -- in Nm
  transmission TEXT,
  fuel_type TEXT,
  drive_type TEXT,

  -- Step 3: Dimensions & Capacity
  length DOUBLE PRECISION, -- in mm
  width DOUBLE PRECISION, -- in mm
  height DOUBLE PRECISION, -- in mm
  wheelbase DOUBLE PRECISION, -- in mm
  ground_clearance DOUBLE PRECISION, -- in mm
  seating_capacity INT CHECK (seating_capacity > 0),
  door_count INT CHECK (door_count > 0),
  fuel_tank_capacity DOUBLE PRECISION, -- in liters
  curb_weight DOUBLE PRECISION, -- in kg
  gross_weight DOUBLE PRECISION, -- in kg

  -- Step 4: Exterior Details
  exterior_color TEXT,
  paint_type TEXT,
  rim_type TEXT,
  rim_size TEXT,
  tire_size TEXT,
  tire_brand TEXT,

  -- Step 5: Condition & History
  condition TEXT,
  mileage INT CHECK (mileage >= 0), -- in km
  previous_owners INT CHECK (previous_owners >= 0),
  has_modifications BOOLEAN,
  modifications_details TEXT,
  has_warranty BOOLEAN,
  warranty_details TEXT,
  usage_type TEXT,

  -- Step 6: Documentation
  plate_number TEXT,
  orcr_status TEXT,
  registration_status TEXT,
  registration_expiry DATE,
  province TEXT,
  city_municipality TEXT,

  -- Step 8: Additional Details
  known_issues TEXT,
  features TEXT[], -- Array of feature strings

  -- AI-Generated Fields (copied from draft)
  ai_detected_brand TEXT,
  ai_detected_model TEXT,
  ai_detected_year INT,
  ai_detected_color TEXT,
  ai_detected_damage JSONB,
  ai_generated_tags TEXT[],
  ai_suggested_price_min DOUBLE PRECISION,
  ai_suggested_price_max DOUBLE PRECISION,
  ai_price_confidence DOUBLE PRECISION CHECK (ai_price_confidence BETWEEN 0 AND 1),
  ai_price_factors JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 2: Create auction_photos Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS auction_photos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,

  -- Photo details
  photo_url TEXT NOT NULL,
  category TEXT NOT NULL CHECK (category IN ('exterior', 'interior', 'engine', 'damage', 'documents', 'other')),
  display_order INT DEFAULT 0, -- For sorting photos within a category
  caption TEXT,

  -- Metadata
  is_primary BOOLEAN DEFAULT FALSE, -- One photo per auction should be primary
  width INT,
  height INT,
  file_size INT, -- in bytes

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 3: Indexes for Performance
-- ============================================================================

-- Index on auction_id for photo lookups
CREATE INDEX IF NOT EXISTS idx_auction_photos_auction_id
  ON auction_photos(auction_id);

-- Index on category and display_order for sorted retrieval
CREATE INDEX IF NOT EXISTS idx_auction_photos_category_order
  ON auction_photos(auction_id, category, display_order);

-- Index on is_primary for quick primary photo lookup
CREATE INDEX IF NOT EXISTS idx_auction_photos_primary
  ON auction_photos(auction_id, is_primary)
  WHERE is_primary = TRUE;

-- Index on vehicle brand/model for search
CREATE INDEX IF NOT EXISTS idx_auction_vehicles_brand_model
  ON auction_vehicles(brand, model);

-- Index on year for filtering
CREATE INDEX IF NOT EXISTS idx_auction_vehicles_year
  ON auction_vehicles(year);

-- Index on mileage for filtering
CREATE INDEX IF NOT EXISTS idx_auction_vehicles_mileage
  ON auction_vehicles(mileage);

-- ============================================================================
-- SECTION 4: Triggers for updated_at
-- ============================================================================

CREATE TRIGGER update_auction_vehicles_updated_at
  BEFORE UPDATE ON auction_vehicles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SECTION 5: Row Level Security (RLS)
-- ============================================================================

ALTER TABLE auction_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_photos ENABLE ROW LEVEL SECURITY;

-- Public can view all auction vehicles (listings are public)
CREATE POLICY auction_vehicles_public_select
  ON auction_vehicles FOR SELECT
  USING (TRUE);

-- Only auction owner can insert vehicle details (via RPC with SECURITY DEFINER)
CREATE POLICY auction_vehicles_owner_insert
  ON auction_vehicles FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auctions
      WHERE auctions.id = auction_id
      AND auctions.seller_id = auth.uid()
    )
  );

-- Only auction owner can update vehicle details
CREATE POLICY auction_vehicles_owner_update
  ON auction_vehicles FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM auctions
      WHERE auctions.id = auction_id
      AND auctions.seller_id = auth.uid()
    )
  );

-- Public can view all auction photos
CREATE POLICY auction_photos_public_select
  ON auction_photos FOR SELECT
  USING (TRUE);

-- Only auction owner can insert photos
CREATE POLICY auction_photos_owner_insert
  ON auction_photos FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auctions
      WHERE auctions.id = auction_id
      AND auctions.seller_id = auth.uid()
    )
  );

-- Only auction owner can update photos
CREATE POLICY auction_photos_owner_update
  ON auction_photos FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM auctions
      WHERE auctions.id = auction_id
      AND auctions.seller_id = auth.uid()
    )
  );

-- Only auction owner can delete photos
CREATE POLICY auction_photos_owner_delete
  ON auction_photos FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM auctions
      WHERE auctions.id = auction_id
      AND auctions.seller_id = auth.uid()
    )
  );

-- ============================================================================
-- SECTION 6: Verification Queries
-- ============================================================================

-- View auction with vehicle details
-- SELECT a.title, av.brand, av.model, av.year, av.mileage, av.condition
-- FROM auctions a
-- JOIN auction_vehicles av ON a.id = av.auction_id
-- LIMIT 10;

-- View auction photos by category
-- SELECT a.title, ap.category, ap.photo_url, ap.is_primary
-- FROM auctions a
-- JOIN auction_photos ap ON a.id = ap.auction_id
-- ORDER BY a.id, ap.category, ap.display_order;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
