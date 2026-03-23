-- ============================================================================
-- AutoBid Mobile - Migration 00149: Exclusive Bidding Tier Configuration
-- Sellers can restrict exclusive auctions to silver-only, gold-only, or both.
-- Enforced at the database level when inviting users.
-- ============================================================================

-- 1) Add exclusive_tier column to listing_drafts
ALTER TABLE listing_drafts
ADD COLUMN IF NOT EXISTS exclusive_tier TEXT;

ALTER TABLE listing_drafts
DROP CONSTRAINT IF EXISTS chk_listing_drafts_exclusive_tier;

ALTER TABLE listing_drafts
ADD CONSTRAINT chk_listing_drafts_exclusive_tier
CHECK (exclusive_tier IS NULL OR exclusive_tier IN ('silver', 'gold', 'silver_gold'));

-- 2) Add exclusive_tier column to auctions
ALTER TABLE auctions
ADD COLUMN IF NOT EXISTS exclusive_tier TEXT;

ALTER TABLE auctions
DROP CONSTRAINT IF EXISTS chk_auctions_exclusive_tier;

ALTER TABLE auctions
ADD CONSTRAINT chk_auctions_exclusive_tier
CHECK (exclusive_tier IS NULL OR exclusive_tier IN ('silver', 'gold', 'silver_gold'));

-- ============================================================================
-- 3) Update submit_listing_from_draft to copy exclusive_tier from draft to auction
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
  v_exclusive_tier TEXT;
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

  -- ========================================================================
  -- COMPREHENSIVE VALIDATION BEFORE TOKEN CONSUMPTION
  -- ========================================================================

  IF v_draft.starting_price IS NULL OR v_draft.starting_price <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Starting price is required and must be greater than 0'
    );
  END IF;

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
      'error', 'Auction must run for at least 1 day'
    );
  END IF;

  IF v_calculated_end_time > NOW() + INTERVAL '90 days' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction duration cannot exceed 90 days'
    );
  END IF;

  -- ========================================================================
  -- USE BIDDING CONFIGURATION FROM DRAFT
  -- ========================================================================

  v_bidding_type := COALESCE(v_draft.bidding_type, 'open');

  v_min_bid_increment := COALESCE(
    v_draft.min_bid_increment,
    v_draft.bid_increment,
    GREATEST(v_draft.starting_price * 0.05, 1000)
  );

  v_bid_increment := v_min_bid_increment;

  IF v_bid_increment <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Invalid bid increment: must be greater than 0'
    );
  END IF;

  v_deposit_amount := COALESCE(
    v_draft.deposit_amount,
    GREATEST(v_draft.starting_price * 0.10, 5000)
  );

  IF v_deposit_amount <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Invalid deposit amount: must be greater than 0'
    );
  END IF;

  v_enable_incremental_bidding := COALESCE(v_draft.enable_incremental_bidding, TRUE);

  -- Exclusive tier: only relevant when bidding_type is 'exclusive'
  v_exclusive_tier := CASE
    WHEN v_bidding_type = 'exclusive' THEN v_draft.exclusive_tier
    ELSE NULL
  END;

  -- ========================================================================
  -- MAP TAGS
  -- ========================================================================
  v_tags := COALESCE(v_draft.tags, v_draft.ai_generated_tags);

  -- ========================================================================
  -- STEP 1: Consume listing token ATOMICALLY
  -- ========================================================================
  v_token_consumed := consume_listing_token(auth.uid(), draft_id);

  IF NOT v_token_consumed THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Insufficient listing tokens. Please purchase more tokens or upgrade your subscription.'
    );
  END IF;

  -- ========================================================================
  -- STEP 2: Get category and status
  -- ========================================================================
  SELECT id INTO v_category_id
  FROM auction_categories
  WHERE category_name = 'Vehicles'
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
  -- STEP 3: Insert auction with bidding configuration + exclusive_tier
  -- ========================================================================
  INSERT INTO auctions (
    seller_id, category_id, status_id,
    title, description,
    starting_price, reserve_price, current_price,
    bid_increment, deposit_amount,
    bidding_type, min_bid_increment, enable_incremental_bidding,
    exclusive_tier,
    start_time, end_time
  ) VALUES (
    v_draft.seller_id, v_category_id, v_status_id,
    v_auction_title,
    COALESCE(v_draft.description, 'No description provided'),
    v_draft.starting_price, v_draft.reserve_price, v_draft.starting_price,
    v_bid_increment, v_deposit_amount,
    v_bidding_type, v_min_bid_increment, v_enable_incremental_bidding,
    v_exclusive_tier,
    NOW(),
    v_calculated_end_time
  )
  RETURNING id INTO v_auction_id;

  -- ========================================================================
  -- STEP 4: Insert vehicle details
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
    v_draft.ai_detected_color, v_draft.ai_detected_damage, v_tags,
    v_draft.ai_suggested_price_min, v_draft.ai_suggested_price_max,
    v_draft.ai_price_confidence, v_draft.ai_price_factors
  );

  -- ========================================================================
  -- STEP 5: Copy photos from draft to auction
  -- ========================================================================
  IF v_draft.photo_urls IS NOT NULL THEN
    FOR v_photo_category, v_photo_url IN
      SELECT key, value
      FROM jsonb_each_text(v_draft.photo_urls)
    LOOP
      v_display_order := 0;
      FOR v_photo_url IN
        SELECT jsonb_array_elements_text(v_draft.photo_urls->v_photo_category)
      LOOP
        INSERT INTO auction_photos (auction_id, photo_url, category, display_order)
        VALUES (v_auction_id, v_photo_url, v_photo_category, v_display_order);
        v_display_order := v_display_order + 1;
      END LOOP;
    END LOOP;
  END IF;

  -- ========================================================================
  -- STEP 6: Soft-delete the draft
  -- ========================================================================
  UPDATE listing_drafts
  SET deleted_at = NOW()
  WHERE id = draft_id;

  -- ========================================================================
  -- RETURN SUCCESS with auction ID
  -- ========================================================================
  RETURN json_build_object(
    'success', TRUE,
    'auction_id', v_auction_id,
    'message', 'Listing submitted successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION submit_listing_from_draft TO authenticated;

-- ============================================================================
-- 4) Update invite_user_to_auction to validate subscription tier
-- ============================================================================

DROP FUNCTION IF EXISTS invite_user_to_auction(uuid, text, text);

CREATE OR REPLACE FUNCTION public.invite_user_to_auction(
  p_auction_id uuid,
  p_invitee_identifier text,
  p_identifier_type text -- 'username' or 'email'
) RETURNS uuid AS $$
DECLARE
  v_invitee_user_id uuid;
  v_invite_id uuid;
  v_exclusive_tier TEXT;
  v_invitee_plan TEXT;
  v_plan_tier TEXT;
BEGIN
  -- Check seller owns the auction
  IF NOT EXISTS (
    SELECT 1 FROM public.auctions a
    WHERE a.id = p_auction_id AND a.seller_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to invite for this auction';
  END IF;

  -- Resolve invitee user id by identifier
  IF p_identifier_type = 'username' THEN
    SELECT id INTO v_invitee_user_id FROM auth.users WHERE raw_user_meta_data->>'username' = p_invitee_identifier;
  ELSIF p_identifier_type = 'email' THEN
    SELECT id INTO v_invitee_user_id FROM auth.users WHERE email = p_invitee_identifier;
  ELSE
    RAISE EXCEPTION 'Invalid identifier type';
  END IF;

  -- ========================================================================
  -- Validate invitee's subscription tier matches auction's exclusive_tier
  -- ========================================================================
  SELECT exclusive_tier INTO v_exclusive_tier
  FROM public.auctions
  WHERE id = p_auction_id;

  IF v_exclusive_tier IS NOT NULL AND v_invitee_user_id IS NOT NULL THEN
    -- Get the invitee's active subscription plan
    SELECT plan INTO v_invitee_plan
    FROM public.user_subscriptions
    WHERE user_id = v_invitee_user_id
      AND is_active = TRUE
    ORDER BY created_at DESC
    LIMIT 1;

    -- Determine plan tier (silver or gold)
    v_plan_tier := CASE
      WHEN v_invitee_plan IN ('gold_monthly', 'gold_yearly') THEN 'gold'
      WHEN v_invitee_plan IN ('silver_monthly', 'silver_yearly') THEN 'silver'
      ELSE NULL
    END;

    -- Validate against auction's required tier
    IF v_plan_tier IS NULL THEN
      RAISE EXCEPTION 'Invitee does not have a qualifying subscription (silver or gold required)';
    END IF;

    IF v_exclusive_tier = 'silver' AND v_plan_tier <> 'silver' THEN
      RAISE EXCEPTION 'This auction requires a Silver subscription. Invitee has a % plan.', v_plan_tier;
    END IF;

    IF v_exclusive_tier = 'gold' AND v_plan_tier <> 'gold' THEN
      RAISE EXCEPTION 'This auction requires a Gold subscription. Invitee has a % plan.', v_plan_tier;
    END IF;

    -- 'silver_gold' allows both silver and gold — no additional check needed
  END IF;

  -- Insert invite
  INSERT INTO public.auction_invites(auction_id, inviter_id, invitee_user_id, invitee_username, invitee_email, status)
  VALUES (
    p_auction_id,
    auth.uid(),
    v_invitee_user_id,
    CASE WHEN p_identifier_type = 'username' THEN p_invitee_identifier ELSE NULL END,
    CASE WHEN p_identifier_type = 'email' THEN p_invitee_identifier ELSE NULL END,
    'pending'
  ) RETURNING id INTO v_invite_id;

  -- Notify invitee
  IF v_invitee_user_id IS NOT NULL THEN
    PERFORM public.notify_auction_invite(
      v_invitee_user_id,
      p_auction_id,
      v_invite_id,
      'auction_invite'::text
    );
  END IF;

  RETURN v_invite_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
