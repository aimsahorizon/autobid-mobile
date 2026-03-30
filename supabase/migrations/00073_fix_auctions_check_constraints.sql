-- ============================================================================
-- AutoBid Mobile - Migration 00073: Fix Auctions CHECK Constraints
-- ============================================================================
-- 
-- PROBLEM:
-- Updating the end_time for approved listings causes a constraint violation 
-- on "auction_check1" (or similar auto-generated anonymous check constraint).
-- PostgreSQL anonymous constraints are hard to debug and can be flaky during updates.
--
-- SOLUTION:
-- 1. Dynamically find and drop ALL anonymous/auto-generated check constraints 
--    on the auctions table.
-- 2. Re-add them with explicit names and NULL-safe logic where appropriate.
-- 3. Ensure the end_time > start_time constraint is clearly defined and named.
-- ============================================================================

DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- STEP 1: Find and drop ALL check constraints on auctions table
    -- This includes named ones like 'valid_time_range' and anonymous ones like 'auction_check1'
    FOR constraint_record IN
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'auctions'
          AND table_schema = 'public'
          AND constraint_type = 'CHECK'
    LOOP
        -- Drop each constraint
        EXECUTE 'ALTER TABLE auctions DROP CONSTRAINT IF EXISTS ' || quote_ident(constraint_record.constraint_name);
        RAISE NOTICE 'Dropped constraint: % from auctions table', constraint_record.constraint_name;
    END LOOP;
END $$;

-- STEP 2: Re-add constraints with explicit names and robust logic
ALTER TABLE auctions
    -- Price constraints
    ADD CONSTRAINT auctions_starting_price_check 
        CHECK (starting_price > 0),
    
    ADD CONSTRAINT auctions_reserve_price_check 
        CHECK (reserve_price IS NULL OR reserve_price >= starting_price),
    
    ADD CONSTRAINT auctions_current_price_check 
        CHECK (current_price >= 0),

    -- Bidding config constraints
    ADD CONSTRAINT auctions_bid_increment_check 
        CHECK (bid_increment > 0),
    
    ADD CONSTRAINT auctions_min_bid_increment_check 
        CHECK (min_bid_increment IS NULL OR min_bid_increment > 0),
    
    ADD CONSTRAINT auctions_deposit_amount_check 
        CHECK (deposit_amount > 0),
    
    ADD CONSTRAINT auctions_bidding_type_check 
        CHECK (bidding_type IN ('public', 'private')),

    -- Timing constraints (The likely culprit)
    ADD CONSTRAINT auctions_time_range_check 
        CHECK (end_time > start_time),

    -- Snipe guard constraints
    ADD CONSTRAINT auctions_snipe_guard_threshold_check 
        CHECK (snipe_guard_threshold_seconds >= 0 AND snipe_guard_threshold_seconds <= 3600),
    
    ADD CONSTRAINT auctions_snipe_guard_extend_check 
        CHECK (snipe_guard_extend_seconds >= 60 AND snipe_guard_extend_seconds <= 3600);

-- STEP 3: Ensure update_auction_end_time function is robust
CREATE OR REPLACE FUNCTION update_auction_end_time(
  p_auction_id UUID,
  p_new_end_time TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_status_name TEXT;
BEGIN
  -- Fetch the auction and verify ownership
  SELECT a.*, ast.status_name
  INTO v_auction
  FROM auctions a
  JOIN auction_statuses ast ON a.status_id = ast.id
  WHERE a.id = p_auction_id
    AND a.seller_id = auth.uid();

  -- Validate auction exists and belongs to current user
  IF v_auction IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction not found or access denied'
    );
  END IF;

  -- Only allow updates for pending_approval or approved status
  IF v_auction.status_name NOT IN ('pending_approval', 'approved') THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Can only update end time for pending or approved auctions'
    );
  END IF;

  -- Validate new end time is in the future
  -- Use a small buffer (1 minute) to avoid race conditions with NOW()
  IF p_new_end_time <= NOW() + INTERVAL '1 minute' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'End time must be in the future'
    );
  END IF;

  -- Validate new end time is after start time
  IF p_new_end_time <= v_auction.start_time THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'End time must be after start time'
    );
  END IF;

  -- Validate auction duration (max 90 days)
  IF p_new_end_time > v_auction.start_time + INTERVAL '90 days' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction cannot run for more than 90 days'
    );
  END IF;

  -- Update the end time
  UPDATE auctions
  SET end_time = p_new_end_time,
      updated_at = NOW()
  WHERE id = p_auction_id;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Auction end time updated successfully',
    'new_end_time', p_new_end_time
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- End of Migration 00073: Fixes anonymous check constraints on auctions table and makes end time updates more robust

