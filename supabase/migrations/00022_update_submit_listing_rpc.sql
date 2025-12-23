-- ============================================================================
-- AutoBid Mobile - Migration 00022: Update submit_listing_from_draft RPC
-- Now transfers ALL vehicle details and photos to auction_vehicles and auction_photos
-- ============================================================================

-- Drop existing function
DROP FUNCTION IF EXISTS submit_listing_from_draft(UUID);

-- Recreate with full data transfer
CREATE OR REPLACE FUNCTION submit_listing_from_draft(draft_id UUID)
RETURNS JSON AS $$
DECLARE
  v_draft RECORD;
  v_auction_id UUID;
  v_category_id UUID;
  v_status_id UUID;
  v_auction_title TEXT;
  v_photo_category TEXT;
  v_photo_url TEXT;
  v_display_order INT;
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

  -- Get 'Vehicles' category
  SELECT id INTO v_category_id
  FROM auction_categories
  WHERE category_name = 'Vehicles'
  LIMIT 1;

  IF v_category_id IS NULL THEN
    SELECT id INTO v_category_id FROM auction_categories LIMIT 1;
  END IF;

  -- Get 'pending_approval' status for new auctions (awaiting admin review)
  SELECT id INTO v_status_id
  FROM auction_statuses
  WHERE status_name = 'pending_approval'
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

  IF v_auction_title IS NULL OR TRIM(v_auction_title) = '' THEN
    v_auction_title := 'Vehicle Auction #' || SUBSTRING(draft_id::TEXT FROM 1 FOR 8);
  END IF;

  -- ========================================================================
  -- STEP 1: Insert into auctions table
  -- ========================================================================
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
    GREATEST(v_draft.starting_price * 0.05, 1000), -- 5% or min 1000
    GREATEST(v_draft.starting_price * 0.10, 5000), -- 10% or min 5000
    NOW(),
    COALESCE(v_draft.auction_end_date, NOW() + INTERVAL '7 days')
  )
  RETURNING id INTO v_auction_id;

  -- ========================================================================
  -- STEP 2: Insert ALL vehicle details into auction_vehicles
  -- ========================================================================
  INSERT INTO auction_vehicles (
    auction_id,
    -- Step 1: Basic Info
    brand, model, variant, year,
    -- Step 2: Mechanical
    engine_type, engine_displacement, cylinder_count, horsepower, torque,
    transmission, fuel_type, drive_type,
    -- Step 3: Dimensions
    length, width, height, wheelbase, ground_clearance,
    seating_capacity, door_count, fuel_tank_capacity, curb_weight, gross_weight,
    -- Step 4: Exterior
    exterior_color, paint_type, rim_type, rim_size, tire_size, tire_brand,
    -- Step 5: Condition
    condition, mileage, previous_owners, has_modifications, modifications_details,
    has_warranty, warranty_details, usage_type,
    -- Step 6: Documentation
    plate_number, orcr_status, registration_status, registration_expiry,
    province, city_municipality,
    -- Step 8: Details
    known_issues, features,
    -- AI Fields
    ai_detected_brand, ai_detected_model, ai_detected_year, ai_detected_color,
    ai_detected_damage, ai_generated_tags, ai_suggested_price_min, ai_suggested_price_max,
    ai_price_confidence, ai_price_factors
  ) VALUES (
    v_auction_id,
    -- Step 1
    v_draft.brand, v_draft.model, v_draft.variant, v_draft.year,
    -- Step 2
    v_draft.engine_type, v_draft.engine_displacement, v_draft.cylinder_count,
    v_draft.horsepower, v_draft.torque, v_draft.transmission, v_draft.fuel_type, v_draft.drive_type,
    -- Step 3
    v_draft.length, v_draft.width, v_draft.height, v_draft.wheelbase, v_draft.ground_clearance,
    v_draft.seating_capacity, v_draft.door_count, v_draft.fuel_tank_capacity,
    v_draft.curb_weight, v_draft.gross_weight,
    -- Step 4
    v_draft.exterior_color, v_draft.paint_type, v_draft.rim_type, v_draft.rim_size,
    v_draft.tire_size, v_draft.tire_brand,
    -- Step 5
    v_draft.condition, v_draft.mileage, v_draft.previous_owners, v_draft.has_modifications,
    v_draft.modifications_details, v_draft.has_warranty, v_draft.warranty_details, v_draft.usage_type,
    -- Step 6
    v_draft.plate_number, v_draft.orcr_status, v_draft.registration_status,
    v_draft.registration_expiry, v_draft.province, v_draft.city_municipality,
    -- Step 8
    v_draft.known_issues, v_draft.features,
    -- AI Fields
    v_draft.ai_detected_brand, v_draft.ai_detected_model, v_draft.ai_detected_year,
    v_draft.ai_detected_color, v_draft.ai_detected_damage, v_draft.ai_generated_tags,
    v_draft.ai_suggested_price_min, v_draft.ai_suggested_price_max,
    v_draft.ai_price_confidence, v_draft.ai_price_factors
  );

  -- ========================================================================
  -- STEP 3: Transfer photos from JSONB to auction_photos table
  -- ========================================================================
  -- photo_urls JSONB format: {"exterior": ["url1", "url2"], "interior": ["url3"]}
  IF v_draft.photo_urls IS NOT NULL THEN
    -- Loop through each category in the JSONB object
    FOR v_photo_category IN
      SELECT jsonb_object_keys(v_draft.photo_urls)
    LOOP
      v_display_order := 0;

      -- Loop through each URL in the category array
      FOR v_photo_url IN
        SELECT jsonb_array_elements_text(v_draft.photo_urls -> v_photo_category)
      LOOP
        INSERT INTO auction_photos (
          auction_id,
          photo_url,
          category,
          display_order,
          is_primary
        ) VALUES (
          v_auction_id,
          v_photo_url,
          v_photo_category,
          v_display_order,
          (v_photo_category = 'exterior' AND v_display_order = 0) -- First exterior photo is primary
        );

        v_display_order := v_display_order + 1;
      END LOOP;
    END LOOP;
  END IF;

  -- ========================================================================
  -- STEP 4: Soft delete the draft (keep for audit trail)
  -- ========================================================================
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = draft_id;

  -- ========================================================================
  -- STEP 5: Return success with auction ID
  -- ========================================================================
  RETURN json_build_object(
    'success', TRUE,
    'auction_id', v_auction_id,
    'message', 'Listing submitted successfully with all vehicle details and photos'
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION submit_listing_from_draft TO authenticated;

-- ============================================================================
-- Verification Query
-- ============================================================================

-- After running, test with:
-- SELECT submit_listing_from_draft('your-draft-id');

-- Verify data transfer:
-- SELECT a.title, av.brand, av.model, av.year, av.mileage,
--        COUNT(ap.id) as photo_count
-- FROM auctions a
-- JOIN auction_vehicles av ON a.id = av.auction_id
-- LEFT JOIN auction_photos ap ON a.id = ap.auction_id
-- GROUP BY a.id, a.title, av.brand, av.model, av.year, av.mileage;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
