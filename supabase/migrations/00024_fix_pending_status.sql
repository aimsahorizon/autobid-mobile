-- ============================================================================
-- AutoBid Mobile - Migration 00024: Fix Pending Status for New Submissions
-- Updates RPC to use 'pending_approval' status instead of non-existent 'active'
-- ============================================================================

-- Drop and recreate the RPC function with correct status
DROP FUNCTION IF EXISTS submit_listing_from_draft(UUID);

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
  -- STEP 1: Insert into auctions table with 'pending_approval' status
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
    GREATEST(v_draft.starting_price * 0.05, 1000),
    GREATEST(v_draft.starting_price * 0.10, 5000),
    NOW(),
    COALESCE(v_draft.auction_end_date, NOW() + INTERVAL '7 days')
  )
  RETURNING id INTO v_auction_id;

  -- ========================================================================
  -- STEP 2: Insert ALL vehicle details into auction_vehicles
  -- ========================================================================
  INSERT INTO auction_vehicles (
    auction_id,
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
    known_issues, features,
    ai_detected_brand, ai_detected_model, ai_detected_year, ai_detected_color,
    ai_detected_damage, ai_generated_tags, ai_suggested_price_min, ai_suggested_price_max,
    ai_price_confidence, ai_price_factors
  ) VALUES (
    v_auction_id,
    v_draft.brand, v_draft.model, v_draft.variant, v_draft.year,
    v_draft.engine_type, v_draft.engine_displacement, v_draft.cylinder_count,
    v_draft.horsepower, v_draft.torque, v_draft.transmission, v_draft.fuel_type, v_draft.drive_type,
    v_draft.length, v_draft.width, v_draft.height, v_draft.wheelbase, v_draft.ground_clearance,
    v_draft.seating_capacity, v_draft.door_count, v_draft.fuel_tank_capacity,
    v_draft.curb_weight, v_draft.gross_weight,
    v_draft.exterior_color, v_draft.paint_type, v_draft.rim_type, v_draft.rim_size,
    v_draft.tire_size, v_draft.tire_brand,
    v_draft.condition, v_draft.mileage, v_draft.previous_owners, v_draft.has_modifications,
    v_draft.modifications_details, v_draft.has_warranty, v_draft.warranty_details, v_draft.usage_type,
    v_draft.plate_number, v_draft.orcr_status, v_draft.registration_status,
    v_draft.registration_expiry, v_draft.province, v_draft.city_municipality,
    v_draft.known_issues, v_draft.features,
    v_draft.ai_detected_brand, v_draft.ai_detected_model, v_draft.ai_detected_year,
    v_draft.ai_detected_color, v_draft.ai_detected_damage, v_draft.ai_generated_tags,
    v_draft.ai_suggested_price_min, v_draft.ai_suggested_price_max,
    v_draft.ai_price_confidence, v_draft.ai_price_factors
  );

  -- ========================================================================
  -- STEP 3: Transfer photos from JSONB to auction_photos table
  -- ========================================================================
  IF v_draft.photo_urls IS NOT NULL THEN
    FOR v_photo_category IN
      SELECT jsonb_object_keys(v_draft.photo_urls)
    LOOP
      v_display_order := 0;
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
          (v_photo_category = 'exterior' AND v_display_order = 0)
        );
        v_display_order := v_display_order + 1;
      END LOOP;
    END LOOP;
  END IF;

  -- ========================================================================
  -- STEP 4: Soft delete the draft
  -- ========================================================================
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = draft_id;

  -- ========================================================================
  -- STEP 5: Return success
  -- ========================================================================
  RETURN json_build_object(
    'success', TRUE,
    'auction_id', v_auction_id,
    'message', 'Listing submitted successfully and is pending admin approval'
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

GRANT EXECUTE ON FUNCTION submit_listing_from_draft TO authenticated;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
