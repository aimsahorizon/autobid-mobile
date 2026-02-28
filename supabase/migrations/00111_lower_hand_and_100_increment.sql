-- Migration: 00111_lower_hand_and_100_increment.sql
-- Date: 2026-02-24
-- Description:
--   1. Fix bid_queue CHECK constraint to add 'withdrawn', 'active_turn', 'expired'
--   2. DROP old 2-param raise_hand() causing function overload ambiguity
--   3. lower_hand() — allows buyers to withdraw from the queue
--   4. give_next_turn() — turn management with auto-bidder auto-execution,
--      snipe guard (2-min extension when within threshold), cycle continuation
--   5. process_single_cycle() — locks cycle, injects auto-bidders, starts turns
--   6. submit_turn_bid() — manual bid during 60s turn (no snipe guard here)
--   7. raise_hand() — queue-only (NO bid amount)
--   8. Change minimum increment granularity from ₱1,000 to ₱100
--   9. process_bid_cycles() — also checks expired turns + creates auto-bidder cycles
--  10. get_queue_status() — includes active turn info

-- ============================================================================
-- 0. Schema changes
-- ============================================================================

-- 0a. Fix bid_queue CHECK constraint
ALTER TABLE bid_queue DROP CONSTRAINT IF EXISTS bid_queue_status_check;
ALTER TABLE bid_queue ADD CONSTRAINT bid_queue_status_check
  CHECK (status IN ('pending', 'processing', 'executed', 'skipped', 'failed', 'withdrawn', 'active_turn', 'expired'));

-- 0b. Add turn_started_at column to track when a user's turn began (60s timer)
ALTER TABLE bid_queue ADD COLUMN IF NOT EXISTS turn_started_at TIMESTAMPTZ;

-- 0c. DROP the old 2-parameter raise_hand function from migration 00109.
--     Migration 00110 created a 3-param version (UUID, UUID, NUMERIC DEFAULT NULL)
--     but did NOT drop the 2-param version, causing PostgreSQL function overload
--     ambiguity: "could not choose the best candidate function between
--     public.raise_hand(p_auction_id => uuid, p_bidder_id => uuid) and
--     public.raise_hand(p_auction_id => uuid, p_bidder_id => uuid, p_bid_amount => numeric)"
DROP FUNCTION IF EXISTS raise_hand(UUID, UUID);

-- ============================================================================
-- 1. lower_hand() — Withdraw from the bid queue
-- ============================================================================
CREATE OR REPLACE FUNCTION lower_hand(
  p_auction_id UUID,
  p_bidder_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_entry RECORD;
BEGIN
  -- Find the bidder's pending or active_turn entry in any active cycle
  SELECT bq.id, bq.cycle_number, bq.position, bq.status, bqc.state AS cycle_state
  INTO v_entry
  FROM bid_queue bq
  JOIN bid_queue_cycles bqc
    ON bqc.auction_id = bq.auction_id AND bqc.cycle_number = bq.cycle_number
  WHERE bq.auction_id = p_auction_id
    AND bq.bidder_id = p_bidder_id
    AND bq.status IN ('pending', 'active_turn')
    AND bqc.state IN ('open', 'locked', 'processing')
  ORDER BY bq.cycle_number DESC
  LIMIT 1
  FOR UPDATE OF bq;

  IF v_entry IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'You are not currently in the queue.'
    );
  END IF;

  -- Mark entry as withdrawn
  UPDATE bid_queue
  SET status = 'withdrawn'
  WHERE id = v_entry.id;

  -- If they were the active turn, immediately give turn to next person
  IF v_entry.status = 'active_turn' THEN
    PERFORM give_next_turn(p_auction_id, v_entry.cycle_number);
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'cycle_number', v_entry.cycle_number,
    'position', v_entry.position,
    'message', 'Hand lowered successfully.'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 2. give_next_turn() — Internal: find next pending entry, give turn
--    * Auto-bidders (type='auto') execute immediately (no 60s wait)
--    * Snipe guard: adds 2 minutes when remaining < threshold
--    * On cycle complete: creates new cycle if 2+ auto-bidders can battle
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
  -- NO MORE PENDING → COMPLETE CYCLE + CHECK AUTO-BIDDER BATTLE
  -- ================================================================
  IF v_next IS NULL THEN
    UPDATE bid_queue_cycles
    SET state = 'complete', completed_at = NOW(), updated_at = NOW()
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number
      AND state IN ('open', 'locked', 'processing');

    -- Check if auto-bidders need to continue battling
    SELECT a.current_price, a.bid_increment, a.end_time, s.status_name
    INTO v_current_price, v_min_increment, v_end_time, v_auction_status
    FROM auctions a
    JOIN auction_statuses s ON a.status_id = s.id
    WHERE a.id = p_auction_id;

    IF v_auction_status IN ('live', 'active') AND NOW() < v_end_time THEN
      -- Current winning bidder (excluded from auto-bidder count)
      SELECT bidder_id INTO v_current_winner_id
      FROM bids WHERE auction_id = p_auction_id
      ORDER BY bid_amount DESC LIMIT 1;

      -- Count auto-bidders who can still outbid
      SELECT COUNT(DISTINCT abs.user_id) INTO v_auto_bidder_count
      FROM auto_bid_settings abs
      WHERE abs.auction_id = p_auction_id
        AND abs.is_active = TRUE
        AND abs.max_bid_amount >= v_current_price + v_min_increment
        AND abs.user_id != COALESCE(v_current_winner_id, '00000000-0000-0000-0000-000000000000'::uuid);

      -- 2+ auto-bidders can battle → create new cycle (0 grace period)
      IF v_auto_bidder_count >= 2 THEN
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
  -- "when the duration is within the anti bid snipping settings,
  --  add additional of 2 minutes to the duration of the auction"
  -- "if total time added went beyond the anti bid sniping window,
  --  then the increment upon bidding must not be active again
  --  until it goes back to the anti sniping window"
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

    -- Calculate bid: ceil to nearest 100
    v_auto_bid_amount := CEIL((v_current_price + v_min_increment) / 100.0) * 100;

    -- Get auto-bidder's max budget
    SELECT max_bid_amount INTO v_auto_max
    FROM auto_bid_settings
    WHERE auction_id = p_auction_id AND user_id = v_next.bidder_id AND is_active = TRUE;

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
-- 3. process_single_cycle() — Lock cycle, inject auto-bidders, start turns
-- ============================================================================
CREATE OR REPLACE FUNCTION process_single_cycle(
  p_auction_id UUID,
  p_cycle_number INTEGER
) RETURNS JSONB AS $$
DECLARE
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_end_time TIMESTAMPTZ;
  v_auction_status TEXT;
  v_auction_title TEXT;
  v_cycle_id UUID;
  v_turn_result JSONB;
  v_active_entry RECORD;
  v_auto_position INTEGER;
  v_previous_bidder_id UUID;
  v_autobidder RECORD;
BEGIN
  -- ============================
  -- PHASE 1: Check for expired active turns
  -- ============================
  SELECT bq.id, bq.bidder_id, bq.turn_started_at, bq.cycle_number
  INTO v_active_entry
  FROM bid_queue bq
  JOIN bid_queue_cycles bqc
    ON bqc.auction_id = bq.auction_id AND bqc.cycle_number = bq.cycle_number
  WHERE bq.auction_id = p_auction_id
    AND bq.cycle_number = p_cycle_number
    AND bq.status = 'active_turn'
    AND bqc.state IN ('open', 'locked', 'processing')
  LIMIT 1;

  IF v_active_entry IS NOT NULL THEN
    IF v_active_entry.turn_started_at IS NOT NULL
       AND NOW() > v_active_entry.turn_started_at + INTERVAL '60 seconds' THEN
      UPDATE bid_queue SET status = 'expired' WHERE id = v_active_entry.id;
      v_turn_result := give_next_turn(p_auction_id, p_cycle_number);
      RETURN jsonb_build_object(
        'success', true,
        'action', 'turn_expired',
        'expired_bidder', v_active_entry.bidder_id,
        'next_turn', v_turn_result
      );
    ELSE
      RETURN jsonb_build_object(
        'success', true,
        'action', 'turn_active',
        'bidder_id', v_active_entry.bidder_id
      );
    END IF;
  END IF;

  -- ============================
  -- PHASE 2: LOCK the cycle (if still open)
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'processing', locked_at = NOW(), processing_at = NOW(), updated_at = NOW()
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND state = 'open'
  RETURNING id INTO v_cycle_id;

  IF v_cycle_id IS NULL THEN
    SELECT id INTO v_cycle_id FROM bid_queue_cycles
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number
      AND state = 'processing';

    IF v_cycle_id IS NULL THEN
      RETURN jsonb_build_object('success', false, 'error', 'Cycle already completed or not found');
    END IF;
  END IF;

  -- Get auction state
  SELECT a.current_price, a.bid_increment, a.end_time, s.status_name, a.title
  INTO v_current_price, v_min_increment, v_end_time, v_auction_status, v_auction_title
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

  IF v_auction_status NOT IN ('live', 'active') OR NOW() > v_end_time THEN
    UPDATE bid_queue_cycles
    SET state = 'complete', completed_at = NOW(), updated_at = NOW()
    WHERE id = v_cycle_id;

    UPDATE bid_queue
    SET status = 'skipped'
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND status = 'pending';

    RETURN jsonb_build_object('success', false, 'error', 'Auction no longer live');
  END IF;

  -- ============================
  -- PHASE 2b: INJECT auto-bidders into the queue
  -- Auto-bidders are placed AFTER manual bidders (by position).
  -- Their actual bid amount is calculated at execution time in give_next_turn().
  -- ============================
  SELECT COALESCE(MAX(position), 0) INTO v_auto_position
  FROM bid_queue WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

  -- Current winner (auto-bidders won't bid against themselves)
  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC LIMIT 1;

  FOR v_autobidder IN
    SELECT abs.user_id, abs.max_bid_amount
    FROM auto_bid_settings abs
    WHERE abs.auction_id = p_auction_id
      AND abs.is_active = TRUE
      AND abs.max_bid_amount >= v_current_price + v_min_increment
      AND abs.user_id != COALESCE(v_previous_bidder_id, '00000000-0000-0000-0000-000000000000'::uuid)
      AND NOT EXISTS (
        SELECT 1 FROM bid_queue bq
        WHERE bq.auction_id = p_auction_id
          AND bq.bidder_id = abs.user_id
          AND bq.cycle_number = p_cycle_number
      )
    ORDER BY abs.created_at ASC
  LOOP
    v_auto_position := v_auto_position + 1;

    INSERT INTO bid_queue (auction_id, bidder_id, type, status, cycle_number, position)
    VALUES (p_auction_id, v_autobidder.user_id, 'auto', 'pending', p_cycle_number, v_auto_position)
    ON CONFLICT (auction_id, bidder_id, cycle_number) DO NOTHING;
  END LOOP;

  -- ============================
  -- PHASE 3: Give first pending person their turn
  -- (If auto-bidder, give_next_turn auto-executes immediately)
  -- ============================
  v_turn_result := give_next_turn(p_auction_id, p_cycle_number);

  RETURN jsonb_build_object(
    'success', true,
    'cycle_number', p_cycle_number,
    'turn_result', v_turn_result
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. submit_turn_bid() — Active turn user places their bid
--    Snipe guard is handled in give_next_turn() when assigning turns,
--    NOT here. This simplifies bid placement.
-- ============================================================================
CREATE OR REPLACE FUNCTION submit_turn_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_bid_amount NUMERIC
) RETURNS JSONB AS $$
DECLARE
  v_entry RECORD;
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_end_time TIMESTAMPTZ;
  v_auction_status TEXT;
  v_auction_title TEXT;
  v_active_bid_status_id UUID;
  v_bid_id UUID;
  v_previous_bidder_id UUID;
  v_turn_result JSONB;
BEGIN
  -- 1. Find the user's active_turn entry
  SELECT bq.id, bq.cycle_number, bq.turn_started_at
  INTO v_entry
  FROM bid_queue bq
  JOIN bid_queue_cycles bqc
    ON bqc.auction_id = bq.auction_id AND bqc.cycle_number = bq.cycle_number
  WHERE bq.auction_id = p_auction_id
    AND bq.bidder_id = p_bidder_id
    AND bq.status = 'active_turn'
    AND bqc.state = 'processing'
  LIMIT 1
  FOR UPDATE OF bq;

  IF v_entry IS NULL THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'It is not your turn to bid.'
    );
  END IF;

  -- 2. Check 60s hasn't expired
  IF v_entry.turn_started_at IS NOT NULL
     AND NOW() > v_entry.turn_started_at + INTERVAL '60 seconds' THEN
    UPDATE bid_queue SET status = 'expired' WHERE id = v_entry.id;
    PERFORM give_next_turn(p_auction_id, v_entry.cycle_number);
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Your turn has expired (60 seconds). The next bidder has been given their turn.'
    );
  END IF;

  -- 3. Get auction state
  SELECT a.current_price, a.bid_increment, a.end_time, s.status_name, a.title
  INTO v_current_price, v_min_increment, v_end_time, v_auction_status, v_auction_title
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id
  FOR UPDATE;

  IF v_auction_status NOT IN ('live', 'active') OR NOW() > v_end_time THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction is no longer live');
  END IF;

  -- 4. Validate bid amount
  IF p_bid_amount < v_current_price + v_min_increment THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', format('Bid must be at least ₱%s', to_char(v_current_price + v_min_increment, 'FM999,999,999'))
    );
  END IF;

  IF p_bid_amount::numeric % 100 != 0 THEN
    RETURN jsonb_build_object('success', false, 'error', 'Bid must be a multiple of ₱100');
  END IF;

  -- 5. Get active bid status
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;

  -- 6. Get previous leading bidder (for outbid notification)
  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC LIMIT 1;

  -- 7. Place the bid
  UPDATE bid_queue SET status = 'executed', bid_amount = p_bid_amount WHERE id = v_entry.id;

  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
  VALUES (p_auction_id, p_bidder_id, p_bid_amount, FALSE, v_active_bid_status_id)
  RETURNING id INTO v_bid_id;

  -- 8. Update auction price and total bids (NO snipe guard here — handled in give_next_turn)
  UPDATE auctions
  SET
    current_price = p_bid_amount,
    total_bids = COALESCE(total_bids, 0) + 1,
    updated_at = NOW()
  WHERE id = p_auction_id;

  -- 9. Notify previous bidder of being outbid
  IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != p_bidder_id THEN
    PERFORM create_bid_notification(
      v_previous_bidder_id, 'outbid',
      'You''ve Been Outbid!',
      format('Someone placed a higher bid of ₱%s on %s.',
        to_char(p_bid_amount, 'FM999,999,999'), v_auction_title),
      jsonb_build_object('auction_id', p_auction_id, 'outbid_amount', p_bid_amount, 'action', 'place_bid')
    );
  END IF;

  -- 10. Give turn to next person (or complete cycle)
  v_turn_result := give_next_turn(p_auction_id, v_entry.cycle_number);

  RETURN jsonb_build_object(
    'success', true,
    'bid_id', v_bid_id,
    'bid_amount', p_bid_amount,
    'cycle_number', v_entry.cycle_number,
    'next_turn', v_turn_result,
    'message', format('Bid of ₱%s placed successfully!', to_char(p_bid_amount, 'FM999,999,999'))
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. Update raise_hand() — queue-only, NO bid amount
-- ============================================================================
CREATE OR REPLACE FUNCTION raise_hand(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_bid_amount NUMERIC DEFAULT NULL  -- kept for backward compat but ignored
) RETURNS JSONB AS $$
DECLARE
  v_auction_status TEXT;
  v_end_time TIMESTAMPTZ;
  v_cycle RECORD;
  v_position INTEGER;
  v_grace_period INTEGER := 3;
  v_current_price NUMERIC;
BEGIN
  -- 1. Validate auction is live
  SELECT s.status_name, a.end_time, a.current_price
  INTO v_auction_status, v_end_time, v_current_price
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id
  FOR UPDATE;

  IF v_auction_status IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction not found');
  END IF;

  IF v_auction_status NOT IN ('live', 'active') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction is not live');
  END IF;

  IF NOW() > v_end_time THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction has ended');
  END IF;

  -- 2. Get or create cycle — support concurrent cycles
  SELECT * INTO v_cycle FROM bid_queue_cycles
  WHERE auction_id = p_auction_id
    AND state IN ('open', 'processing')
  ORDER BY cycle_number DESC
  LIMIT 1
  FOR UPDATE;

  IF v_cycle IS NULL THEN
    SELECT * INTO v_cycle FROM bid_queue_cycles
    WHERE auction_id = p_auction_id
    ORDER BY cycle_number DESC
    LIMIT 1;

    IF v_cycle IS NULL THEN
      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (p_auction_id, 'open', v_grace_period, 1, NOW())
      RETURNING * INTO v_cycle;
    ELSIF v_cycle.state = 'complete' THEN
      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (p_auction_id, 'open', v_grace_period, v_cycle.cycle_number + 1, NOW())
      RETURNING * INTO v_cycle;
    ELSIF v_cycle.state = 'locked' THEN
      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (p_auction_id, 'open', v_grace_period, v_cycle.cycle_number + 1, NOW())
      RETURNING * INTO v_cycle;
    END IF;
  END IF;

  -- 3. Check user hasn't already raised hand this cycle
  IF EXISTS (
    SELECT 1 FROM bid_queue
    WHERE auction_id = p_auction_id
      AND bidder_id = p_bidder_id
      AND cycle_number = v_cycle.cycle_number
      AND status NOT IN ('withdrawn', 'skipped', 'executed', 'expired')
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'You have already raised your hand this round.',
      'state', v_cycle.state
    );
  END IF;

  -- 4. Calculate position (next available in this cycle)
  SELECT COALESCE(MAX(position), 0) + 1 INTO v_position
  FROM bid_queue
  WHERE auction_id = p_auction_id
    AND cycle_number = v_cycle.cycle_number;

  -- 5. Insert into queue WITHOUT bid amount (queue only)
  INSERT INTO bid_queue (auction_id, bidder_id, type, status, cycle_number, position)
  VALUES (p_auction_id, p_bidder_id, 'manual', 'pending', v_cycle.cycle_number, v_position);

  RETURN jsonb_build_object(
    'success', true,
    'position', v_position,
    'cycle_number', v_cycle.cycle_number,
    'state', v_cycle.state,
    'grace_period_seconds', v_cycle.grace_period_seconds,
    'message', format(
      'Hand raised! You are #%s in queue. When it''s your turn, you''ll have 60 seconds to place your bid.',
      v_position
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. Add CHECK constraints on listing_drafts prices (multiples of 100)
-- ============================================================================
-- Drop old constraints if they exist, then add new ones
ALTER TABLE listing_drafts DROP CONSTRAINT IF EXISTS listing_drafts_starting_price_multiple_100;
ALTER TABLE listing_drafts DROP CONSTRAINT IF EXISTS listing_drafts_reserve_price_multiple_100;
ALTER TABLE listing_drafts DROP CONSTRAINT IF EXISTS listing_drafts_bid_increment_min_100;

-- Round existing data to nearest 100 so constraints don't fail
UPDATE listing_drafts SET starting_price = ROUND(starting_price::numeric / 100) * 100
  WHERE starting_price IS NOT NULL AND (starting_price::numeric % 100) != 0;
UPDATE listing_drafts SET reserve_price = ROUND(reserve_price::numeric / 100) * 100
  WHERE reserve_price IS NOT NULL AND (reserve_price::numeric % 100) != 0;
UPDATE listing_drafts SET bid_increment = GREATEST(100, ROUND(bid_increment::numeric / 100) * 100)
  WHERE bid_increment IS NOT NULL AND (bid_increment < 100 OR (bid_increment::numeric % 100) != 0);
UPDATE listing_drafts SET min_bid_increment = GREATEST(100, ROUND(min_bid_increment::numeric / 100) * 100)
  WHERE min_bid_increment IS NOT NULL AND (min_bid_increment::numeric % 100) != 0;

-- Starting price must be multiple of 100
ALTER TABLE listing_drafts ADD CONSTRAINT listing_drafts_starting_price_multiple_100
  CHECK (starting_price IS NULL OR (starting_price::numeric % 100) = 0);

-- Reserve price must be multiple of 100
ALTER TABLE listing_drafts ADD CONSTRAINT listing_drafts_reserve_price_multiple_100
  CHECK (reserve_price IS NULL OR (reserve_price::numeric % 100) = 0);

-- Bid increment minimum 100, must be multiple of 100
ALTER TABLE listing_drafts ADD CONSTRAINT listing_drafts_bid_increment_min_100
  CHECK (bid_increment IS NULL OR (bid_increment >= 100 AND (bid_increment::numeric % 100) = 0));

-- Also update the min_bid_increment column default
ALTER TABLE listing_drafts ALTER COLUMN bid_increment SET DEFAULT 100;
ALTER TABLE listing_drafts ALTER COLUMN min_bid_increment SET DEFAULT 100;

-- Update auctions table defaults too
ALTER TABLE auctions ALTER COLUMN bid_increment SET DEFAULT 100;

-- ============================================================================
-- 7. Update get_queue_status() — include turn info
-- ============================================================================
CREATE OR REPLACE FUNCTION get_queue_status(p_auction_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_cycle RECORD;
  v_queue JSONB;
  v_remaining_ms INTEGER;
  v_active_turn RECORD;
  v_turn_remaining_ms INTEGER;
BEGIN
  -- Find the latest non-complete cycle (active one), or the latest complete
  SELECT * INTO v_cycle FROM bid_queue_cycles
  WHERE auction_id = p_auction_id
    AND state IN ('open', 'locked', 'processing')
  ORDER BY cycle_number DESC
  LIMIT 1;

  -- If no active cycle, show latest complete or idle
  IF v_cycle IS NULL THEN
    SELECT * INTO v_cycle FROM bid_queue_cycles
    WHERE auction_id = p_auction_id
    ORDER BY cycle_number DESC
    LIMIT 1;

    IF v_cycle IS NULL THEN
      RETURN jsonb_build_object(
        'state', 'idle',
        'cycle_number', 0,
        'queue', '[]'::jsonb,
        'remaining_ms', 0,
        'grace_period_seconds', 3,
        'active_turn_bidder_id', NULL,
        'turn_remaining_ms', 0
      );
    END IF;
  END IF;

  -- Get queue entries for this cycle
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', bq.id,
      'bidder_id', bq.bidder_id,
      'type', bq.type,
      'status', bq.status,
      'position', bq.position,
      'bid_amount', bq.bid_amount,
      'turn_started_at', bq.turn_started_at
    ) ORDER BY bq.position ASC
  ), '[]'::jsonb)
  INTO v_queue
  FROM bid_queue bq
  WHERE bq.auction_id = p_auction_id
    AND bq.cycle_number = v_cycle.cycle_number;

  -- Calculate remaining grace period
  IF v_cycle.state = 'open' THEN
    v_remaining_ms := GREATEST(0,
      EXTRACT(EPOCH FROM (
        v_cycle.opened_at + (v_cycle.grace_period_seconds * INTERVAL '1 second') - NOW()
      )) * 1000
    )::INTEGER;
  ELSE
    v_remaining_ms := 0;
  END IF;

  -- Find active turn info
  SELECT bq.bidder_id, bq.turn_started_at
  INTO v_active_turn
  FROM bid_queue bq
  WHERE bq.auction_id = p_auction_id
    AND bq.cycle_number = v_cycle.cycle_number
    AND bq.status = 'active_turn'
  LIMIT 1;

  IF v_active_turn IS NOT NULL AND v_active_turn.turn_started_at IS NOT NULL THEN
    v_turn_remaining_ms := GREATEST(0,
      EXTRACT(EPOCH FROM (
        v_active_turn.turn_started_at + INTERVAL '60 seconds' - NOW()
      )) * 1000
    )::INTEGER;
  ELSE
    v_turn_remaining_ms := 0;
  END IF;

  RETURN jsonb_build_object(
    'state', v_cycle.state,
    'cycle_number', v_cycle.cycle_number,
    'queue', v_queue,
    'remaining_ms', v_remaining_ms,
    'grace_period_seconds', v_cycle.grace_period_seconds,
    'active_turn_bidder_id', v_active_turn.bidder_id,
    'turn_remaining_ms', v_turn_remaining_ms,
    'opened_at', v_cycle.opened_at,
    'locked_at', v_cycle.locked_at,
    'processing_at', v_cycle.processing_at,
    'completed_at', v_cycle.completed_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 9. process_bid_cycles() — REVISED
--    * Processes open cycles past grace period (existing)
--    * Checks processing cycles for expired turns (NEW)
--    * Creates new cycles for auto-bidder battles when no active cycle (NEW)
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

  -- 3. Create new cycles for live auctions with 2+ active auto-bidders battling
  --    but no active cycle currently running. This ensures continuous cycles
  --    "until the end time of the auction" when auto-bidders are active.
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
    -- Current winner (excluded from count — they don't bid against themselves)
    SELECT bidder_id INTO v_current_winner_id
    FROM bids WHERE auction_id = v_auction.id
    ORDER BY bid_amount DESC LIMIT 1;

    -- Count auto-bidders who can outbid
    SELECT COUNT(DISTINCT abs.user_id) INTO v_auto_bidder_count
    FROM auto_bid_settings abs
    WHERE abs.auction_id = v_auction.id
      AND abs.is_active = TRUE
      AND abs.max_bid_amount >= v_auction.current_price + v_auction.bid_increment
      AND abs.user_id != COALESCE(v_current_winner_id, '00000000-0000-0000-0000-000000000000'::uuid);

    IF v_auto_bidder_count >= 2 THEN
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