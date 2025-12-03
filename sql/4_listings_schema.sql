-- ============================================================================
-- AUTOBID LISTINGS SCHEMA
-- Car auction listings with drafts, submissions, and auction lifecycle
-- ============================================================================

-- ============================================================================
-- LISTING DRAFTS TABLE
-- Stores incomplete listings that users are creating (can save progress)
-- ============================================================================
CREATE TABLE listing_drafts (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Progress tracking
  current_step INTEGER NOT NULL DEFAULT 1 CHECK (current_step BETWEEN 1 AND 9),
  is_complete BOOLEAN NOT NULL DEFAULT FALSE,
  last_saved TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Step 1: Basic Information
  brand TEXT,
  model TEXT,
  variant TEXT,
  year INTEGER CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM NOW()) + 1),

  -- Step 2: Mechanical Specification
  engine_type TEXT,
  engine_displacement DECIMAL(4,2), -- in liters (e.g., 2.50)
  cylinder_count INTEGER CHECK (cylinder_count > 0),
  horsepower INTEGER CHECK (horsepower > 0),
  torque INTEGER CHECK (torque > 0),
  transmission TEXT,
  fuel_type TEXT,
  drive_type TEXT,

  -- Step 3: Dimensions & Capacity
  length DECIMAL(6,2), -- in mm
  width DECIMAL(6,2),
  height DECIMAL(6,2),
  wheelbase DECIMAL(6,2),
  ground_clearance DECIMAL(5,2),
  seating_capacity INTEGER CHECK (seating_capacity > 0),
  door_count INTEGER CHECK (door_count > 0),
  fuel_tank_capacity DECIMAL(5,2), -- in liters
  curb_weight DECIMAL(6,2), -- in kg
  gross_weight DECIMAL(6,2),

  -- Step 4: Exterior Details
  exterior_color TEXT,
  paint_type TEXT,
  rim_type TEXT,
  rim_size TEXT,
  tire_size TEXT,
  tire_brand TEXT,

  -- Step 5: Condition & History
  condition TEXT,
  mileage INTEGER CHECK (mileage >= 0),
  previous_owners INTEGER CHECK (previous_owners >= 0),
  has_modifications BOOLEAN,
  modifications_details TEXT,
  has_warranty BOOLEAN,
  warranty_details TEXT,
  usage_type TEXT,

  -- Step 6: Documentation & Location
  plate_number TEXT,
  orcr_status TEXT,
  registration_status TEXT,
  registration_expiry DATE,
  province TEXT,
  city_municipality TEXT,

  -- Step 7: Photos (stored as JSONB: {category: [url1, url2, ...]})
  photo_urls JSONB DEFAULT '{}'::jsonb,

  -- Step 8: Final Details & Pricing
  description TEXT,
  known_issues TEXT,
  features TEXT[], -- Array of feature strings
  starting_price DECIMAL(12,2) CHECK (starting_price >= 0),
  reserve_price DECIMAL(12,2) CHECK (reserve_price >= 0),
  auction_end_date TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- LISTINGS TABLE
-- Main table for submitted listings (pending, approved, active, completed)
-- ============================================================================
CREATE TABLE listings (
  -- Primary identification
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

  -- Status and lifecycle
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'approved', 'active', 'ended', 'sold', 'cancelled')),
  admin_status TEXT DEFAULT 'pending'
    CHECK (admin_status IN ('pending', 'approved', 'rejected')),
  rejection_reason TEXT,

  -- Admin review
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES users(id),

  -- User action (approved listings wait for user to make them live)
  made_live_at TIMESTAMPTZ,

  -- Car Basic Information
  brand TEXT NOT NULL,
  model TEXT NOT NULL,
  variant TEXT,
  year INTEGER NOT NULL CHECK (year >= 1900 AND year <= EXTRACT(YEAR FROM NOW()) + 1),

  -- Mechanical Specification
  engine_type TEXT,
  engine_displacement DECIMAL(4,2),
  cylinder_count INTEGER,
  horsepower INTEGER,
  torque INTEGER,
  transmission TEXT NOT NULL,
  fuel_type TEXT NOT NULL,
  drive_type TEXT,

  -- Dimensions & Capacity
  length DECIMAL(6,2),
  width DECIMAL(6,2),
  height DECIMAL(6,2),
  wheelbase DECIMAL(6,2),
  ground_clearance DECIMAL(5,2),
  seating_capacity INTEGER,
  door_count INTEGER,
  fuel_tank_capacity DECIMAL(5,2),
  curb_weight DECIMAL(6,2),
  gross_weight DECIMAL(6,2),

  -- Exterior Details
  exterior_color TEXT NOT NULL,
  paint_type TEXT,
  rim_type TEXT,
  rim_size TEXT,
  tire_size TEXT,
  tire_brand TEXT,

  -- Condition & History
  condition TEXT NOT NULL,
  mileage INTEGER NOT NULL CHECK (mileage >= 0),
  previous_owners INTEGER CHECK (previous_owners >= 0),
  has_modifications BOOLEAN DEFAULT FALSE,
  modifications_details TEXT,
  has_warranty BOOLEAN DEFAULT FALSE,
  warranty_details TEXT,
  usage_type TEXT,

  -- Documentation & Location
  plate_number TEXT NOT NULL,
  orcr_status TEXT NOT NULL,
  registration_status TEXT NOT NULL,
  registration_expiry DATE,
  province TEXT NOT NULL,
  city_municipality TEXT NOT NULL,

  -- Photos
  photo_urls JSONB NOT NULL DEFAULT '{}'::jsonb,
  cover_photo_url TEXT, -- First photo for quick access

  -- Listing Details
  description TEXT NOT NULL,
  known_issues TEXT,
  features TEXT[],

  -- Pricing & Auction
  starting_price DECIMAL(12,2) NOT NULL CHECK (starting_price >= 0),
  current_bid DECIMAL(12,2) DEFAULT 0,
  reserve_price DECIMAL(12,2) CHECK (reserve_price >= 0),

  -- Auction Timing
  auction_start_time TIMESTAMPTZ, -- When user made it live
  auction_end_time TIMESTAMPTZ, -- When auction ends

  -- Engagement metrics
  total_bids INTEGER DEFAULT 0,
  watchers_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,

  -- Winner information (for ended auctions)
  winner_id UUID REFERENCES users(id),
  sold_price DECIMAL(12,2),
  sold_at TIMESTAMPTZ,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ
);

-- ============================================================================
-- INDEXES for performance
-- ============================================================================

-- Listing drafts indexes
CREATE INDEX idx_listing_drafts_seller ON listing_drafts(seller_id)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_listing_drafts_updated ON listing_drafts(seller_id, updated_at DESC)
  WHERE deleted_at IS NULL;

-- Listings indexes
CREATE INDEX idx_listings_seller ON listings(seller_id)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_status ON listings(status)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_admin_status ON listings(admin_status)
  WHERE deleted_at IS NULL;
CREATE INDEX idx_listings_active ON listings(status, auction_end_time)
  WHERE status = 'active' AND deleted_at IS NULL;
CREATE INDEX idx_listings_pending_admin ON listings(admin_status, created_at)
  WHERE admin_status = 'pending' AND deleted_at IS NULL;
CREATE INDEX idx_listings_seller_status ON listings(seller_id, status)
  WHERE deleted_at IS NULL;

-- Full-text search index for browse functionality
CREATE INDEX idx_listings_search ON listings
  USING gin(to_tsvector('english',
    coalesce(brand, '') || ' ' ||
    coalesce(model, '') || ' ' ||
    coalesce(variant, '') || ' ' ||
    coalesce(description, '')
  )) WHERE status = 'active' AND deleted_at IS NULL;

-- ============================================================================
-- AUTO-UPDATE updated_at timestamp
-- ============================================================================

CREATE TRIGGER set_listing_drafts_updated_at
BEFORE UPDATE ON listing_drafts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER set_listings_updated_at
BEFORE UPDATE ON listings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- FUNCTIONS for listing lifecycle management
-- ============================================================================

-- Function: Submit draft as listing (moves from draft to pending)
CREATE OR REPLACE FUNCTION submit_listing_from_draft(draft_id UUID)
RETURNS UUID AS $$
DECLARE
  new_listing_id UUID;
  draft_data RECORD;
BEGIN
  -- Get draft data
  SELECT * INTO draft_data FROM listing_drafts
  WHERE id = draft_id AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Draft not found';
  END IF;

  -- Create listing from draft
  INSERT INTO listings (
    seller_id, status, admin_status,
    brand, model, variant, year,
    engine_type, engine_displacement, cylinder_count, horsepower, torque,
    transmission, fuel_type, drive_type,
    length, width, height, wheelbase, ground_clearance,
    seating_capacity, door_count, fuel_tank_capacity, curb_weight, gross_weight,
    exterior_color, paint_type, rim_type, rim_size, tire_size, tire_brand,
    condition, mileage, previous_owners, has_modifications, modifications_details,
    has_warranty, warranty_details, usage_type,
    plate_number, orcr_status, registration_status, registration_expiry,
    province, city_municipality,
    photo_urls, cover_photo_url,
    description, known_issues, features,
    starting_price, reserve_price, auction_end_time
  ) VALUES (
    draft_data.seller_id, 'pending', 'pending',
    draft_data.brand, draft_data.model, draft_data.variant, draft_data.year,
    draft_data.engine_type, draft_data.engine_displacement, draft_data.cylinder_count,
    draft_data.horsepower, draft_data.torque, draft_data.transmission,
    draft_data.fuel_type, draft_data.drive_type,
    draft_data.length, draft_data.width, draft_data.height, draft_data.wheelbase,
    draft_data.ground_clearance, draft_data.seating_capacity, draft_data.door_count,
    draft_data.fuel_tank_capacity, draft_data.curb_weight, draft_data.gross_weight,
    draft_data.exterior_color, draft_data.paint_type, draft_data.rim_type,
    draft_data.rim_size, draft_data.tire_size, draft_data.tire_brand,
    draft_data.condition, draft_data.mileage, draft_data.previous_owners,
    draft_data.has_modifications, draft_data.modifications_details,
    draft_data.has_warranty, draft_data.warranty_details, draft_data.usage_type,
    draft_data.plate_number, draft_data.orcr_status, draft_data.registration_status,
    draft_data.registration_expiry, draft_data.province, draft_data.city_municipality,
    draft_data.photo_urls,
    -- Extract first photo as cover
    (SELECT url FROM jsonb_each_text(draft_data.photo_urls)
     CROSS JOIN jsonb_array_elements_text(value::jsonb) AS url LIMIT 1),
    draft_data.description, draft_data.known_issues, draft_data.features,
    draft_data.starting_price, draft_data.reserve_price, draft_data.auction_end_date
  ) RETURNING id INTO new_listing_id;

  -- Mark draft as deleted (soft delete)
  UPDATE listing_drafts SET deleted_at = NOW() WHERE id = draft_id;

  -- Update user total listings
  UPDATE users SET total_listings = total_listings + 1
  WHERE id = draft_data.seller_id;

  RETURN new_listing_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Admin approve listing
CREATE OR REPLACE FUNCTION admin_approve_listing(listing_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE listings
  SET
    admin_status = 'approved',
    status = 'approved',
    reviewed_at = NOW(),
    reviewed_by = auth.uid()
  WHERE id = listing_id AND admin_status = 'pending' AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Listing not found or already reviewed';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Admin reject listing
CREATE OR REPLACE FUNCTION admin_reject_listing(listing_id UUID, reason TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE listings
  SET
    admin_status = 'rejected',
    status = 'cancelled',
    rejection_reason = reason,
    reviewed_at = NOW(),
    reviewed_by = auth.uid()
  WHERE id = listing_id AND admin_status = 'pending' AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Listing not found or already reviewed';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Seller makes approved listing live
CREATE OR REPLACE FUNCTION make_listing_live(listing_id UUID)
RETURNS VOID AS $$
DECLARE
  listing_data RECORD;
BEGIN
  -- Get listing data
  SELECT * INTO listing_data FROM listings
  WHERE id = listing_id
    AND seller_id = auth.uid()
    AND admin_status = 'approved'
    AND status = 'approved'
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Listing not found or not approved';
  END IF;

  -- Make listing active
  UPDATE listings
  SET
    status = 'active',
    made_live_at = NOW(),
    auction_start_time = NOW(),
    auction_end_time = listing_data.auction_end_time
  WHERE id = listing_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: End auction (runs automatically when auction_end_time is reached)
CREATE OR REPLACE FUNCTION end_auction(listing_id UUID)
RETURNS VOID AS $$
DECLARE
  listing_data RECORD;
BEGIN
  SELECT * INTO listing_data FROM listings
  WHERE id = listing_id AND status = 'active' AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- Check if auction has ended
  IF listing_data.auction_end_time > NOW() THEN
    RETURN;
  END IF;

  -- If there's a winner (has bids), mark as ended, else cancel
  IF listing_data.total_bids > 0 AND listing_data.winner_id IS NOT NULL THEN
    UPDATE listings SET status = 'ended' WHERE id = listing_id;
  ELSE
    UPDATE listings SET status = 'cancelled' WHERE id = listing_id;
  END IF;
END;
$$ LANGUAGE plpgsql;

-- Function: Complete sale
CREATE OR REPLACE FUNCTION complete_sale(listing_id UUID, final_price DECIMAL)
RETURNS VOID AS $$
BEGIN
  UPDATE listings
  SET
    status = 'sold',
    sold_price = final_price,
    sold_at = NOW()
  WHERE id = listing_id
    AND status = 'ended'
    AND seller_id = auth.uid()
    AND deleted_at IS NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Listing not found or not eligible for sale completion';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- VIEWS for easy querying
-- ============================================================================

-- View: Active auctions for browse module
CREATE OR REPLACE VIEW active_auctions AS
SELECT
  l.id,
  l.seller_id,
  u.username AS seller_username,
  u.display_name AS seller_display_name,
  l.brand,
  l.model,
  l.variant,
  l.year,
  l.cover_photo_url,
  l.starting_price,
  l.current_bid,
  l.reserve_price,
  l.total_bids,
  l.watchers_count,
  l.views_count,
  l.auction_start_time,
  l.auction_end_time,
  l.mileage,
  l.condition,
  l.exterior_color,
  l.transmission,
  l.fuel_type,
  l.province,
  l.city_municipality,
  l.created_at
FROM listings l
JOIN users u ON l.seller_id = u.id
WHERE l.status = 'active'
  AND l.deleted_at IS NULL
  AND l.auction_end_time > NOW()
ORDER BY l.auction_end_time ASC;

-- View: Seller's listings summary
CREATE OR REPLACE VIEW seller_listings_summary AS
SELECT
  l.seller_id,
  l.status,
  COUNT(*) as count,
  SUM(l.total_bids) as total_bids,
  SUM(l.watchers_count) as total_watchers,
  MAX(l.current_bid) as highest_bid
FROM listings l
WHERE l.deleted_at IS NULL
GROUP BY l.seller_id, l.status;

-- ============================================================================
-- HELPER FUNCTIONS for watchers
-- ============================================================================

-- Increment watchers count
CREATE OR REPLACE FUNCTION increment_watchers(listing_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE listings
  SET watchers_count = watchers_count + 1
  WHERE id = listing_id AND status = 'active' AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- Decrement watchers count
CREATE OR REPLACE FUNCTION decrement_watchers(listing_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE listings
  SET watchers_count = GREATEST(0, watchers_count - 1)
  WHERE id = listing_id AND status = 'active' AND deleted_at IS NULL;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- LISTINGS SCHEMA COMPLETE
-- Next: Run 5_listings_rls.sql for security policies
-- ============================================================================
