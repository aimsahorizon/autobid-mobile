-- Migration: 00110_raise_hand_v2_bid_selection.sql
-- Date: 2026-02-23
-- Description: Raise Hand v2 — User-chosen bid amounts + bucket-picks-lowest + concurrent cycles
--
--   CHANGES:
--   1. raise_hand() now accepts p_bid_amount (user picks their increment)
--   2. process_single_cycle() picks the LOWEST bid from the bucket (not FIFO all)
--   3. Bidders can always raise hand: if current cycle is processing, entry goes to NEXT cycle
--   4. bid_queue_cycles: remove UNIQUE on auction_id (multiple cycles per auction)
--   5. get_queue_status() returns current + next cycle info
--   6. get_seller_queue_status() — new RPC for seller live view

-- ============================================================================
-- 1. Remove UNIQUE constraint on bid_queue_cycles.auction_id
--    (allow multiple rows per auction — one per cycle)
-- ============================================================================
ALTER TABLE bid_queue_cycles DROP CONSTRAINT IF EXISTS bid_queue_cycles_auction_id_key;

-- Add compound unique so only ONE non-complete cycle per auction at a time
-- We'll enforce this in code, but add index for fast lookups
CREATE INDEX IF NOT EXISTS idx_bqc_auction_state ON bid_queue_cycles(auction_id, state);

-- ============================================================================
-- 2. raise_hand() v2 — Accepts user-chosen bid amount + concurrent cycles
-- ============================================================================
CREATE OR REPLACE FUNCTION raise_hand(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_bid_amount NUMERIC DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_auction_status TEXT;
  v_end_time TIMESTAMPTZ;
  v_cycle RECORD;
  v_position INTEGER;
  v_grace_period INTEGER := 3;
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
  v_bid_amount NUMERIC;
BEGIN
  -- 1. Validate auction is live
  SELECT s.status_name, a.end_time, a.current_price, a.bid_increment
  INTO v_auction_status, v_end_time, v_current_price, v_min_increment
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

  -- 2. Determine bid amount
  IF p_bid_amount IS NOT NULL THEN
    v_bid_amount := p_bid_amount;
    -- Validate: must be >= current_price + min_increment
    IF v_bid_amount < v_current_price + v_min_increment THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', format('Bid must be at least ₱%s', to_char(v_current_price + v_min_increment, 'FM999,999,999'))
      );
    END IF;
    -- Validate: must be multiple of 1,000
    IF v_bid_amount % 1000 != 0 THEN
      RETURN jsonb_build_object('success', false, 'error', 'Bid must be a multiple of ₱1,000');
    END IF;
  ELSE
    -- Default: current price + min increment, rounded up to nearest 1k
    v_bid_amount := CEIL((v_current_price + v_min_increment) / 1000.0) * 1000;
  END IF;

  -- 3. Get or create cycle — support concurrent cycles
  --    Find the latest OPEN cycle, or create one.
  --    If current cycle is locked/processing, create a NEW cycle for next round.
  SELECT * INTO v_cycle FROM bid_queue_cycles
  WHERE auction_id = p_auction_id
    AND state IN ('open')
  ORDER BY cycle_number DESC
  LIMIT 1
  FOR UPDATE;

  IF v_cycle IS NULL THEN
    -- No open cycle. Check if one exists at all for this auction
    SELECT * INTO v_cycle FROM bid_queue_cycles
    WHERE auction_id = p_auction_id
    ORDER BY cycle_number DESC
    LIMIT 1;

    IF v_cycle IS NULL THEN
      -- First ever raise hand — create cycle 1
      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (p_auction_id, 'open', v_grace_period, 1, NOW())
      RETURNING * INTO v_cycle;
    ELSIF v_cycle.state = 'complete' THEN
      -- Previous cycle done — start new one (increment number)
      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (p_auction_id, 'open', v_grace_period, v_cycle.cycle_number + 1, NOW())
      RETURNING * INTO v_cycle;
    ELSIF v_cycle.state IN ('locked', 'processing') THEN
      -- Current cycle is busy — create NEXT cycle so bidder isn't blocked
      INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
      VALUES (p_auction_id, 'open', v_grace_period, v_cycle.cycle_number + 1, NOW())
      RETURNING * INTO v_cycle;
    END IF;
  END IF;

  -- 4. Check user hasn't already raised hand this cycle
  IF EXISTS (
    SELECT 1 FROM bid_queue
    WHERE auction_id = p_auction_id
      AND bidder_id = p_bidder_id
      AND cycle_number = v_cycle.cycle_number
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'You have already raised your hand this round.',
      'state', 'open'
    );
  END IF;

  -- 5. Calculate position (next available in this cycle)
  SELECT COALESCE(MAX(position), 0) + 1 INTO v_position
  FROM bid_queue
  WHERE auction_id = p_auction_id
    AND cycle_number = v_cycle.cycle_number;

  -- 6. Insert into queue with user's chosen amount
  INSERT INTO bid_queue (auction_id, bidder_id, type, status, cycle_number, position, bid_amount)
  VALUES (p_auction_id, p_bidder_id, 'manual', 'pending', v_cycle.cycle_number, v_position, v_bid_amount);

  RETURN jsonb_build_object(
    'success', true,
    'position', v_position,
    'cycle_number', v_cycle.cycle_number,
    'bid_amount', v_bid_amount,
    'state', 'open'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. process_single_cycle() v2 — Pick LOWEST bid from bucket
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
  v_status_id UUID;
  v_active_bid_status_id UUID;
  v_winning_entry RECORD;
  v_bid_id UUID;
  v_previous_bidder_id UUID;
  v_auction_title TEXT;
  v_snipe_extension INTERVAL := '5 minutes';
  v_auto_position INTEGER;
  v_autobidder RECORD;
  v_auto_bid_amount NUMERIC;
  v_auto_max NUMERIC;
  v_cycle_id UUID;
BEGIN
  -- ============================
  -- PHASE 1: LOCK the cycle
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'locked', locked_at = NOW(), updated_at = NOW()
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND state = 'open'
  RETURNING id INTO v_cycle_id;

  IF v_cycle_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Cycle already processed or not found');
  END IF;

  -- Get auction state
  SELECT a.current_price, a.bid_increment, a.end_time, a.status_id, s.status_name, a.title
  INTO v_current_price, v_min_increment, v_end_time, v_status_id, v_auction_status, v_auction_title
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id
  FOR UPDATE;

  -- Validate auction is still live
  IF v_auction_status NOT IN ('live', 'active') OR NOW() > v_end_time THEN
    UPDATE bid_queue_cycles
    SET state = 'complete', completed_at = NOW(), updated_at = NOW()
    WHERE id = v_cycle_id;

    UPDATE bid_queue
    SET status = 'skipped'
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND status = 'pending';

    RETURN jsonb_build_object('success', false, 'error', 'Auction no longer live');
  END IF;

  -- Get active bid status ID
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;

  -- ============================
  -- PHASE 2: INJECT auto-bidders into queue
  -- ============================
  SELECT COALESCE(MAX(position), 0) INTO v_auto_position
  FROM bid_queue
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

  -- Get current leading bidder (don't auto-bid against yourself)
  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC LIMIT 1;

  FOR v_autobidder IN
    SELECT abs.user_id, abs.max_bid_amount, abs.bid_increment AS user_increment
    FROM auto_bid_settings abs
    WHERE abs.auction_id = p_auction_id
      AND abs.is_active = TRUE
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

    -- Calculate auto-bid amount: current_price + min_increment, rounded to 1k
    v_auto_bid_amount := CEIL((v_current_price + v_min_increment) / 1000.0) * 1000;

    -- Apply ceiling logic
    v_auto_max := v_autobidder.max_bid_amount;

    IF v_auto_bid_amount > v_auto_max THEN
      -- Try using max itself (rounded down to 1k)
      IF v_auto_max > v_current_price THEN
        v_auto_bid_amount := FLOOR(v_auto_max / 1000.0) * 1000;
        IF v_auto_bid_amount <= v_current_price THEN
          -- Can't bid — deactivate and notify
          UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
          WHERE auction_id = p_auction_id AND user_id = v_autobidder.user_id;
          PERFORM create_bid_notification(
            v_autobidder.user_id, 'max_bid_reached',
            'Auto-Bid Limit Reached',
            format('Your auto-bid limit of ₱%s has been reached on %s.',
              to_char(v_auto_max, 'FM999,999,999'), v_auction_title),
            jsonb_build_object('auction_id', p_auction_id, 'action', 'view_auction')
          );
          CONTINUE;
        END IF;
      ELSE
        UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
        WHERE auction_id = p_auction_id AND user_id = v_autobidder.user_id;
        PERFORM create_bid_notification(
          v_autobidder.user_id, 'max_bid_reached',
          'Auto-Bid Limit Reached',
          format('Your auto-bid limit of ₱%s has been reached on %s.',
            to_char(v_auto_max, 'FM999,999,999'), v_auction_title),
          jsonb_build_object('auction_id', p_auction_id, 'action', 'view_auction')
        );
        CONTINUE;
      END IF;
    END IF;

    INSERT INTO bid_queue (auction_id, bidder_id, type, status, cycle_number, position, bid_amount)
    VALUES (p_auction_id, v_autobidder.user_id, 'auto', 'pending', p_cycle_number, v_auto_position, v_auto_bid_amount)
    ON CONFLICT (auction_id, bidder_id, cycle_number) DO NOTHING;

    UPDATE auto_bid_settings SET last_bid_at = NOW(), updated_at = NOW()
    WHERE auction_id = p_auction_id AND user_id = v_autobidder.user_id;
  END LOOP;

  -- ============================
  -- PHASE 3: PROCESS — pick LOWEST bid from the bucket
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'processing', processing_at = NOW(), updated_at = NOW()
  WHERE id = v_cycle_id;

  -- Re-read current price after potential concurrent changes
  SELECT current_price, end_time INTO v_current_price, v_end_time
  FROM auctions WHERE id = p_auction_id;

  -- Find the entry with the LOWEST valid bid amount
  -- Must be > current_price; pick lowest amount, break ties by position (first raised = wins)
  SELECT bq.id, bq.bidder_id, bq.type, bq.position, bq.bid_amount
  INTO v_winning_entry
  FROM bid_queue bq
  WHERE bq.auction_id = p_auction_id
    AND bq.cycle_number = p_cycle_number
    AND bq.status = 'pending'
    AND bq.bid_amount > v_current_price
  ORDER BY bq.bid_amount ASC, bq.position ASC
  LIMIT 1;

  IF v_winning_entry IS NULL THEN
    -- No valid bids in bucket — skip all and complete
    UPDATE bid_queue
    SET status = 'skipped'
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND status = 'pending';

    UPDATE bid_queue_cycles
    SET state = 'complete', completed_at = NOW(), updated_at = NOW()
    WHERE id = v_cycle_id;

    RETURN jsonb_build_object(
      'success', true,
      'cycle_number', p_cycle_number,
      'bids_placed', 0,
      'bids_skipped', (SELECT COUNT(*) FROM bid_queue WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND status = 'skipped')
    );
  END IF;

  -- Get previous leading bidder (for outbid notification)
  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC LIMIT 1;

  -- Execute the winning bid
  UPDATE bid_queue SET status = 'processing' WHERE id = v_winning_entry.id;

  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
  VALUES (
    p_auction_id,
    v_winning_entry.bidder_id,
    v_winning_entry.bid_amount,
    v_winning_entry.type = 'auto',
    v_active_bid_status_id
  ) RETURNING id INTO v_bid_id;

  UPDATE bid_queue SET status = 'executed' WHERE id = v_winning_entry.id;

  -- Mark all other entries as skipped (they didn't win this round)
  UPDATE bid_queue
  SET status = 'skipped'
  WHERE auction_id = p_auction_id
    AND cycle_number = p_cycle_number
    AND status = 'pending'
    AND id != v_winning_entry.id;

  -- Update auction: price, total_bids, snipe guard
  UPDATE auctions
  SET
    current_price = v_winning_entry.bid_amount,
    total_bids = COALESCE(total_bids, 0) + 1,
    end_time = CASE
      WHEN v_end_time - NOW() < v_snipe_extension THEN NOW() + v_snipe_extension
      ELSE end_time
    END,
    updated_at = NOW()
  WHERE id = p_auction_id;

  -- Notify previous bidder of being outbid
  IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != v_winning_entry.bidder_id THEN
    PERFORM create_bid_notification(
      v_previous_bidder_id, 'outbid',
      'You''ve Been Outbid!',
      format('Someone placed a higher bid of ₱%s on %s.',
        to_char(v_winning_entry.bid_amount, 'FM999,999,999'), v_auction_title),
      jsonb_build_object('auction_id', p_auction_id, 'outbid_amount', v_winning_entry.bid_amount, 'action', 'place_bid')
    );
  END IF;

  -- ============================
  -- PHASE 4: COMPLETE the cycle
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'complete', completed_at = NOW(), updated_at = NOW()
  WHERE id = v_cycle_id;

  -- Trigger auto-bid processing for stragglers
  PERFORM enqueue_auto_bid_processing(p_auction_id);

  RETURN jsonb_build_object(
    'success', true,
    'cycle_number', p_cycle_number,
    'bids_placed', 1,
    'winning_bidder', v_winning_entry.bidder_id,
    'winning_amount', v_winning_entry.bid_amount,
    'bids_skipped', (SELECT COUNT(*) FROM bid_queue WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND status = 'skipped')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. process_bid_cycles() — Updated to find cycles by their own ID
-- ============================================================================
CREATE OR REPLACE FUNCTION process_bid_cycles()
RETURNS JSONB AS $$
DECLARE
  v_cycle RECORD;
  v_result JSONB;
  v_processed INTEGER := 0;
BEGIN
  FOR v_cycle IN
    SELECT * FROM bid_queue_cycles
    WHERE state = 'open'
      AND NOW() >= opened_at + (grace_period_seconds * INTERVAL '1 second')
    FOR UPDATE SKIP LOCKED
  LOOP
    v_result := process_single_cycle(v_cycle.auction_id, v_cycle.cycle_number);
    v_processed := v_processed + 1;
  END LOOP;

  RETURN jsonb_build_object('processed', v_processed);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. get_queue_status() v2 — Returns both current (active) and next cycle
-- ============================================================================
CREATE OR REPLACE FUNCTION get_queue_status(p_auction_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_cycle RECORD;
  v_queue JSONB;
  v_remaining_ms INTEGER;
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
        'remaining_ms', 0
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
      'bid_amount', bq.bid_amount
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

  RETURN jsonb_build_object(
    'state', v_cycle.state,
    'cycle_number', v_cycle.cycle_number,
    'queue', v_queue,
    'remaining_ms', v_remaining_ms,
    'opened_at', v_cycle.opened_at,
    'locked_at', v_cycle.locked_at,
    'processing_at', v_cycle.processing_at,
    'completed_at', v_cycle.completed_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. get_seller_queue_status() — Detailed view for seller dashboard
-- ============================================================================
CREATE OR REPLACE FUNCTION get_seller_queue_status(p_auction_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_cycles JSONB;
  v_current RECORD;
BEGIN
  -- Get all recent cycles (last 10) with full queue details including bidder names
  SELECT COALESCE(jsonb_agg(cycle_data ORDER BY (cycle_data->>'cycle_number')::int DESC), '[]'::jsonb)
  INTO v_cycles
  FROM (
    SELECT jsonb_build_object(
      'id', c.id,
      'cycle_number', c.cycle_number,
      'state', c.state,
      'grace_period_seconds', c.grace_period_seconds,
      'opened_at', c.opened_at,
      'locked_at', c.locked_at,
      'processing_at', c.processing_at,
      'completed_at', c.completed_at,
      'queue', COALESCE((
        SELECT jsonb_agg(
          jsonb_build_object(
            'id', bq.id,
            'bidder_id', bq.bidder_id,
            'bidder_name', COALESCE(u.display_name, u.username, 'Anonymous'),
            'type', bq.type,
            'status', bq.status,
            'position', bq.position,
            'bid_amount', bq.bid_amount,
            'created_at', bq.created_at
          ) ORDER BY bq.position ASC
        )
        FROM bid_queue bq
        LEFT JOIN users u ON u.id = bq.bidder_id
        WHERE bq.auction_id = c.auction_id AND bq.cycle_number = c.cycle_number
      ), '[]'::jsonb)
    ) AS cycle_data
    FROM bid_queue_cycles c
    WHERE c.auction_id = p_auction_id
    ORDER BY c.cycle_number DESC
    LIMIT 10
  ) sub;

  RETURN jsonb_build_object(
    'auction_id', p_auction_id,
    'cycles', v_cycles,
    'total_cycles', (SELECT COUNT(*) FROM bid_queue_cycles WHERE auction_id = p_auction_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
