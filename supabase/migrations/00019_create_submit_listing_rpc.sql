-- ============================================================================
-- AutoBid Mobile - Migration 00019: Create submit_listing_from_draft RPC
-- Converts a completed draft into a live auction listing
-- ============================================================================

-- ============================================================================
-- SECTION 1: Create RPC Function
-- ============================================================================

CREATE OR REPLACE FUNCTION submit_listing_from_draft(draft_id UUID)
RETURNS JSON AS $$
DECLARE
  v_draft RECORD;
  v_auction_id UUID;
  v_category_id UUID;
  v_status_id UUID;
  v_auction_title TEXT;
BEGIN
  -- Fetch the draft (with row-level security check)
  SELECT * INTO v_draft
  FROM listing_drafts
  WHERE id = draft_id
    AND seller_id = auth.uid()
    AND is_complete = TRUE
    AND deleted_at IS NULL;

  -- Validate draft exists and belongs to current user
  IF v_draft IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Draft not found, not complete, or access denied'
    );
  END IF;

  -- Get appropriate category_id (default to 'Vehicles' category)
  -- You may want to enhance this logic based on vehicle type
  SELECT id INTO v_category_id
  FROM auction_categories
  WHERE category_name = 'Vehicles'
  LIMIT 1;

  IF v_category_id IS NULL THEN
    -- Fallback: get any category
    SELECT id INTO v_category_id FROM auction_categories LIMIT 1;
  END IF;

  -- Get 'active' status for new auctions
  SELECT id INTO v_status_id
  FROM auction_statuses
  WHERE status_name = 'active'
  LIMIT 1;

  IF v_status_id IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction status not found. Please contact support.'
    );
  END IF;

  -- Build auction title from vehicle details
  v_auction_title := CONCAT_WS(' ',
    v_draft.year::TEXT,
    v_draft.brand,
    v_draft.model,
    v_draft.variant
  );

  -- If title is empty, use a fallback
  IF v_auction_title IS NULL OR TRIM(v_auction_title) = '' THEN
    v_auction_title := 'Vehicle Auction #' || SUBSTRING(draft_id::TEXT FROM 1 FOR 8);
  END IF;

  -- Insert into auctions table
  INSERT INTO auctions (
    seller_id,
    category_id,
    status_id,
    title,
    description,
    starting_price,
    reserve_price,
    bid_increment,
    deposit_amount,
    start_time,
    end_time
  ) VALUES (
    v_draft.seller_id,
    v_category_id,
    v_status_id,
    v_auction_title,
    COALESCE(v_draft.description, 'No description provided'),
    v_draft.starting_price,
    v_draft.reserve_price,
    GREATEST(v_draft.starting_price * 0.05, 1000), -- 5% of starting price or min 1000
    GREATEST(v_draft.starting_price * 0.10, 5000), -- 10% deposit or min 5000
    NOW(), -- Start immediately
    COALESCE(v_draft.auction_end_date, NOW() + INTERVAL '7 days') -- Default 7 days
  )
  RETURNING id INTO v_auction_id;

  -- TODO: Create supporting records in other tables:
  -- - auction_vehicles (detailed vehicle specs from draft)
  -- - auction_photos (from draft photo_urls JSONB)
  -- - auction_features (from draft features array)

  -- For now, we'll just create the basic auction
  -- Future migration can add these supporting tables

  -- Soft delete the draft (keep for audit trail)
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = draft_id;

  -- Return success with auction ID
  RETURN json_build_object(
    'success', TRUE,
    'auction_id', v_auction_id,
    'message', 'Listing submitted successfully'
  );

EXCEPTION
  WHEN foreign_key_violation THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Invalid reference data. Please contact support.'
    );
  WHEN check_violation THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Invalid data in draft. Please review your listing.'
    );
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION submit_listing_from_draft TO authenticated;

-- ============================================================================
-- SECTION 2: Future Enhancement - auction_vehicles Table (TODO)
-- ============================================================================

-- This would store detailed vehicle specifications
-- Uncomment and run in a future migration when needed:

/*
CREATE TABLE IF NOT EXISTS auction_vehicles (
  auction_id UUID PRIMARY KEY REFERENCES auctions(id) ON DELETE CASCADE,

  -- Basic Info (from draft)
  brand TEXT,
  model TEXT,
  variant TEXT,
  year INT,

  -- Mechanical
  engine_type TEXT,
  engine_displacement DOUBLE PRECISION,
  horsepower INT,
  transmission TEXT,
  fuel_type TEXT,
  drive_type TEXT,

  -- Dimensions
  mileage INT,
  seating_capacity INT,
  exterior_color TEXT,

  -- Condition
  condition TEXT,
  previous_owners INT,

  -- Documentation
  plate_number TEXT,
  registration_status TEXT,
  province TEXT,
  city_municipality TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS for auction_vehicles
ALTER TABLE auction_vehicles ENABLE ROW LEVEL SECURITY;

CREATE POLICY auction_vehicles_public_select
  ON auction_vehicles FOR SELECT
  USING (TRUE);
*/

-- ============================================================================
-- SECTION 3: Verification Query
-- ============================================================================

-- Test the function (replace with actual draft_id):
-- SELECT submit_listing_from_draft('your-draft-id-here');

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
