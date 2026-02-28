-- ============================================================================
-- AutoBid Mobile - Migration 00065: Add Deed of Sale to Auctions
-- Adds deed_of_sale_url column to auctions table and updates submission logic
-- ============================================================================

-- 1. Add deed_of_sale_url column to auctions table
ALTER TABLE auctions 
ADD COLUMN IF NOT EXISTS deed_of_sale_url TEXT;

-- 2. Update submit_listing_from_draft function to copy deed_of_sale_url
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
  v_global_display_order INT;
  v_is_primary BOOLEAN;
  v_token_consumed BOOLEAN;
  v_calculated_end_time TIMESTAMPTZ;
  v_bid_increment NUMERIC(12, 2);
  v_min_bid_increment NUMERIC(12, 2);
  v_deposit_amount NUMERIC(12, 2);
  v_bidding_type TEXT;
  v_enable_incremental_bidding BOOLEAN;
  v_tags TEXT[];
  v_snipe_guard_enabled BOOLEAN;
  v_snipe_guard_threshold INTEGER;
  v_snipe_guard_extend INTEGER;
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

  -- ========================================================================
  -- COMPREHENSIVE VALIDATION BEFORE TOKEN CONSUMPTION
  -- ========================================================================

  -- Validate starting_price
  IF v_draft.starting_price IS NULL OR v_draft.starting_price <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Starting price is required and must be greater than 0'
    );
  END IF;

  -- Validate reserve_price if set
  IF v_draft.reserve_price IS NOT NULL THEN
    IF v_draft.reserve_price <= 0 THEN
      RETURN json_build_object(
        'success', FALSE,
        'error', 'Reserve price must be greater than 0 if specified'
      );
    END IF;
    IF v_draft.reserve_price < v_draft.starting_price THEN
      RETURN json_build_object(
        'success', FALSE,
        'error', 'Reserve price must be greater than or equal to starting price'
      );
    END IF;
  END IF;

  -- Calculate and validate auction end time
  v_calculated_end_time := COALESCE(v_draft.auction_end_date, NOW() + INTERVAL '7 days');

  IF v_calculated_end_time <= NOW() THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction end date must be in the future. Please select a date after today.'
    );
  END IF;

  -- Validate auction duration (at least 1 day, max 90 days)
  IF v_calculated_end_time < NOW() + INTERVAL '1 day' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction must run for at least 1 day. Please select a later end date.'
    );
  END IF;

  IF v_calculated_end_time > NOW() + INTERVAL '90 days' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction cannot run for more than 90 days. Please select an earlier end date.'
    );
  END IF;

  -- ========================================================================
  -- STEP 1: CONSUME LISTING TOKEN
  -- ========================================================================
  SELECT consume_listing_token(auth.uid(), draft_id) INTO v_token_consumed;

  IF NOT v_token_consumed THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Insufficient listing tokens. Please upgrade your subscription or purchase more tokens.'
    );
  END IF;

  -- ========================================================================
  -- STEP 2: Prepare bidding configuration values
  -- ========================================================================
  v_bid_increment := COALESCE(v_draft.bid_increment, 1000);
  v_min_bid_increment := COALESCE(v_draft.min_bid_increment, 1000);
  v_deposit_amount := COALESCE(v_draft.deposit_amount, 50000);
  v_bidding_type := COALESCE(v_draft.bidding_type, 'public');
  v_enable_incremental_bidding := COALESCE(v_draft.enable_incremental_bidding, TRUE);
  v_tags := v_draft.tags;

  -- ========================================================================
  -- STEP 2.5: Prepare snipe guard configuration
  -- ========================================================================
  v_snipe_guard_enabled := COALESCE(v_draft.snipe_guard_enabled, TRUE);
  v_snipe_guard_threshold := COALESCE(v_draft.snipe_guard_threshold_seconds, 300);
  v_snipe_guard_extend := COALESCE(v_draft.snipe_guard_extend_seconds, 300);

  -- Validate snipe guard values
  IF v_snipe_guard_threshold < 0 OR v_snipe_guard_threshold > 3600 THEN
    v_snipe_guard_threshold := 300; -- Default to 5 minutes
  END IF;

  IF v_snipe_guard_extend < 60 OR v_snipe_guard_extend > 3600 THEN
    v_snipe_guard_extend := 300; -- Default to 5 minutes
  END IF;

  -- Get category and status IDs
  SELECT id INTO v_category_id
  FROM auction_categories
  WHERE category_name = 'vehicle'
  LIMIT 1;

  IF v_category_id IS NULL THEN
    SELECT id INTO v_category_id FROM auction_categories LIMIT 1;
  END IF;

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

  -- Build auction title
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
  -- STEP 3: Insert auction with all configuration
  -- ========================================================================
  INSERT INTO auctions (
    seller_id, category_id, status_id,
    title, description,
    starting_price, reserve_price, current_price,
    bid_increment, deposit_amount,
    bidding_type, min_bid_increment, enable_incremental_bidding,
    snipe_guard_enabled, snipe_guard_threshold_seconds, snipe_guard_extend_seconds,
    start_time, end_time,
    deed_of_sale_url -- New column
  ) VALUES (
    v_draft.seller_id, v_category_id, v_status_id,
    v_auction_title,
    COALESCE(v_draft.description, 'No description provided'),
    v_draft.starting_price, v_draft.reserve_price, v_draft.starting_price,
    v_bid_increment, v_deposit_amount,
    v_bidding_type, v_min_bid_increment, v_enable_incremental_bidding,
    v_snipe_guard_enabled, v_snipe_guard_threshold, v_snipe_guard_extend,
    NOW(),
    v_calculated_end_time,
    v_draft.deed_of_sale_url -- Copy deed_of_sale_url
  )
  RETURNING id INTO v_auction_id;

  -- ========================================================================
  -- STEP 4: Insert vehicle details with tags mapped to ai_generated_tags
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
    v_draft.horsepower, v_draft.torque,
    v_draft.transmission, v_draft.fuel_type, v_draft.drive_type,
    v_draft.length, v_draft.width, v_draft.height, v_draft.wheelbase, v_draft.ground_clearance,
    v_draft.seating_capacity, v_draft.door_count, v_draft.fuel_tank_capacity,
    v_draft.curb_weight, v_draft.gross_weight,
    v_draft.exterior_color, v_draft.paint_type, v_draft.rim_type, v_draft.rim_size,
    v_draft.tire_size, v_draft.tire_brand,
    v_draft.condition, v_draft.mileage, v_draft.previous_owners,
    v_draft.has_modifications, v_draft.modifications_details,
    v_draft.has_warranty, v_draft.warranty_details, v_draft.usage_type,
    v_draft.plate_number, v_draft.orcr_status, v_draft.registration_status, v_draft.registration_expiry,
    v_draft.province, v_draft.city_municipality,
    v_draft.known_issues, v_draft.features,
    v_draft.ai_detected_brand, v_draft.ai_detected_model, v_draft.ai_detected_year,
    v_draft.ai_detected_color, v_draft.ai_detected_damage,
    v_tags, -- Map draft.tags to auction_vehicles.ai_generated_tags
    v_draft.ai_suggested_price_min, v_draft.ai_suggested_price_max,
    v_draft.ai_price_confidence, v_draft.ai_price_factors
  );

  -- ========================================================================
  -- STEP 5: Process and insert photos with categories
  -- ========================================================================
  IF v_draft.photo_urls IS NOT NULL THEN
    v_global_display_order := 0; -- Initialize global counter
    
    FOR v_photo_category, v_photo_url IN
      SELECT key, value
      FROM jsonb_each_text(v_draft.photo_urls)
    LOOP
      v_display_order := 0; -- Reset category-specific counter
      
      FOR v_photo_url IN
        SELECT jsonb_array_elements_text(v_draft.photo_urls->v_photo_category)
      LOOP
        -- First photo overall is primary
        v_is_primary := (v_global_display_order = 0);
        
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
          v_is_primary
        );
        
        v_display_order := v_display_order + 1;
        v_global_display_order := v_global_display_order + 1;
      END LOOP;
    END LOOP;
  END IF;

  -- ========================================================================
  -- STEP 6: Mark draft as submitted (soft delete)
  -- ========================================================================
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = draft_id;

  -- ========================================================================
  -- SUCCESS RESPONSE
  -- ========================================================================
  RETURN json_build_object(
    'success', TRUE,
    'auction_id', v_auction_id,
    'message', 'Listing submitted successfully and is pending admin approval'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
