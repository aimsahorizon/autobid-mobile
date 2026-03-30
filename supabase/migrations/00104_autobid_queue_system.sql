-- Migration: 00104_autobid_queue_system.sql
-- Date: 2026-02-20
-- Description: Convert autobidding from synchronous to async queue-based system
--
--   PROBLEMS FIXED:
--   1. App lag: place_bid() blocked until ALL auto-bids resolved synchronously
--   2. No start on activate: auto-bid only triggered when someone ELSE bids
--
--   NEW SYSTEM:
--   - place_bid() returns immediately, enqueues auto-bid processing
--   - pg_cron processes ONE auto-bid per auction every 5 seconds
--   - Round-robin FIFO: each autobidder gets a turn per cycle (A→B→C→A→B→C)
--   - Manual bids always processed immediately (auto-bids react on next tick)
--   - Activating auto-bid immediately enqueues if user is outbid
--   - Snipe guard applied to auto-bids too

-- ============================================================================
-- 1. Add last_bid_at to auto_bid_settings for round-robin ordering
-- ============================================================================
ALTER TABLE auto_bid_settings
  ADD COLUMN IF NOT EXISTS last_bid_at TIMESTAMPTZ;

COMMENT ON COLUMN auto_bid_settings.last_bid_at IS
  'Timestamp of last auto-bid placed. Used for round-robin queue ordering.';

-- ============================================================================
-- 2. Create auto_bid_queue table (one entry per auction needing processing)
-- ============================================================================
CREATE TABLE IF NOT EXISTS auto_bid_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL UNIQUE REFERENCES auctions(id) ON DELETE CASCADE,
  next_process_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_auto_bid_queue_pending
  ON auto_bid_queue(next_process_at);

ALTER TABLE auto_bid_queue ENABLE ROW LEVEL SECURITY;
-- No RLS policies = no direct access. Only SECURITY DEFINER functions can touch it.

COMMENT ON TABLE auto_bid_queue IS
  'Queue for async auto-bid processing. One row per auction needing auto-bid resolution. Processed by pg_cron every 5 seconds.';

-- ============================================================================
-- 3. Enqueue helper: add an auction to the processing queue
-- ============================================================================
CREATE OR REPLACE FUNCTION enqueue_auto_bid_processing(p_auction_id UUID)
RETURNS VOID AS $$
DECLARE
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_current_bidder_id UUID;
BEGIN
  -- Get current auction state
  SELECT current_price, bid_increment
  INTO v_current_price, v_min_increment
  FROM auctions WHERE id = p_auction_id;

  IF v_current_price IS NULL THEN RETURN; END IF;

  -- Get current leading bidder
  SELECT bidder_id INTO v_current_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC LIMIT 1;

  -- Only enqueue if eligible auto-bidders exist who can actually bid
  IF EXISTS (
    SELECT 1 FROM auto_bid_settings
    WHERE auction_id = p_auction_id
      AND is_active = TRUE
      AND user_id != COALESCE(v_current_bidder_id, '00000000-0000-0000-0000-000000000000'::uuid)
      AND max_bid_amount >= v_current_price + v_min_increment
  ) THEN
    INSERT INTO auto_bid_queue (auction_id, next_process_at)
    VALUES (p_auction_id, NOW())
    ON CONFLICT (auction_id)
    DO UPDATE SET next_process_at = LEAST(auto_bid_queue.next_process_at, EXCLUDED.next_process_at);
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. Process ONE auto-bid for an auction (round-robin FIFO)
-- ============================================================================
CREATE OR REPLACE FUNCTION process_one_auto_bid(p_auction_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_end_time TIMESTAMPTZ;
  v_status_id UUID;
  v_auction_status TEXT;
  v_current_bidder_id UUID;
  v_autobidder RECORD;
  v_next_bid NUMERIC;
  v_effective_increment NUMERIC;
  v_active_bid_status_id UUID;
  v_auction_title TEXT;
  v_snipe_extension INTERVAL := '5 minutes';
BEGIN
  -- Advisory lock per auction to prevent concurrent processing
  IF NOT pg_try_advisory_xact_lock(hashtext(p_auction_id::text)) THEN
    RETURN jsonb_build_object('status', 'locked', 'has_more', true);
  END IF;

  -- Lock and read auction state
  SELECT current_price, bid_increment, end_time, status_id
  INTO v_current_price, v_min_increment, v_end_time, v_status_id
  FROM auctions WHERE id = p_auction_id
  FOR UPDATE;

  IF v_current_price IS NULL THEN
    RETURN jsonb_build_object('status', 'auction_not_found', 'has_more', false);
  END IF;

  -- Verify auction is still live
  SELECT status_name INTO v_auction_status FROM auction_statuses WHERE id = v_status_id;
  IF v_auction_status NOT IN ('live', 'active') OR NOW() > v_end_time THEN
    RETURN jsonb_build_object('status', 'auction_ended', 'has_more', false);
  END IF;

  -- Get active bid status ID
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;
  IF v_active_bid_status_id IS NULL THEN
    RETURN jsonb_build_object('status', 'config_error', 'has_more', false);
  END IF;

  -- Get auction title for notifications
  SELECT COALESCE(title, 'this auction') INTO v_auction_title
  FROM auctions WHERE id = p_auction_id;

  -- Get current leading bidder
  SELECT bidder_id INTO v_current_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC LIMIT 1;

  -- ====================================================================
  -- ROUND-ROBIN FIFO SELECTION
  -- 
  -- Order by last_bid_at ASC NULLS FIRST:
  --   - Users who haven't bid yet go first (NULL = never bid)
  --   - Among those who have bid, oldest bid goes first
  --   - created_at tiebreak for users who joined at the same time
  --
  -- This creates natural round-robin: A→B→C→A→B→C
  -- New autobidders (NULL last_bid_at) get immediate turns
  -- ====================================================================
  SELECT user_id, max_bid_amount,
         COALESCE(bid_increment, v_min_increment) AS effective_increment
  INTO v_autobidder
  FROM auto_bid_settings
  WHERE auction_id = p_auction_id
    AND is_active = TRUE
    AND user_id != COALESCE(v_current_bidder_id, '00000000-0000-0000-0000-000000000000'::uuid)
    AND max_bid_amount > v_current_price
  ORDER BY last_bid_at ASC NULLS FIRST, created_at ASC
  LIMIT 1;

  -- No eligible autobidder found
  IF v_autobidder IS NULL THEN
    RETURN jsonb_build_object('status', 'no_autobidders', 'has_more', false);
  END IF;

  -- Calculate bid amount using autobidder's custom increment (or auction min)
  v_effective_increment := GREATEST(v_autobidder.effective_increment, v_min_increment);
  v_next_bid := v_current_price + v_effective_increment;

  -- Handle case where increment exceeds remaining budget
  IF v_next_bid > v_autobidder.max_bid_amount THEN
    IF v_autobidder.max_bid_amount >= v_current_price + v_min_increment THEN
      -- Can't afford custom increment but CAN afford auction minimum → bid their max
      v_next_bid := v_autobidder.max_bid_amount;
    ELSE
      -- Can't afford even minimum increment → deactivate and notify
      UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
      WHERE auction_id = p_auction_id AND user_id = v_autobidder.user_id;

      PERFORM create_bid_notification(
        v_autobidder.user_id, 'outbid', 'Auto-Bid Max Reached',
        format('Your auto-bid maximum of ₱%s has been reached on %s. Current bid is ₱%s. Increase your maximum to stay in the auction.',
          to_char(v_autobidder.max_bid_amount, 'FM999,999,999'),
          v_auction_title,
          to_char(v_current_price, 'FM999,999,999')),
        jsonb_build_object(
          'auction_id', p_auction_id,
          'max_bid_amount', v_autobidder.max_bid_amount,
          'current_price', v_current_price,
          'action', 'increase_max_bid'
        )
      );

      -- Check if OTHER autobidders can still bid
      RETURN jsonb_build_object('status', 'max_reached_deactivated', 'has_more', EXISTS(
        SELECT 1 FROM auto_bid_settings
        WHERE auction_id = p_auction_id AND is_active = TRUE
          AND user_id != COALESCE(v_current_bidder_id, '00000000-0000-0000-0000-000000000000'::uuid)
          AND max_bid_amount > v_current_price
      ));
    END IF;
  END IF;

  -- ====================================================================
  -- PLACE THE AUTO-BID
  -- ====================================================================
  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
  VALUES (p_auction_id, v_autobidder.user_id, v_next_bid, TRUE, v_active_bid_status_id);

  -- Update auction: price, total_bids, snipe guard
  UPDATE auctions SET
    current_price = v_next_bid,
    total_bids = COALESCE(total_bids, 0) + 1,
    end_time = CASE
      WHEN v_end_time - NOW() < v_snipe_extension THEN NOW() + v_snipe_extension
      ELSE end_time
    END
  WHERE id = p_auction_id;

  -- Update round-robin tracking (marks this user as "just bid")
  UPDATE auto_bid_settings SET last_bid_at = NOW()
  WHERE auction_id = p_auction_id AND user_id = v_autobidder.user_id;

  -- Notify previous leader they've been outbid
  IF v_current_bidder_id IS NOT NULL AND v_current_bidder_id != v_autobidder.user_id THEN
    PERFORM create_bid_notification(
      v_current_bidder_id, 'outbid', 'You''ve Been Outbid!',
      format('Someone placed a higher bid of ₱%s on %s.',
        to_char(v_next_bid, 'FM999,999,999'), v_auction_title),
      jsonb_build_object(
        'auction_id', p_auction_id,
        'outbid_amount', v_next_bid,
        'action', 'place_bid'
      )
    );
  END IF;

  -- Deactivate if autobidder hit their max (but they're winning, so no notification yet)
  IF v_next_bid >= v_autobidder.max_bid_amount THEN
    UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
    WHERE auction_id = p_auction_id AND user_id = v_autobidder.user_id;
  END IF;

  -- Check if more auto-bids are pending (determines next queue tick)
  RETURN jsonb_build_object('status', 'bid_placed', 'has_more', EXISTS(
    SELECT 1 FROM auto_bid_settings
    WHERE auction_id = p_auction_id AND is_active = TRUE
      AND user_id != v_autobidder.user_id  -- new leader is excluded
      AND max_bid_amount > v_next_bid
  ));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. Queue processor: called by pg_cron every 5 seconds
-- ============================================================================
CREATE OR REPLACE FUNCTION process_auto_bid_queue()
RETURNS VOID AS $$
DECLARE
  v_queue RECORD;
  v_result JSONB;
BEGIN
  -- Prevent overlapping cron runs
  IF NOT pg_try_advisory_xact_lock(20260220) THEN
    RETURN;
  END IF;

  -- Process all due queue entries (one bid per auction per tick)
  FOR v_queue IN
    SELECT id, auction_id FROM auto_bid_queue
    WHERE next_process_at <= NOW()
    ORDER BY next_process_at ASC
    FOR UPDATE SKIP LOCKED
  LOOP
    -- Process one auto-bid for this auction
    v_result := process_one_auto_bid(v_queue.auction_id);

    IF v_result IS NOT NULL AND (v_result->>'has_more')::boolean THEN
      -- More auto-bids pending → schedule next tick (5 seconds)
      UPDATE auto_bid_queue
      SET next_process_at = NOW() + interval '5 seconds'
      WHERE id = v_queue.id;
    ELSE
      -- No more auto-bids needed → remove from queue
      DELETE FROM auto_bid_queue WHERE id = v_queue.id;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. Updated place_bid: enqueue instead of synchronous process_auto_bids
-- ============================================================================
CREATE OR REPLACE FUNCTION place_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_amount NUMERIC,
  p_is_auto_bid BOOLEAN DEFAULT FALSE
) RETURNS JSONB AS $$
DECLARE
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_end_time TIMESTAMPTZ;
  v_status_id UUID;
  v_auction_status TEXT;
  v_bid_id UUID;
  v_snipe_extension INTERVAL := '5 minutes';
  v_active_bid_status_id UUID;
  v_previous_bidder_id UUID;
  v_auction_title TEXT;
BEGIN
  -- 1. Get the 'active' status ID for the new bid
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;

  IF v_active_bid_status_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'System Error: Active bid status not found');
  END IF;

  -- 2. Lock the auction row for update to prevent race conditions
  SELECT current_price, bid_increment, end_time, status_id
  INTO v_current_price, v_min_increment, v_end_time, v_status_id
  FROM auctions
  WHERE id = p_auction_id
  FOR UPDATE;

  -- 3. Get auction status name
  SELECT status_name INTO v_auction_status
  FROM auction_statuses
  WHERE id = v_status_id;

  -- 4. Validation: Auction must be live
  IF v_auction_status != 'live' AND v_auction_status != 'active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction is not live');
  END IF;

  -- 5. Validation: Auction must not be ended
  IF NOW() > v_end_time THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction has ended');
  END IF;

  -- 6. Validation: Bid amount
  IF p_amount < (v_current_price + v_min_increment) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Bid amount too low. Minimum required: ' || (v_current_price + v_min_increment));
  END IF;

  -- 6b. Find the current leading bidder (to notify them of being outbid)
  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids
  WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC
  LIMIT 1;

  -- 7. Insert Bid
  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
  VALUES (p_auction_id, p_bidder_id, p_amount, p_is_auto_bid, v_active_bid_status_id)
  RETURNING id INTO v_bid_id;

  -- 8. Update Auction (Current Price, Total Bids, Snipe Guard)
  UPDATE auctions
  SET
    current_price = p_amount,
    total_bids = COALESCE(total_bids, 0) + 1,
    end_time = CASE
      WHEN v_end_time - NOW() < v_snipe_extension THEN NOW() + v_snipe_extension
      ELSE end_time
    END
  WHERE id = p_auction_id;

  -- 8b. Notify previous leading bidder they've been outbid (only if different user)
  IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != p_bidder_id THEN
    SELECT COALESCE(
      (SELECT title FROM auctions WHERE id = p_auction_id),
      'this auction'
    ) INTO v_auction_title;

    PERFORM create_bid_notification(
      v_previous_bidder_id,
      'outbid',
      'You''ve Been Outbid!',
      format('Someone placed a higher bid of ₱%s on %s.',
        to_char(p_amount, 'FM999,999,999'),
        v_auction_title
      ),
      jsonb_build_object(
        'auction_id', p_auction_id,
        'outbid_amount', p_amount,
        'action', 'place_bid'
      )
    );
  END IF;

  -- 9. Enqueue auto-bid processing (async via pg_cron queue)
  --    Replaces old synchronous PERFORM process_auto_bids(...)
  PERFORM enqueue_auto_bid_processing(p_auction_id);

  RETURN jsonb_build_object('success', true, 'bid_id', v_bid_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Updated upsert_auto_bid_settings: enqueue when activating if outbid
-- ============================================================================
CREATE OR REPLACE FUNCTION upsert_auto_bid_settings(
  p_auction_id UUID,
  p_user_id UUID,
  p_max_bid_amount NUMERIC,
  p_bid_increment NUMERIC DEFAULT NULL,
  p_is_active BOOLEAN DEFAULT TRUE
) RETURNS JSONB AS $$
DECLARE
  v_min_increment NUMERIC;
  v_current_price NUMERIC;
  v_settings_id UUID;
  v_current_bidder_id UUID;
BEGIN
  -- Validate auction exists and get min increment
  SELECT bid_increment, current_price
  INTO v_min_increment, v_current_price
  FROM auctions WHERE id = p_auction_id;

  IF v_min_increment IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction not found');
  END IF;

  -- Validate max bid is reasonable
  IF p_max_bid_amount <= v_current_price THEN
    RETURN jsonb_build_object('success', false, 'error', 'Maximum bid must be higher than current price');
  END IF;

  -- Validate increment if provided
  IF p_bid_increment IS NOT NULL AND p_bid_increment < v_min_increment THEN
    RETURN jsonb_build_object('success', false, 'error',
      'Bid increment must be at least ' || v_min_increment);
  END IF;

  -- Upsert settings
  INSERT INTO auto_bid_settings (auction_id, user_id, max_bid_amount, bid_increment, is_active, updated_at)
  VALUES (p_auction_id, p_user_id, p_max_bid_amount, COALESCE(p_bid_increment, v_min_increment), p_is_active, NOW())
  ON CONFLICT (auction_id, user_id)
  DO UPDATE SET
    max_bid_amount = EXCLUDED.max_bid_amount,
    bid_increment = EXCLUDED.bid_increment,
    is_active = EXCLUDED.is_active,
    updated_at = NOW()
  RETURNING id INTO v_settings_id;

  -- ================================================================
  -- AUTO-ACTIVATE: If turning ON, check if user is currently outbid
  -- and enqueue for immediate processing on next cron tick
  -- ================================================================
  IF p_is_active THEN
    SELECT bidder_id INTO v_current_bidder_id
    FROM bids WHERE auction_id = p_auction_id
    ORDER BY bid_amount DESC LIMIT 1;

    -- If user is NOT the current leader (or no bids yet), enqueue auto-bid
    IF v_current_bidder_id IS NULL OR v_current_bidder_id != p_user_id THEN
      PERFORM enqueue_auto_bid_processing(p_auction_id);
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'settings_id', v_settings_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. Drop old synchronous process_auto_bids (no longer needed)
-- ============================================================================
DROP FUNCTION IF EXISTS process_auto_bids(UUID, UUID, NUMERIC, NUMERIC);

-- ============================================================================
-- 9. Schedule pg_cron job for queue processing
-- ============================================================================
DO $outer$
BEGIN
  -- Remove any existing schedule with this name
  BEGIN
    PERFORM cron.unschedule('process-auto-bid-queue');
  EXCEPTION WHEN OTHERS THEN
    -- Ignore if doesn't exist
    NULL;
  END;

  -- Try sub-minute scheduling: every 5 seconds (pg_cron 1.5+ with 6-field syntax)
  BEGIN
    PERFORM cron.schedule(
      'process-auto-bid-queue',
      '*/5 * * * * *',
      'SELECT process_auto_bid_queue()'
    );
    RAISE NOTICE 'Auto-bid queue scheduled every 5 seconds';
  EXCEPTION WHEN OTHERS THEN
    -- Fallback: every 1 minute (auto-bids process once per minute instead of every 5s)
    BEGIN
      PERFORM cron.schedule(
        'process-auto-bid-queue',
        '* * * * *',
        'SELECT process_auto_bid_queue()'
      );
      RAISE NOTICE 'Auto-bid queue scheduled every 1 minute (sub-minute cron not supported on this instance)';
    EXCEPTION WHEN OTHERS THEN
      RAISE WARNING 'pg_cron not available. Auto-bid queue requires manual setup.';
    END;
  END;
END $outer$;
