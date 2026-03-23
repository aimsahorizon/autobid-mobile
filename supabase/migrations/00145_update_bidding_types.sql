-- Migration 00145: Rename bidding types and add mystery type
-- public → open, private → exclusive, add mystery
--
-- Strategy: Convert auctions.visibility from enum to TEXT + CHECK constraint.
-- This avoids the PostgreSQL limitation where new enum values added via
-- ALTER TYPE ... ADD VALUE cannot be used in the same transaction.

-- ========================================================================
-- 0. Drop ALL dependencies on auctions.visibility before altering it
-- ========================================================================

-- Drop sync triggers (they cast bidding_type to auction_visibility)
DROP TRIGGER IF EXISTS trg_sync_visibility ON auctions;
DROP TRIGGER IF EXISTS trg_sync_visibility_insert ON auctions;
DROP FUNCTION IF EXISTS sync_visibility_with_bidding_type() CASCADE;
DROP FUNCTION IF EXISTS sync_visibility_on_insert() CASCADE;

-- Drop RLS policy that references visibility
DROP POLICY IF EXISTS "Auctions visibility policy" ON public.auctions;

-- Drop views that reference visibility
DROP VIEW IF EXISTS public.authorized_auctions CASCADE;
DROP VIEW IF EXISTS public.auction_browse_simple CASCADE;
DROP VIEW IF EXISTS public.auction_browse_listings CASCADE;

-- ========================================================================
-- 1. Convert auctions.visibility from enum to TEXT
-- ========================================================================

ALTER TABLE auctions ALTER COLUMN visibility DROP DEFAULT;
ALTER TABLE auctions ALTER COLUMN visibility TYPE TEXT USING visibility::TEXT;

-- Update values
UPDATE auctions SET visibility = 'open' WHERE visibility = 'public';
UPDATE auctions SET visibility = 'exclusive' WHERE visibility = 'private';

-- Set new default and CHECK constraint
ALTER TABLE auctions ALTER COLUMN visibility SET DEFAULT 'open';
ALTER TABLE auctions ADD CONSTRAINT auctions_visibility_check
  CHECK (visibility IN ('open', 'exclusive', 'mystery'));

-- Drop the old enum type (no longer needed)
DROP TYPE IF EXISTS auction_visibility;

-- ========================================================================
-- 2. Update listing_drafts.bidding_type (TEXT column with CHECK)
-- ========================================================================

ALTER TABLE listing_drafts DROP CONSTRAINT IF EXISTS listing_drafts_bidding_type_check;

UPDATE listing_drafts SET bidding_type = 'open' WHERE bidding_type = 'public';
UPDATE listing_drafts SET bidding_type = 'exclusive' WHERE bidding_type = 'private';

ALTER TABLE listing_drafts
  ADD CONSTRAINT listing_drafts_bidding_type_check
  CHECK (bidding_type IN ('open', 'exclusive', 'mystery'));

ALTER TABLE listing_drafts ALTER COLUMN bidding_type SET DEFAULT 'open';

COMMENT ON COLUMN listing_drafts.bidding_type IS
  'Bidding type: open (all can see and bid), exclusive (invite-only), mystery (sealed bids revealed at end)';

-- ========================================================================
-- 3. Update auctions.bidding_type (TEXT column with CHECK)
-- ========================================================================

ALTER TABLE auctions DROP CONSTRAINT IF EXISTS auctions_bidding_type_check;

UPDATE auctions SET bidding_type = 'open' WHERE bidding_type = 'public';
UPDATE auctions SET bidding_type = 'exclusive' WHERE bidding_type = 'private';

ALTER TABLE auctions
  ADD CONSTRAINT auctions_bidding_type_check
  CHECK (bidding_type IN ('open', 'exclusive', 'mystery'));

ALTER TABLE auctions ALTER COLUMN bidding_type SET DEFAULT 'open';

COMMENT ON COLUMN auctions.bidding_type IS
  'Bidding type: open (all can see and bid), exclusive (invite-only), mystery (sealed bids revealed at end)';

COMMENT ON COLUMN auctions.visibility IS
  'Auction visibility: open (all can see and bid), exclusive (invite-only), mystery (sealed bids revealed at end)';

-- ========================================================================
-- 4. Recreate sync triggers (now using TEXT, no enum cast needed)
-- ========================================================================

CREATE OR REPLACE FUNCTION sync_visibility_with_bidding_type()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.bidding_type IS DISTINCT FROM OLD.bidding_type THEN
    NEW.visibility := NEW.bidding_type;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_visibility
  BEFORE UPDATE ON auctions
  FOR EACH ROW
  EXECUTE FUNCTION sync_visibility_with_bidding_type();

CREATE OR REPLACE FUNCTION sync_visibility_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  NEW.visibility := NEW.bidding_type;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_visibility_insert
  BEFORE INSERT ON auctions
  FOR EACH ROW
  EXECUTE FUNCTION sync_visibility_on_insert();

-- ========================================================================
-- 5. Recreate RLS policy
-- ========================================================================

CREATE POLICY "Auctions visibility policy"
ON public.auctions
FOR SELECT
USING (
  visibility = 'open'
  OR visibility = 'mystery'
  OR seller_id = auth.uid()
  OR EXISTS (
    SELECT 1
    FROM public.auction_invites ai
    WHERE ai.auction_id = auctions.id
      AND ai.invitee_user_id = auth.uid()
      AND ai.status = 'accepted'
  )
);

-- ========================================================================
-- 6. Recreate views
-- ========================================================================

CREATE OR REPLACE VIEW public.auction_browse_listings AS
SELECT
  a.id,
  a.title,
  a.description,
  a.starting_price,
  a.current_price,
  a.reserve_price,
  a.bid_increment,
  a.min_bid_increment,
  a.enable_incremental_bidding,
  a.deposit_amount,
  a.start_time,
  a.end_time,
  a.total_bids,
  a.view_count,
  a.is_featured,
  a.seller_id,
  a.category_id,
  a.status_id,
  a.visibility,
  a.bidding_type,
  a.is_active,
  a.created_at,
  a.updated_at,
  COALESCE(
    (SELECT photo_url FROM public.auction_photos
     WHERE auction_id = a.id AND is_primary = true
     LIMIT 1),
    (SELECT photo_url FROM public.auction_photos
     WHERE auction_id = a.id
     ORDER BY display_order ASC
     LIMIT 1),
    ''
  ) AS primary_image_url,
  COALESCE((SELECT COUNT(*) FROM public.auction_watchers aw WHERE aw.auction_id = a.id), 0) AS watchers_count,
  COALESCE(av.year, 0) AS vehicle_year,
  COALESCE(av.brand, '') AS vehicle_make,
  COALESCE(av.model, '') AS vehicle_model,
  COALESCE(av.variant, '') AS vehicle_variant,
  COALESCE(u.display_name, u.full_name, 'Seller') AS seller_display_name,
  COALESCE(u.profile_image_url, '') AS seller_profile_image_url
FROM public.auctions a
LEFT JOIN public.auction_vehicles av ON a.id = av.auction_id
LEFT JOIN public.users u ON u.id = a.seller_id
WHERE
  a.status_id = (SELECT id FROM public.auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW()
  AND a.is_active = true
  AND (
    a.visibility = 'open'
    OR a.visibility = 'mystery'
    OR a.seller_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.auction_invites ai
      WHERE ai.auction_id = a.id
        AND ai.invitee_user_id = auth.uid()
        AND ai.status = 'accepted'
    )
  );

CREATE OR REPLACE VIEW public.auction_browse_simple AS
SELECT
  a.id,
  a.title,
  a.description,
  a.starting_price,
  a.current_price,
  a.reserve_price,
  a.end_time,
  a.total_bids,
  a.view_count,
  a.is_featured,
  a.seller_id,
  a.visibility,
  a.bidding_type,
  a.is_active,
  a.created_at,
  0 AS vehicle_year,
  '' AS vehicle_make,
  '' AS vehicle_model,
  '' AS vehicle_variant,
  '' AS primary_image_url,
  0 AS watchers_count,
  COALESCE(u.display_name, u.full_name, 'Seller') AS seller_display_name,
  COALESCE(u.profile_image_url, '') AS seller_profile_image_url
FROM public.auctions a
LEFT JOIN public.users u ON u.id = a.seller_id
WHERE
  a.status_id = (SELECT id FROM public.auction_statuses WHERE status_name = 'live')
  AND a.end_time > NOW()
  AND a.is_active = true
  AND (
    a.visibility = 'open'
    OR a.visibility = 'mystery'
    OR a.seller_id = auth.uid()
    OR EXISTS (
      SELECT 1
      FROM public.auction_invites ai
      WHERE ai.auction_id = a.id
        AND ai.invitee_user_id = auth.uid()
        AND ai.status = 'accepted'
    )
  );

CREATE OR REPLACE VIEW public.authorized_auctions AS
SELECT *
FROM public.auction_browse_listings;

GRANT SELECT ON public.auction_browse_listings TO authenticated, service_role;
GRANT SELECT ON public.auction_browse_simple TO anon, authenticated, service_role;
GRANT SELECT ON public.authorized_auctions TO anon, authenticated, service_role;

-- ========================================================================
-- 7. Update submit_listing_from_draft RPC
-- ========================================================================
CREATE OR REPLACE FUNCTION submit_listing_from_draft(draft_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_draft listing_drafts%ROWTYPE;
  v_auction_id UUID;
  v_vehicle_id UUID;
  v_category_id UUID;
  v_status_id UUID;
  v_auction_title TEXT;
  v_calculated_end_time TIMESTAMPTZ;
  v_bid_increment NUMERIC;
  v_deposit_amount NUMERIC;
  v_bidding_type TEXT;
  v_min_bid_increment NUMERIC;
  v_enable_incremental_bidding BOOLEAN;
  v_token_consumed BOOLEAN;
  v_tags TEXT[];
BEGIN
  -- ========================================================================
  -- VALIDATE DRAFT
  -- ========================================================================
  SELECT * INTO v_draft FROM listing_drafts WHERE id = draft_id;

  IF v_draft IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Draft not found');
  END IF;

  IF v_draft.seller_id != auth.uid() THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized: you do not own this draft');
  END IF;

  IF v_draft.status NOT IN ('draft', 'rejected') THEN
    RETURN json_build_object('success', FALSE, 'error', 'Draft already submitted or not in draft/rejected status');
  END IF;

  -- Validate required fields
  IF v_draft.brand IS NULL OR v_draft.model IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Brand and model are required');
  END IF;

  IF v_draft.starting_price IS NULL OR v_draft.starting_price <= 0 THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid starting price');
  END IF;

  IF v_draft.reserve_price IS NOT NULL AND v_draft.reserve_price < v_draft.starting_price THEN
    RETURN json_build_object('success', FALSE, 'error', 'Reserve price must be >= starting price');
  END IF;

  -- Calculate end time (default 7 days if not set)
  v_calculated_end_time := COALESCE(
    v_draft.auction_end_date,
    NOW() + INTERVAL '7 days'
  );

  -- ========================================================================
  -- USE BIDDING CONFIGURATION FROM DRAFT
  -- ========================================================================

  -- Get bidding_type from draft (default to 'open')
  v_bidding_type := COALESCE(v_draft.bidding_type, 'open');

  -- Get min_bid_increment from draft (with fallback to bid_increment, then calculated value)
  v_min_bid_increment := COALESCE(
    v_draft.min_bid_increment,
    v_draft.bid_increment,
    GREATEST(v_draft.starting_price * 0.05, 1000)
  );

  -- For backward compatibility, also set bid_increment
  v_bid_increment := v_min_bid_increment;

  IF v_bid_increment <= 0 THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Invalid bid increment: must be greater than 0'
    );
  END IF;

  -- Get deposit_amount from draft (with fallback to calculated value)
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

  -- Get enable_incremental_bidding flag (default to TRUE)
  v_enable_incremental_bidding := COALESCE(v_draft.enable_incremental_bidding, TRUE);

  -- ========================================================================
  -- MAP TAGS: Use draft.tags if available, fallback to ai_generated_tags
  -- ========================================================================
  v_tags := COALESCE(v_draft.tags, v_draft.ai_generated_tags);

  -- ========================================================================
  -- STEP 1: Consume listing token ATOMICALLY (after all validation passes)
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
  -- STEP 3: Insert auction with bidding configuration
  -- ========================================================================
  INSERT INTO auctions (
    seller_id, category_id, status_id,
    title, description,
    starting_price, reserve_price, current_price,
    bid_increment, deposit_amount,
    bidding_type, min_bid_increment, enable_incremental_bidding,
    start_time, end_time
  ) VALUES (
    v_draft.seller_id, v_category_id, v_status_id,
    v_auction_title,
    COALESCE(v_draft.description, 'No description provided'),
    v_draft.starting_price, v_draft.reserve_price, v_draft.starting_price,
    v_bid_increment, v_deposit_amount,
    v_bidding_type, v_min_bid_increment, v_enable_incremental_bidding,
    NOW(),
    v_calculated_end_time
  )
  RETURNING id INTO v_auction_id;

  -- ========================================================================
  -- STEP 4: Insert vehicle and images
  -- ========================================================================
  INSERT INTO auction_vehicles (
    auction_id,
    brand, model, variant, year,
    mileage, transmission, fuel_type, body_type,
    exterior_color, interior_color, number_of_owners,
    location, plate_number, chassis_number,
    description, condition_report,
    ai_condition_report, ai_generated_tags, tags
  ) VALUES (
    v_auction_id,
    v_draft.brand, v_draft.model, v_draft.variant, v_draft.year,
    v_draft.mileage, v_draft.transmission, v_draft.fuel_type, v_draft.body_type,
    v_draft.exterior_color, v_draft.interior_color, v_draft.number_of_owners,
    v_draft.location, v_draft.plate_number, v_draft.chassis_number,
    COALESCE(v_draft.description, 'No description provided'),
    v_draft.condition_report,
    v_draft.ai_condition_report, v_draft.ai_generated_tags, v_tags
  )
  RETURNING id INTO v_vehicle_id;

  -- Copy images from draft to auction
  INSERT INTO auction_images (auction_id, vehicle_id, image_url, display_order)
  SELECT v_auction_id, v_vehicle_id, image_url, display_order
  FROM listing_draft_images
  WHERE draft_id = draft_id
  ORDER BY display_order;

  -- ========================================================================
  -- STEP 5: Update draft status
  -- ========================================================================
  UPDATE listing_drafts
  SET status = 'submitted',
      updated_at = NOW()
  WHERE id = draft_id;

  RETURN json_build_object(
    'success', TRUE,
    'auction_id', v_auction_id,
    'vehicle_id', v_vehicle_id,
    'message', 'Listing submitted successfully for approval'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Failed to submit listing: ' || SQLERRM
    );
END;
$$;

GRANT EXECUTE ON FUNCTION submit_listing_from_draft TO authenticated;
