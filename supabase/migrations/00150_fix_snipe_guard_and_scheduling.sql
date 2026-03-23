-- ============================================================================
-- Migration 00150: Fix snipe guard (always enabled) + scheduling on approval
-- 1. Add schedule_live_mode column to auctions (was only on listing_drafts)
-- 2. Update submit_listing_from_draft to force snipe_guard_enabled = TRUE
--    and copy schedule_live_mode to auctions
-- 3. Update approve_auction to handle auto_live and auto_schedule
-- ============================================================================

-- Add schedule_live_mode to auctions table
ALTER TABLE auctions
  ADD COLUMN IF NOT EXISTS schedule_live_mode TEXT DEFAULT 'manual';

COMMENT ON COLUMN auctions.schedule_live_mode IS
  'Seller scheduling preference: auto_live, auto_schedule, or manual. Copied from listing_drafts at submission.';

-- ============================================================================
-- Update submit_listing_from_draft: force snipe_guard_enabled = TRUE
-- ============================================================================

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
  v_token_consumed BOOLEAN;
  v_calculated_end_time TIMESTAMPTZ;
  v_bid_increment NUMERIC(12, 2);
  v_min_bid_increment NUMERIC(12, 2);
  v_deposit_amount NUMERIC(12, 2);
  v_bidding_type TEXT;
  v_enable_incremental_bidding BOOLEAN;
  v_tags TEXT[];
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

  IF v_draft IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Draft not found, not complete, or access denied'
    );
  END IF;

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

  -- Consume listing token
  SELECT consume_listing_token(auth.uid(), draft_id) INTO v_token_consumed;

  IF NOT v_token_consumed THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Insufficient listing tokens. Please upgrade your subscription or purchase more tokens.'
    );
  END IF;

  -- Prepare bidding configuration values
  v_bid_increment := COALESCE(v_draft.bid_increment, 1000);
  v_min_bid_increment := COALESCE(v_draft.min_bid_increment, 1000);
  v_deposit_amount := COALESCE(v_draft.deposit_amount, 50000);
  v_bidding_type := COALESCE(v_draft.bidding_type, 'public');
  v_enable_incremental_bidding := COALESCE(v_draft.enable_incremental_bidding, TRUE);
  v_tags := v_draft.tags;

  -- Snipe guard is ALWAYS enabled — threshold/extend come from user settings
  v_snipe_guard_threshold := COALESCE(v_draft.snipe_guard_threshold_seconds, 300);
  v_snipe_guard_extend := COALESCE(v_draft.snipe_guard_extend_seconds, 300);

  IF v_snipe_guard_threshold < 0 OR v_snipe_guard_threshold > 3600 THEN
    v_snipe_guard_threshold := 300;
  END IF;

  IF v_snipe_guard_extend < 60 OR v_snipe_guard_extend > 3600 THEN
    v_snipe_guard_extend := 300;
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

  -- Insert auction with snipe guard ALWAYS enabled
  INSERT INTO auctions (
    seller_id, category_id, status_id,
    title, description,
    starting_price, reserve_price, current_price,
    bid_increment, deposit_amount,
    bidding_type, min_bid_increment, enable_incremental_bidding,
    snipe_guard_enabled, snipe_guard_threshold_seconds, snipe_guard_extend_seconds,
    start_time, end_time,
    auto_live_after_approval, schedule_live_mode
  ) VALUES (
    v_draft.seller_id, v_category_id, v_status_id,
    v_auction_title,
    COALESCE(v_draft.description, 'No description provided'),
    v_draft.starting_price, v_draft.reserve_price, v_draft.starting_price,
    v_bid_increment, v_deposit_amount,
    v_bidding_type, v_min_bid_increment, v_enable_incremental_bidding,
    TRUE, v_snipe_guard_threshold, v_snipe_guard_extend,
    NOW(),
    v_calculated_end_time,
    COALESCE(v_draft.auto_live_after_approval, FALSE),
    COALESCE(v_draft.schedule_live_mode, 'manual')
  )
  RETURNING id INTO v_auction_id;

  -- Insert vehicle details
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
    plate_number, chassis_number, orcr_status, registration_status, registration_expiry,
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
    v_draft.plate_number, v_draft.chassis_number, v_draft.orcr_status, v_draft.registration_status, v_draft.registration_expiry,
    v_draft.province, v_draft.city_municipality,
    v_draft.known_issues, v_draft.features,
    v_draft.ai_detected_brand, v_draft.ai_detected_model, v_draft.ai_detected_year,
    v_draft.ai_detected_color, v_draft.ai_detected_damage,
    v_tags,
    v_draft.ai_suggested_price_min, v_draft.ai_suggested_price_max,
    v_draft.ai_price_confidence, v_draft.ai_price_factors
  );

  -- Process and insert photos
  IF v_draft.photo_urls IS NOT NULL THEN
    FOR v_photo_category, v_photo_url IN
      SELECT key, value
      FROM jsonb_each_text(v_draft.photo_urls)
    LOOP
      v_display_order := 0;
      FOR v_photo_url IN
        SELECT jsonb_array_elements_text(v_draft.photo_urls->v_photo_category)
      LOOP
        INSERT INTO auction_photos (
          auction_id, photo_url, category, display_order
        ) VALUES (
          v_auction_id, v_photo_url, v_photo_category, v_display_order
        );
        v_display_order := v_display_order + 1;
      END LOOP;
    END LOOP;
  END IF;

  -- Mark draft as submitted
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = draft_id;

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

GRANT EXECUTE ON FUNCTION submit_listing_from_draft(UUID) TO authenticated;

-- ============================================================================
-- Update approve_auction: handle auto_live, auto_schedule, and manual
-- ============================================================================

DROP FUNCTION IF EXISTS approve_auction(UUID, UUID);

CREATE OR REPLACE FUNCTION approve_auction(
  p_auction_id UUID,
  p_admin_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_target_status_id UUID;
  v_auto_live BOOLEAN;
  v_schedule_mode TEXT;
  v_target_status TEXT;
  v_end_time TIMESTAMPTZ;
BEGIN
  -- Check admin permission
  IF NOT is_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  -- Read scheduling preferences
  SELECT auto_live_after_approval, schedule_live_mode, end_time
  INTO v_auto_live, v_schedule_mode, v_end_time
  FROM auctions WHERE id = p_auction_id;

  -- Determine target status
  IF v_auto_live = TRUE OR v_schedule_mode = 'auto_live' THEN
    v_target_status := 'live';
  ELSIF v_schedule_mode = 'auto_schedule' THEN
    v_target_status := 'scheduled';
  ELSE
    v_target_status := 'approved';
  END IF;

  SELECT id INTO v_target_status_id
  FROM auction_statuses WHERE status_name = v_target_status;

  -- Update auction based on mode
  IF v_target_status = 'live' THEN
    UPDATE auctions
    SET status_id = v_target_status_id,
        start_time = NOW(),
        end_time = CASE
          WHEN v_end_time > NOW() THEN v_end_time
          ELSE NOW() + INTERVAL '7 days'
        END,
        updated_at = NOW()
    WHERE id = p_auction_id;
  ELSE
    UPDATE auctions
    SET status_id = v_target_status_id, updated_at = NOW()
    WHERE id = p_auction_id;
  END IF;

  -- Log moderation action
  INSERT INTO auction_moderation (auction_id, moderator_id, action)
  VALUES (p_auction_id, (SELECT id FROM admin_users WHERE user_id = p_admin_id), 'approve');

  RETURN json_build_object(
    'success', TRUE,
    'auto_live', COALESCE(v_auto_live, FALSE),
    'schedule_mode', COALESCE(v_schedule_mode, 'manual'),
    'target_status', v_target_status
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
