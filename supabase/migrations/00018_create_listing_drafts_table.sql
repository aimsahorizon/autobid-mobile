-- ============================================================================
-- AutoBid Mobile - Migration 00018: Create Listing Drafts Table
-- Supports 9-step listing creation workflow with auto-save
-- ============================================================================

-- ============================================================================
-- SECTION 1: Create listing_drafts Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS listing_drafts (
  -- Primary key
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),

  -- Core draft metadata
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  current_step INT NOT NULL DEFAULT 1 CHECK (current_step BETWEEN 1 AND 9),
  is_complete BOOLEAN DEFAULT FALSE,
  last_saved TIMESTAMPTZ DEFAULT NOW(),

  -- Step 1: Basic Vehicle Information
  brand TEXT,
  model TEXT,
  variant TEXT,
  year INT CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM NOW()) + 1),

  -- Step 2: Mechanical Specifications
  engine_type TEXT, -- e.g., 'inline', 'v-type', 'rotary', 'electric'
  engine_displacement DOUBLE PRECISION, -- in liters (e.g., 2.0)
  cylinder_count INT CHECK (cylinder_count > 0),
  horsepower INT CHECK (horsepower > 0),
  torque INT CHECK (torque > 0), -- in Nm
  transmission TEXT, -- e.g., 'manual', 'automatic', 'cvt', 'dct'
  fuel_type TEXT, -- e.g., 'gasoline', 'diesel', 'electric', 'hybrid'
  drive_type TEXT, -- e.g., 'fwd', 'rwd', 'awd', '4wd'

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
  paint_type TEXT, -- e.g., 'metallic', 'solid', 'matte', 'pearlescent'
  rim_type TEXT, -- e.g., 'alloy', 'steel', 'chrome'
  rim_size TEXT, -- e.g., '17 inches'
  tire_size TEXT, -- e.g., '215/55 R17'
  tire_brand TEXT,

  -- Step 5: Condition & History
  condition TEXT, -- e.g., 'excellent', 'good', 'fair', 'needs_work'
  mileage INT CHECK (mileage >= 0), -- in km
  previous_owners INT CHECK (previous_owners >= 0),
  has_modifications BOOLEAN,
  modifications_details TEXT,
  has_warranty BOOLEAN,
  warranty_details TEXT,
  usage_type TEXT, -- e.g., 'personal', 'commercial', 'rental'

  -- Step 6: Documentation
  plate_number TEXT,
  orcr_status TEXT, -- e.g., 'original', 'photocopy', 'pending'
  registration_status TEXT, -- e.g., 'current', 'expired', 'renewed'
  registration_expiry DATE,
  province TEXT,
  city_municipality TEXT,

  -- Step 7: Photos (JSONB structure for categorized photos)
  -- Format: {"exterior": ["url1", "url2"], "interior": ["url3"], "engine": ["url4"]}
  photo_urls JSONB,

  -- Step 8: Final Details & Description
  description TEXT,
  known_issues TEXT,
  features TEXT[], -- Array of feature strings

  -- Step 9: Pricing & Auction Settings
  starting_price DOUBLE PRECISION CHECK (starting_price > 0),
  reserve_price DOUBLE PRECISION CHECK (reserve_price >= starting_price),
  auction_end_date TIMESTAMPTZ,

  -- AI-Generated Fields
  ai_detected_brand TEXT, -- AI-extracted from image
  ai_detected_model TEXT, -- AI-extracted from image
  ai_detected_year INT, -- AI-extracted from image
  ai_detected_color TEXT, -- AI-extracted from image
  ai_detected_damage JSONB, -- AI-detected damages: [{"type": "dent", "location": "front_bumper", "severity": "minor"}]
  ai_generated_tags TEXT[], -- AI-generated tags: ["sedan", "luxury", "fuel_efficient"]
  ai_suggested_price_min DOUBLE PRECISION, -- AI price recommendation (low)
  ai_suggested_price_max DOUBLE PRECISION, -- AI price recommendation (high)
  ai_price_confidence DOUBLE PRECISION CHECK (ai_price_confidence BETWEEN 0 AND 1), -- 0.0 to 1.0
  ai_price_factors JSONB, -- AI pricing breakdown: {"base_value": 500000, "mileage_adjustment": -50000, "condition_adjustment": 30000}
  ai_processing_status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
  ai_processed_at TIMESTAMPTZ, -- When AI analysis completed

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ -- Soft delete support
);

-- ============================================================================
-- SECTION 2: Indexes for Performance
-- ============================================================================

-- Index on seller_id for seller's draft list queries
CREATE INDEX IF NOT EXISTS idx_listing_drafts_seller_id
  ON listing_drafts(seller_id)
  WHERE deleted_at IS NULL;

-- Index on current_step for filtering incomplete drafts
CREATE INDEX IF NOT EXISTS idx_listing_drafts_current_step
  ON listing_drafts(current_step)
  WHERE deleted_at IS NULL;

-- Index on last_saved for sorting recent drafts
CREATE INDEX IF NOT EXISTS idx_listing_drafts_last_saved
  ON listing_drafts(last_saved DESC)
  WHERE deleted_at IS NULL;

-- Index on is_complete for filtering ready-to-submit drafts
CREATE INDEX IF NOT EXISTS idx_listing_drafts_is_complete
  ON listing_drafts(is_complete)
  WHERE deleted_at IS NULL;

-- Index on ai_processing_status for AI job queue
CREATE INDEX IF NOT EXISTS idx_listing_drafts_ai_status
  ON listing_drafts(ai_processing_status, created_at)
  WHERE ai_processing_status IN ('pending', 'processing');

-- ============================================================================
-- SECTION 3: Trigger for updated_at Auto-Update
-- ============================================================================

-- Reuse existing update_updated_at_column function from migration 00001
CREATE TRIGGER trigger_listing_drafts_updated_at
  BEFORE UPDATE ON listing_drafts
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- SECTION 4: Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE listing_drafts ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own drafts
CREATE POLICY listing_drafts_select_own
  ON listing_drafts
  FOR SELECT
  USING (
    seller_id = auth.uid()
    AND deleted_at IS NULL
  );

-- Policy: Users can insert their own drafts
CREATE POLICY listing_drafts_insert_own
  ON listing_drafts
  FOR INSERT
  WITH CHECK (
    seller_id = auth.uid()
  );

-- Policy: Users can update their own drafts
CREATE POLICY listing_drafts_update_own
  ON listing_drafts
  FOR UPDATE
  USING (
    seller_id = auth.uid()
    AND deleted_at IS NULL
  );

-- Policy: Users can soft-delete their own drafts
CREATE POLICY listing_drafts_delete_own
  ON listing_drafts
  FOR UPDATE
  USING (
    seller_id = auth.uid()
  )
  WITH CHECK (
    deleted_at IS NOT NULL
  );

-- Policy: Admins can view all drafts
CREATE POLICY listing_drafts_admin_select_all
  ON listing_drafts
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role_id IN (
        SELECT id FROM user_roles WHERE role_name = 'superadmin'
      )
    )
  );

-- ============================================================================
-- SECTION 5: Verification Queries
-- ============================================================================

-- Verify table structure
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'listing_drafts'
-- ORDER BY ordinal_position;

-- Verify indexes
-- SELECT indexname, indexdef
-- FROM pg_indexes
-- WHERE tablename = 'listing_drafts';

-- Verify RLS policies
-- SELECT policyname, cmd, qual, with_check
-- FROM pg_policies
-- WHERE tablename = 'listing_drafts';

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
