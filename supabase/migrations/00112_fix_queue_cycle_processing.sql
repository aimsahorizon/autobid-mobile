-- ============================================================================
-- Migration 00112: Fix Queue Cycle Processing
-- Bugs fixed:
--   1. Cycle never processes — raise_hand now auto-triggers processing
--      when grace period has elapsed (no dependency on pg_cron latency)
--   2. Duplicate key error on re-raise — lower_hand DELETEs the row
--      instead of setting 'withdrawn', and raise_hand uses ON CONFLICT
--   3. get_queue_status now excludes withdrawn/terminal entries from queue
-- ============================================================================

-- ============================================================================
-- 1. lower_hand() — DELETE the queue entry instead of soft-delete
--    This prevents duplicate key violations on (auction_id, bidder_id, cycle_number)
--    when a user lowers hand and then re-raises in the same cycle.
-- ============================================================================
CREATE OR REPLACE FUNCTION lower_hand(
  p_auction_id UUID,
  p_bidder_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_entry RECORD;
BEGIN
  -- Find the user's active queue entry (pending or active_turn)
  SELECT bq.id, bq.cycle_number, bq.status
  INTO v_entry
  FROM bid_queue bq
  JOIN bid_queue_cycles bqc
    ON bqc.auction_id = bq.auction_id AND bqc.cycle_number = bq.cycle_number
  WHERE bq.auction_id = p_auction_id
    AND bq.bidder_id = p_bidder_id
    AND bq.status IN ('pending', 'active_turn')
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
    -- Delete the entry first so give_next_turn skips it
    DELETE FROM bid_queue WHERE id = v_entry.id;
    -- Then advance the queue
    PERFORM give_next_turn(p_auction_id, v_entry.cycle_number);
  ELSE
    -- Just delete the pending entry
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
-- 2. raise_hand() — ON CONFLICT safety net + auto-trigger processing
--    After the user joins the queue, if the cycle's grace period has
--    already elapsed, immediately call process_single_cycle() so turns
--    start without waiting for pg_cron.
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
  v_grace_period INTEGER := 0;  -- 0 = process immediately (no waiting for more hands)
  v_current_price NUMERIC;
  v_process_result JSONB;
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

  -- 3. Check user hasn't already raised hand this cycle (active entries only)
  IF EXISTS (
    SELECT 1 FROM bid_queue
    WHERE auction_id = p_auction_id
      AND bidder_id = p_bidder_id
      AND cycle_number = v_cycle.cycle_number
      AND status IN ('pending', 'active_turn')
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

  -- 5. Insert into queue — ON CONFLICT handles the rare case where
  --    a withdrawn/expired/executed row still exists from this cycle.
  INSERT INTO bid_queue (auction_id, bidder_id, type, status, cycle_number, position)
  VALUES (p_auction_id, p_bidder_id, 'manual', 'pending', v_cycle.cycle_number, v_position)
  ON CONFLICT (auction_id, bidder_id, cycle_number)
  DO UPDATE SET
    status = 'pending',
    type = 'manual',
    position = EXCLUDED.position,
    bid_amount = NULL,
    turn_started_at = NULL;

  -- 6. AUTO-TRIGGER: If the cycle's grace period has already elapsed,
  --    immediately call process_single_cycle so turns start without
  --    waiting for pg_cron. This is the critical fix for responsiveness.
  IF v_cycle.state = 'open'
     AND NOW() >= v_cycle.opened_at + (v_cycle.grace_period_seconds * INTERVAL '1 second')
  THEN
    v_process_result := process_single_cycle(p_auction_id, v_cycle.cycle_number);
  END IF;

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
-- 3. get_queue_status() — Filter out terminal entries from the queue array
--    Only show pending and active_turn entries to the client.
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

  -- Get queue entries for this cycle — ONLY active entries (pending + active_turn)
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
    AND bq.cycle_number = v_cycle.cycle_number
    AND bq.status IN ('pending', 'active_turn');

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
