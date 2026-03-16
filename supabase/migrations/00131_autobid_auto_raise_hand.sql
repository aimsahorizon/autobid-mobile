-- ============================================================================
-- Migration 00131: Auto-raise hand when autobid is activated + timer fixes
-- Date: 2026-03-16
-- 
-- Problem 1: When a user sets up autobid and is NOT the highest bidder,
--            nothing happens. The auto-bidder only gets injected when someone
--            else manually raises hand or when 2+ auto-bidders exist.
-- Problem 2: After a turn expires, user can't lower hand because the entry
--            is in 'expired' status and lower_hand only looks for pending/active_turn.
-- Problem 3: ON CONFLICT (auction_id, cycle_number) on bid_queue_cycles fails
--            because no unique index exists for that column pair.
--
-- Fix:
--   0. Add UNIQUE index on bid_queue_cycles(auction_id, cycle_number).
--   1. upsert_auto_bid_settings() — after activation, if user is not the
--      current winner, immediately create a cycle and process it so the
--      auto-bidder bids right away.
--   2. give_next_turn() cycle completion — change threshold from 2+ to 1+
--      non-winner auto-bidders. Even a single outbid auto-bidder should
--      get a cycle to counter-bid.
--   3. process_bid_cycles() Phase 3 — same threshold fix.
-- ============================================================================

-- Fix: Add unique index required by ON CONFLICT (auction_id, cycle_number)
CREATE UNIQUE INDEX IF NOT EXISTS idx_bqc_auction_cycle_number
  ON bid_queue_cycles(auction_id, cycle_number);

-- ============================================================================
-- 1. upsert_auto_bid_settings() — Auto-create cycle on activation
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
  v_auction_status TEXT;
  v_end_time TIMESTAMPTZ;
  v_settings_id UUID;
  v_current_bidder_id UUID;
  v_new_cycle_number INTEGER;
  v_process_result JSONB;
BEGIN
  -- Validate auction exists and get state
  SELECT a.bid_increment, a.current_price, a.end_time, s.status_name
  INTO v_min_increment, v_current_price, v_end_time, v_auction_status
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

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
  -- AUTO-RAISE HAND: If activating and auction is live, check if user
  -- needs to bid immediately (they're not the current winner).
  -- Creates a cycle with 0 grace and processes instantly.
  -- ================================================================
  IF p_is_active
     AND v_auction_status IN ('live', 'active')
     AND NOW() < v_end_time
     AND p_max_bid_amount >= v_current_price + v_min_increment
  THEN
    -- Get current highest bidder
    SELECT bidder_id INTO v_current_bidder_id
    FROM bids WHERE auction_id = p_auction_id
    ORDER BY bid_amount DESC LIMIT 1;

    -- Only trigger if user is NOT already winning
    IF v_current_bidder_id IS NULL OR v_current_bidder_id != p_user_id THEN
      -- Only create cycle if no active cycle exists for this auction
      IF NOT EXISTS (
        SELECT 1 FROM bid_queue_cycles
        WHERE auction_id = p_auction_id
          AND state IN ('open', 'locked', 'processing')
      ) THEN
        SELECT COALESCE(MAX(cycle_number), 0) + 1
        INTO v_new_cycle_number
        FROM bid_queue_cycles WHERE auction_id = p_auction_id;

        INSERT INTO bid_queue_cycles (
          auction_id, state, grace_period_seconds, cycle_number, opened_at
        ) VALUES (
          p_auction_id, 'open', 0, v_new_cycle_number, NOW()
        ) ON CONFLICT (auction_id, cycle_number) DO NOTHING;

        -- Immediately process — this will inject auto-bidders and execute
        v_process_result := process_single_cycle(p_auction_id, v_new_cycle_number);
      END IF;
    END IF;
  END IF;

  RETURN jsonb_build_object('success', true, 'settings_id', v_settings_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 1b. lower_hand() — Also match 'expired' entries
--     After a turn expires on the server, the entry status is 'expired'.
--     The user should still be able to "lower hand" (acknowledge/clean up)
--     so the UI resets properly.
-- ============================================================================
CREATE OR REPLACE FUNCTION lower_hand(
  p_auction_id UUID,
  p_bidder_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_entry RECORD;
BEGIN
  -- Find the user's active queue entry (pending, active_turn, OR expired)
  SELECT bq.id, bq.cycle_number, bq.status
  INTO v_entry
  FROM bid_queue bq
  JOIN bid_queue_cycles bqc
    ON bqc.auction_id = bq.auction_id AND bqc.cycle_number = bq.cycle_number
  WHERE bq.auction_id = p_auction_id
    AND bq.bidder_id = p_bidder_id
    AND bq.status IN ('pending', 'active_turn', 'expired')
    AND bqc.state IN ('open', 'locked', 'processing')
  ORDER BY bq.created_at DESC
  LIMIT 1;

  IF v_entry IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'No active queue entry found.'
    );
  END IF;

  -- If user had active turn, give turn to next person BEFORE deleting
  IF v_entry.status = 'active_turn' THEN
    DELETE FROM bid_queue WHERE id = v_entry.id;
    PERFORM give_next_turn(p_auction_id, v_entry.cycle_number);
  ELSE
    -- Just delete the pending or expired entry
    DELETE FROM bid_queue WHERE id = v_entry.id;
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'message', 'Hand lowered successfully.',
    'cycle_number', v_entry.cycle_number
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 2. give_next_turn() — Fix cycle completion threshold
--    Changed: 2+ auto-bidders → 1+ NON-WINNER auto-bidders
--    A single outbid auto-bidder should get a cycle to counter-bid.
-- ============================================================================
CREATE OR REPLACE FUNCTION give_next_turn(
  p_auction_id UUID,
  p_cycle_number INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_next RECORD;
  v_end_time TIMESTAMPTZ;
  v_snipe_enabled BOOLEAN;
  v_snipe_threshold INTEGER;
  v_remaining_seconds INTEGER;
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_auction_title TEXT;
  v_auction_status TEXT;
  v_auto_bid_amount NUMERIC;
  v_auto_max NUMERIC;
  v_user_increment NUMERIC;
  v_effective_increment NUMERIC;
  v_active_bid_status_id UUID;
  v_bid_id UUID;
  v_previous_bidder_id UUID;
  v_current_winner_id UUID;
  v_new_cycle_number INTEGER;
  v_auto_bidder_count INTEGER;
BEGIN
  -- Find next pending entry in position order
  SELECT bq.id, bq.bidder_id, bq.position, bq.type, bq.bid_amount
  INTO v_next
  FROM bid_queue bq
  WHERE bq.auction_id = p_auction_id
    AND bq.cycle_number = p_cycle_number
    AND bq.status = 'pending'
  ORDER BY bq.position ASC
  LIMIT 1
  FOR UPDATE;

  -- ================================================================
  -- NO MORE PENDING → COMPLETE CYCLE + CHECK AUTO-BIDDER COUNTER
  -- ================================================================
  IF v_next IS NULL THEN
    UPDATE bid_queue_cycles
    SET state = 'complete', completed_at = NOW(), updated_at = NOW()
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number
      AND state IN ('open', 'locked', 'processing');

    -- Check if any auto-bidder needs to counter-bid
    SELECT a.current_price, a.bid_increment, a.end_time, s.status_name
    INTO v_current_price, v_min_increment, v_end_time, v_auction_status
    FROM auctions a
    JOIN auction_statuses s ON a.status_id = s.id
    WHERE a.id = p_auction_id;

    IF v_auction_status IN ('live', 'active') AND NOW() < v_end_time THEN
      -- Current winner
      SELECT bidder_id INTO v_current_winner_id
      FROM bids WHERE auction_id = p_auction_id
      ORDER BY bid_amount DESC LIMIT 1;

      -- Count NON-WINNER auto-bidders who can afford to bid.
      -- Even 1 outbid auto-bidder should trigger a new cycle.
      SELECT COUNT(DISTINCT abs.user_id) INTO v_auto_bidder_count
      FROM auto_bid_settings abs
      WHERE abs.auction_id = p_auction_id
        AND abs.is_active = TRUE
        AND abs.max_bid_amount >= v_current_price + v_min_increment
        AND abs.user_id != COALESCE(v_current_winner_id, '00000000-0000-0000-0000-000000000000'::uuid);

      -- 1+ non-winner auto-bidders → create new cycle (0 grace period)
      IF v_auto_bidder_count >= 1 THEN
        SELECT COALESCE(MAX(cycle_number), 0) + 1 INTO v_new_cycle_number
        FROM bid_queue_cycles WHERE auction_id = p_auction_id;

        INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
        VALUES (p_auction_id, 'open', 0, v_new_cycle_number, NOW())
        ON CONFLICT (auction_id, cycle_number) DO NOTHING;
      END IF;
    END IF;

    RETURN jsonb_build_object('success', true, 'action', 'cycle_complete');
  END IF;

  -- ================================================================
  -- GET AUCTION STATE
  -- ================================================================
  SELECT a.current_price, a.bid_increment, a.end_time, a.title,
         a.snipe_guard_enabled, a.snipe_guard_threshold_seconds,
         s.status_name
  INTO v_current_price, v_min_increment, v_end_time, v_auction_title,
       v_snipe_enabled, v_snipe_threshold, v_auction_status
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

  -- Check auction still live
  IF v_auction_status NOT IN ('live', 'active') OR NOW() > v_end_time THEN
    UPDATE bid_queue SET status = 'skipped' WHERE id = v_next.id;
    RETURN give_next_turn(p_auction_id, p_cycle_number);
  END IF;

  -- ================================================================
  -- SNIPE GUARD: add 2 minutes when remaining < threshold
  -- ================================================================
  IF v_snipe_enabled THEN
    v_remaining_seconds := EXTRACT(EPOCH FROM (v_end_time - NOW()))::INTEGER;
    IF v_remaining_seconds > 0 AND v_remaining_seconds < v_snipe_threshold THEN
      UPDATE auctions
      SET end_time = end_time + INTERVAL '2 minutes',
          snipe_guard_last_applied_at = NOW(),
          updated_at = NOW()
      WHERE id = p_auction_id;
      v_end_time := v_end_time + INTERVAL '2 minutes';
    END IF;
  END IF;

  -- ================================================================
  -- AUTO-BIDDER: immediate execution (no 60s wait)
  -- ================================================================
  IF v_next.type = 'auto' THEN
    -- Re-read current price (may have changed during this cycle)
    SELECT current_price INTO v_current_price FROM auctions WHERE id = p_auction_id;

    -- Use user's bid_increment from auto_bid_settings (not auction min)
    SELECT max_bid_amount, COALESCE(bid_increment, v_min_increment)
    INTO v_auto_max, v_user_increment
    FROM auto_bid_settings
    WHERE auction_id = p_auction_id AND user_id = v_next.bidder_id AND is_active = TRUE;

    -- Ensure user's increment is at least the auction minimum
    v_effective_increment := GREATEST(v_user_increment, v_min_increment);

    -- Calculate bid: current price + user's increment, rounded up to nearest 100
    v_auto_bid_amount := CEIL((v_current_price + v_effective_increment) / 100.0) * 100;

    -- Check if auto-bidder can afford the bid
    IF v_auto_max IS NULL OR v_auto_bid_amount > v_auto_max THEN
      -- Try using max itself (floored to 100) if it still beats current
      IF v_auto_max IS NOT NULL AND v_auto_max > v_current_price THEN
        v_auto_bid_amount := FLOOR(v_auto_max / 100.0) * 100;
        IF v_auto_bid_amount <= v_current_price THEN
          UPDATE bid_queue SET status = 'skipped' WHERE id = v_next.id;
          UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
          WHERE auction_id = p_auction_id AND user_id = v_next.bidder_id;
          PERFORM create_bid_notification(
            v_next.bidder_id, 'max_bid_reached',
            'Auto-Bid Limit Reached',
            format('Your auto-bid limit of ₱%s has been reached on %s.',
              to_char(v_auto_max, 'FM999,999,999'), v_auction_title),
            jsonb_build_object('auction_id', p_auction_id, 'action', 'view_auction')
          );
          RETURN give_next_turn(p_auction_id, p_cycle_number);
        END IF;
      ELSE
        UPDATE bid_queue SET status = 'skipped' WHERE id = v_next.id;
        IF v_auto_max IS NOT NULL THEN
          UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
          WHERE auction_id = p_auction_id AND user_id = v_next.bidder_id;
          PERFORM create_bid_notification(
            v_next.bidder_id, 'max_bid_reached',
            'Auto-Bid Limit Reached',
            format('Your auto-bid limit of ₱%s has been reached on %s.',
              to_char(v_auto_max, 'FM999,999,999'), v_auction_title),
            jsonb_build_object('auction_id', p_auction_id, 'action', 'view_auction')
          );
        END IF;
        RETURN give_next_turn(p_auction_id, p_cycle_number);
      END IF;
    END IF;

    -- Don't let auto-bidder bid against themselves (already winning)
    SELECT bidder_id INTO v_current_winner_id
    FROM bids WHERE auction_id = p_auction_id
    ORDER BY bid_amount DESC LIMIT 1;

    IF v_next.bidder_id = v_current_winner_id THEN
      UPDATE bid_queue SET status = 'skipped' WHERE id = v_next.id;
      RETURN give_next_turn(p_auction_id, p_cycle_number);
    END IF;

    -- Execute auto-bid
    SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;
    v_previous_bidder_id := v_current_winner_id;

    UPDATE bid_queue SET status = 'executed', bid_amount = v_auto_bid_amount WHERE id = v_next.id;

    INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
    VALUES (p_auction_id, v_next.bidder_id, v_auto_bid_amount, TRUE, v_active_bid_status_id)
    RETURNING id INTO v_bid_id;

    UPDATE auctions
    SET current_price = v_auto_bid_amount,
        total_bids = COALESCE(total_bids, 0) + 1,
        updated_at = NOW()
    WHERE id = p_auction_id;

    -- Update last_bid_at tracker
    UPDATE auto_bid_settings
    SET last_bid_at = NOW(), updated_at = NOW()
    WHERE auction_id = p_auction_id AND user_id = v_next.bidder_id;

    -- Notify outbid
    IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != v_next.bidder_id THEN
      PERFORM create_bid_notification(
        v_previous_bidder_id, 'outbid',
        'You''ve Been Outbid!',
        format('Someone placed a higher bid of ₱%s on %s.',
          to_char(v_auto_bid_amount, 'FM999,999,999'), v_auction_title),
        jsonb_build_object('auction_id', p_auction_id, 'outbid_amount', v_auto_bid_amount, 'action', 'place_bid')
      );
    END IF;

    -- Move to next person immediately (recurse)
    RETURN give_next_turn(p_auction_id, p_cycle_number);
  END IF;

  -- ================================================================
  -- MANUAL BIDDER: give 60-second turn
  -- ================================================================
  UPDATE bid_queue
  SET status = 'active_turn', turn_started_at = NOW()
  WHERE id = v_next.id;

  RETURN jsonb_build_object(
    'success', true,
    'action', 'turn_given',
    'bidder_id', v_next.bidder_id,
    'position', v_next.position
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. process_bid_cycles() — Fix Phase 3 threshold
--    Changed: 2+ auto-bidders → 1+ NON-WINNER auto-bidders
-- ============================================================================
CREATE OR REPLACE FUNCTION process_bid_cycles()
RETURNS JSONB AS $$
DECLARE
  v_cycle RECORD;
  v_result JSONB;
  v_processed INTEGER := 0;
  v_auction RECORD;
  v_current_winner_id UUID;
  v_auto_bidder_count INTEGER;
  v_new_cycle_number INTEGER;
BEGIN
  -- 1. Process open cycles past their grace period → start turn-based processing
  FOR v_cycle IN
    SELECT * FROM bid_queue_cycles
    WHERE state = 'open'
      AND NOW() >= opened_at + (grace_period_seconds * INTERVAL '1 second')
    FOR UPDATE SKIP LOCKED
  LOOP
    v_result := process_single_cycle(v_cycle.auction_id, v_cycle.cycle_number);
    v_processed := v_processed + 1;
  END LOOP;

  -- 2. Check processing cycles for expired turns → expire and give next
  FOR v_cycle IN
    SELECT * FROM bid_queue_cycles
    WHERE state = 'processing'
    FOR UPDATE SKIP LOCKED
  LOOP
    v_result := process_single_cycle(v_cycle.auction_id, v_cycle.cycle_number);
    v_processed := v_processed + 1;
  END LOOP;

  -- 3. Create new cycles for live auctions with auto-bidders who need to bid
  --    but no active cycle currently running.
  FOR v_auction IN
    SELECT DISTINCT a.id, a.current_price, a.bid_increment, a.end_time
    FROM auctions a
    JOIN auction_statuses s ON a.status_id = s.id
    WHERE s.status_name IN ('live', 'active')
      AND a.end_time > NOW()
      AND NOT EXISTS (
        SELECT 1 FROM bid_queue_cycles bqc
        WHERE bqc.auction_id = a.id
          AND bqc.state IN ('open', 'locked', 'processing')
      )
  LOOP
    -- Current winner (auto-bidders don't bid against themselves)
    SELECT bidder_id INTO v_current_winner_id
    FROM bids WHERE auction_id = v_auction.id
    ORDER BY bid_amount DESC LIMIT 1;

    -- Count NON-WINNER auto-bidders who can outbid.
    -- Even 1 outbid auto-bidder should trigger a cycle.
    SELECT COUNT(DISTINCT abs.user_id) INTO v_auto_bidder_count
    FROM auto_bid_settings abs
    WHERE abs.auction_id = v_auction.id
      AND abs.is_active = TRUE
      AND abs.max_bid_amount >= v_auction.current_price + v_auction.bid_increment
      AND abs.user_id != COALESCE(v_current_winner_id, '00000000-0000-0000-0000-000000000000'::uuid);

    IF v_auto_bidder_count >= 1 THEN
      SELECT COALESCE(MAX(cycle_number), 0) + 1 INTO v_new_cycle_number
      FROM bid_queue_cycles WHERE auction_id = v_auction.id;

      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (v_auction.id, 'open', 0, v_new_cycle_number, NOW())
      ON CONFLICT (auction_id, cycle_number) DO NOTHING;

      v_processed := v_processed + 1;
    END IF;
  END LOOP;

  RETURN jsonb_build_object('processed', v_processed);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
