-- ============================================================================
-- AutoBid Mobile - Migration 00061: Add Deed of Sale Document Support
-- Adds deed_of_sale_url column to listing_drafts and auctions tables
-- ============================================================================

-- ============================================================================
-- SECTION 1: Add deed_of_sale_url to listing_drafts Table
-- ============================================================================

ALTER TABLE listing_drafts
ADD COLUMN IF NOT EXISTS deed_of_sale_url TEXT;

COMMENT ON COLUMN listing_drafts.deed_of_sale_url IS 'URL to the uploaded deed of sale document (PDF/image)';

-- ============================================================================
-- SECTION 2: Add deed_of_sale_url to auctions Table
-- ============================================================================

ALTER TABLE auctions
ADD COLUMN IF NOT EXISTS deed_of_sale_url TEXT;

COMMENT ON COLUMN auctions.deed_of_sale_url IS 'URL to the uploaded deed of sale document (PDF/image)';

-- ============================================================================
-- SECTION 3: Add deed_of_sale_url to auction_vehicles Table (for completeness)
-- ============================================================================

ALTER TABLE auction_vehicles
ADD COLUMN IF NOT EXISTS deed_of_sale_url TEXT;

COMMENT ON COLUMN auction_vehicles.deed_of_sale_url IS 'URL to the uploaded deed of sale document (PDF/image)';

-- ============================================================================
-- SECTION 4: Update submit_listing RPC to include deed_of_sale_url
-- ============================================================================

-- Drop existing function to recreate with new parameter
DROP FUNCTION IF EXISTS submit_listing(UUID);

CREATE OR REPLACE FUNCTION submit_listing(p_draft_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_draft RECORD;
  v_auction_id UUID;
  v_pending_status_id UUID;
  v_user_tokens INT;
BEGIN
  -- Get the draft
  SELECT * INTO v_draft
  FROM listing_drafts
  WHERE id = p_draft_id
    AND seller_id = auth.uid()
    AND deleted_at IS NULL;

  IF v_draft IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Draft not found or unauthorized');
  END IF;

  -- Check user has tokens
  SELECT token_balance INTO v_user_tokens
  FROM user_tokens
  WHERE user_id = auth.uid();

  IF v_user_tokens IS NULL OR v_user_tokens < 1 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Insufficient tokens');
  END IF;

  -- Get pending_approval status ID
  SELECT id INTO v_pending_status_id
  FROM auction_statuses
  WHERE status_name = 'pending_approval';

  IF v_pending_status_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Status not found');
  END IF;

  -- Generate auction ID
  v_auction_id := uuid_generate_v4();

  -- Create auction
  INSERT INTO auctions (
    id,
    seller_id,
    title,
    description,
    starting_price,
    reserve_price,
    current_price,
    status_id,
    start_time,
    end_time,
    bidding_type,
    bid_increment,
    deposit_amount,
    deed_of_sale_url,
    created_at,
    updated_at
  ) VALUES (
    v_auction_id,
    v_draft.seller_id,
    COALESCE(v_draft.brand || ' ' || v_draft.model || ' ' || v_draft.year, 'Untitled'),
    v_draft.description,
    v_draft.starting_price,
    v_draft.reserve_price,
    v_draft.starting_price,
    v_pending_status_id,
    NOW(),
    v_draft.auction_end_date,
    v_draft.bidding_type,
    v_draft.bid_increment,
    v_draft.deposit_amount,
    v_draft.deed_of_sale_url,
    NOW(),
    NOW()
  );

  -- Create auction_vehicles record
  INSERT INTO auction_vehicles (
    auction_id,
    brand,
    model,
    variant,
    year,
    engine_type,
    engine_displacement,
    cylinder_count,
    horsepower,
    torque,
    transmission,
    fuel_type,
    drive_type,
    length,
    width,
    height,
    wheelbase,
    ground_clearance,
    seating_capacity,
    door_count,
    fuel_tank_capacity,
    curb_weight,
    gross_weight,
    exterior_color,
    paint_type,
    rim_type,
    rim_size,
    tire_size,
    tire_brand,
    condition,
    mileage,
    previous_owners,
    has_modifications,
    modifications_details,
    has_warranty,
    warranty_details,
    usage_type,
    plate_number,
    orcr_status,
    registration_status,
    registration_expiry,
    province,
    city_municipality,
    known_issues,
    features,
    deed_of_sale_url
  ) VALUES (
    v_auction_id,
    v_draft.brand,
    v_draft.model,
    v_draft.variant,
    v_draft.year,
    v_draft.engine_type,
    v_draft.engine_displacement,
    v_draft.cylinder_count,
    v_draft.horsepower,
    v_draft.torque,
    v_draft.transmission,
    v_draft.fuel_type,
    v_draft.drive_type,
    v_draft.length,
    v_draft.width,
    v_draft.height,
    v_draft.wheelbase,
    v_draft.ground_clearance,
    v_draft.seating_capacity,
    v_draft.door_count,
    v_draft.fuel_tank_capacity,
    v_draft.curb_weight,
    v_draft.gross_weight,
    v_draft.exterior_color,
    v_draft.paint_type,
    v_draft.rim_type,
    v_draft.rim_size,
    v_draft.tire_size,
    v_draft.tire_brand,
    v_draft.condition,
    v_draft.mileage,
    v_draft.previous_owners,
    v_draft.has_modifications,
    v_draft.modifications_details,
    v_draft.has_warranty,
    v_draft.warranty_details,
    v_draft.usage_type,
    v_draft.plate_number,
    v_draft.orcr_status,
    v_draft.registration_status,
    v_draft.registration_expiry,
    v_draft.province,
    v_draft.city_municipality,
    v_draft.known_issues,
    v_draft.features,
    v_draft.deed_of_sale_url
  );

  -- Insert photos from JSONB
  IF v_draft.photo_urls IS NOT NULL THEN
    INSERT INTO auction_photos (auction_id, photo_url, category, is_primary)
    SELECT
      v_auction_id,
      url,
      key,
      (ROW_NUMBER() OVER (PARTITION BY key ORDER BY ordinality) = 1 AND key = 'Front View')
    FROM jsonb_each(v_draft.photo_urls) AS categories(key, value),
         jsonb_array_elements_text(value) WITH ORDINALITY AS urls(url, ordinality);
  END IF;

  -- Deduct token
  UPDATE user_tokens
  SET token_balance = token_balance - 1,
      updated_at = NOW()
  WHERE user_id = auth.uid();

  -- Soft delete the draft
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = p_draft_id;

  RETURN jsonb_build_object(
    'success', true,
    'auction_id', v_auction_id,
    'message', 'Listing submitted successfully'
  );
END;
$$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
