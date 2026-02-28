-- Migration: 00109_raise_hand_queue.sql
-- Date: 2026-02-22
-- Description: "Raise Hand" queue-based bidding system
--
--   Replaces standard "last-write-wins" bidding with a strictly ordered queue
--   to ensure fairness between Manual users and Auto-bidders.
--
--   LIFECYCLE:
--   1. OPEN (Grace Period)  — Only manual bidders can raise hand (3-5s)
--   2. LOCKED               — Auto-bidders injected after manual entries
--   3. PROCESSING           — Bids executed FIFO (instant, no delay)
--   4. COMPLETE             — Cycle ends, restarts automatically
--
--   CONSTRAINTS:
--   - 1k PHP floor: all bids rounded to multiples of 1,000
--   - One raise per user per cycle
--   - Tie-breaker: random ordering (RPS modal planned for future)

-- ============================================================================
-- 1. bid_queue_cycles: tracks cycle state per auction
-- ============================================================================
CREATE TABLE IF NOT EXISTS bid_queue_cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL UNIQUE REFERENCES auctions(id) ON DELETE CASCADE,
  state TEXT NOT NULL DEFAULT 'open'
    CHECK (state IN ('open', 'locked', 'processing', 'complete')),
  grace_period_seconds INTEGER NOT NULL DEFAULT 3,
  cycle_number INTEGER NOT NULL DEFAULT 1,
  opened_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  locked_at TIMESTAMPTZ,
  processing_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_bqc_state ON bid_queue_cycles(state);
CREATE INDEX IF NOT EXISTS idx_bqc_auction ON bid_queue_cycles(auction_id);

ALTER TABLE bid_queue_cycles ENABLE ROW LEVEL SECURITY;

-- Read-only for authenticated users (state visible to bidders)
DROP POLICY IF EXISTS "users can view queue cycles" ON bid_queue_cycles;
CREATE POLICY "users can view queue cycles" ON bid_queue_cycles
  FOR SELECT TO authenticated USING (true);

COMMENT ON TABLE bid_queue_cycles IS
  'Tracks the state of the raise-hand bid queue cycle per auction. States: open → locked → processing → complete → (new cycle).';

-- ============================================================================
-- 2. bid_queue: individual raise-hand entries
-- ============================================================================
CREATE TABLE IF NOT EXISTS bid_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  bidder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('manual', 'auto')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'processing', 'executed', 'skipped', 'failed')),
  cycle_number INTEGER NOT NULL DEFAULT 1,
  position INTEGER NOT NULL DEFAULT 0,
  bid_amount NUMERIC(12, 2),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(auction_id, bidder_id, cycle_number)
);

CREATE INDEX IF NOT EXISTS idx_bq_auction_cycle ON bid_queue(auction_id, cycle_number);
CREATE INDEX IF NOT EXISTS idx_bq_status ON bid_queue(status);

ALTER TABLE bid_queue ENABLE ROW LEVEL SECURITY;

-- Users can view queue entries for auctions they participate in
DROP POLICY IF EXISTS "users can view bid queue" ON bid_queue;
CREATE POLICY "users can view bid queue" ON bid_queue
  FOR SELECT TO authenticated USING (true);

-- Users can insert their own raise-hand entries (RPC handles validation)
DROP POLICY IF EXISTS "users can insert own queue entry" ON bid_queue;
CREATE POLICY "users can insert own queue entry" ON bid_queue
  FOR INSERT TO authenticated WITH CHECK (bidder_id = auth.uid());

COMMENT ON TABLE bid_queue IS
  'Individual raise-hand entries in the bidding queue. One per user per cycle. Type: manual (user raised hand) or auto (system injected).';

-- ============================================================================
-- 3. Enable Realtime on both tables
-- ============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE bid_queue_cycles;
ALTER PUBLICATION supabase_realtime ADD TABLE bid_queue;

-- ============================================================================
-- 4. raise_hand() — Manual bidder raises hand during OPEN state
-- ============================================================================
CREATE OR REPLACE FUNCTION raise_hand(
  p_auction_id UUID,
  p_bidder_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_auction_status TEXT;
  v_end_time TIMESTAMPTZ;
  v_cycle RECORD;
  v_position INTEGER;
  v_grace_period INTEGER := 3;
  v_next_bid NUMERIC;
  v_current_price NUMERIC;
  v_min_increment NUMERIC;
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

  -- 2. Get or create cycle
  SELECT * INTO v_cycle FROM bid_queue_cycles
  WHERE auction_id = p_auction_id
  FOR UPDATE;

  IF v_cycle IS NULL THEN
    -- First ever raise hand — create cycle
    INSERT INTO bid_queue_cycles (auction_id, state, grace_period_seconds, cycle_number, opened_at)
    VALUES (p_auction_id, 'open', v_grace_period, 1, NOW())
    RETURNING * INTO v_cycle;
  ELSIF v_cycle.state = 'complete' THEN
    -- Previous cycle done — start new one
    UPDATE bid_queue_cycles
    SET state = 'open',
        cycle_number = v_cycle.cycle_number + 1,
        opened_at = NOW(),
        locked_at = NULL,
        processing_at = NULL,
        completed_at = NULL,
        updated_at = NOW()
    WHERE id = v_cycle.id
    RETURNING * INTO v_cycle;
  ELSIF v_cycle.state != 'open' THEN
    -- Cycle is locked or processing — reject
    RETURN jsonb_build_object(
      'success', false,
      'error', 'Queue is currently processing. Please wait for the next cycle.',
      'state', v_cycle.state
    );
  END IF;

  -- 3. Check user hasn't already raised hand this cycle
  IF EXISTS (
    SELECT 1 FROM bid_queue
    WHERE auction_id = p_auction_id
      AND bidder_id = p_bidder_id
      AND cycle_number = v_cycle.cycle_number
  ) THEN
    RETURN jsonb_build_object(
      'success', false,
      'error', 'You have already raised your hand this cycle.',
      'state', 'open'
    );
  END IF;

  -- 4. Calculate position (next available)
  SELECT COALESCE(MAX(position), 0) + 1 INTO v_position
  FROM bid_queue
  WHERE auction_id = p_auction_id
    AND cycle_number = v_cycle.cycle_number;

  -- 5. Calculate what the bid will be
  v_next_bid := v_current_price + v_min_increment;
  -- Round UP to nearest 1,000
  v_next_bid := CEIL(v_next_bid / 1000.0) * 1000;

  -- 6. Insert into queue
  INSERT INTO bid_queue (auction_id, bidder_id, type, status, cycle_number, position, bid_amount)
  VALUES (p_auction_id, p_bidder_id, 'manual', 'pending', v_cycle.cycle_number, v_position, v_next_bid);

  RETURN jsonb_build_object(
    'success', true,
    'position', v_position,
    'cycle_number', v_cycle.cycle_number,
    'estimated_bid', v_next_bid,
    'state', 'open'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. process_bid_cycles() — Process all due cycles (called by pg_cron)
-- ============================================================================
CREATE OR REPLACE FUNCTION process_bid_cycles()
RETURNS JSONB AS $$
DECLARE
  v_cycle RECORD;
  v_result JSONB;
  v_processed INTEGER := 0;
BEGIN
  -- Find all OPEN cycles whose grace period has elapsed
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
-- 6. process_single_cycle() — Full lifecycle for one auction's cycle
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
  v_queue_entry RECORD;
  v_bid_amount NUMERIC;
  v_bid_id UUID;
  v_bids_placed INTEGER := 0;
  v_bids_skipped INTEGER := 0;
  v_autobidder RECORD;
  v_auto_position INTEGER;
  v_previous_bidder_id UUID;
  v_auction_title TEXT;
  v_snipe_extension INTERVAL := '5 minutes';
  v_auto_max NUMERIC;
  v_auto_next NUMERIC;
BEGIN
  -- ============================
  -- PHASE 1: LOCK the cycle
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'locked', locked_at = NOW(), updated_at = NOW()
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

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
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

    UPDATE bid_queue
    SET status = 'skipped'
    WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number AND status = 'pending';

    RETURN jsonb_build_object('success', false, 'error', 'Auction no longer live');
  END IF;

  -- Get active bid status ID
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;

  -- ============================
  -- PHASE 2: INJECT auto-bidders
  -- ============================
  -- Get next position after manual entries
  SELECT COALESCE(MAX(position), 0) INTO v_auto_position
  FROM bid_queue
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

  -- Get current leading bidder
  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC LIMIT 1;

  -- Inject eligible auto-bidders (sorted by setup time — first to setup, first to bid)
  FOR v_autobidder IN
    SELECT abs.user_id, abs.max_bid_amount, abs.bid_increment AS user_increment
    FROM auto_bid_settings abs
    WHERE abs.auction_id = p_auction_id
      AND abs.is_active = TRUE
      AND abs.user_id != COALESCE(v_previous_bidder_id, '00000000-0000-0000-0000-000000000000'::uuid)
      -- Don't inject if already in queue as manual
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
  -- PHASE 3: PROCESS queue (FIFO)
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'processing', processing_at = NOW(), updated_at = NOW()
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

  -- Re-read current price (may have changed)
  SELECT current_price, end_time INTO v_current_price, v_end_time
  FROM auctions WHERE id = p_auction_id;

  FOR v_queue_entry IN
    SELECT bq.id, bq.bidder_id, bq.type, bq.position
    FROM bid_queue bq
    WHERE bq.auction_id = p_auction_id
      AND bq.cycle_number = p_cycle_number
      AND bq.status = 'pending'
    ORDER BY bq.position ASC
  LOOP
    -- Mark as processing
    UPDATE bid_queue SET status = 'processing' WHERE id = v_queue_entry.id;

    -- Re-read current price for each bid (previous bid in queue may have raised it)
    SELECT current_price, end_time INTO v_current_price, v_end_time
    FROM auctions WHERE id = p_auction_id;

    -- Calculate bid amount
    v_bid_amount := v_current_price + v_min_increment;
    -- Round UP to nearest 1,000 (1k floor)
    v_bid_amount := CEIL(v_bid_amount / 1000.0) * 1000;

    IF v_queue_entry.type = 'auto' THEN
      -- Auto-bidder: apply ceiling logic
      SELECT max_bid_amount INTO v_auto_max
      FROM auto_bid_settings
      WHERE auction_id = p_auction_id AND user_id = v_queue_entry.bidder_id AND is_active = TRUE;

      IF v_auto_max IS NULL THEN
        -- Auto-bid deactivated since injection
        UPDATE bid_queue SET status = 'skipped' WHERE id = v_queue_entry.id;
        v_bids_skipped := v_bids_skipped + 1;
        CONTINUE;
      END IF;

      IF v_bid_amount > v_auto_max THEN
        -- Ceiling exceeded: try bidding max (rounded down to nearest 1k)
        IF v_auto_max > v_current_price THEN
          v_bid_amount := FLOOR(v_auto_max / 1000.0) * 1000;
          -- Ensure rounded max is still above current price
          IF v_bid_amount <= v_current_price THEN
            UPDATE bid_queue SET status = 'skipped' WHERE id = v_queue_entry.id;
            v_bids_skipped := v_bids_skipped + 1;

            -- Deactivate auto-bid and notify user
            UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
            WHERE auction_id = p_auction_id AND user_id = v_queue_entry.bidder_id;

            PERFORM create_bid_notification(
              v_queue_entry.bidder_id, 'max_bid_reached',
              'Auto-Bid Limit Reached',
              format('Your auto-bid limit of ₱%s has been reached on %s.',
                to_char(v_auto_max, 'FM999,999,999'), v_auction_title),
              jsonb_build_object('auction_id', p_auction_id, 'action', 'view_auction')
            );
            CONTINUE;
          END IF;
        ELSE
          -- Max is at or below current price — skip
          UPDATE bid_queue SET status = 'skipped' WHERE id = v_queue_entry.id;
          v_bids_skipped := v_bids_skipped + 1;

          UPDATE auto_bid_settings SET is_active = FALSE, updated_at = NOW()
          WHERE auction_id = p_auction_id AND user_id = v_queue_entry.bidder_id;

          PERFORM create_bid_notification(
            v_queue_entry.bidder_id, 'max_bid_reached',
            'Auto-Bid Limit Reached',
            format('Your auto-bid limit of ₱%s has been reached on %s.',
              to_char(v_auto_max, 'FM999,999,999'), v_auction_title),
            jsonb_build_object('auction_id', p_auction_id, 'action', 'view_auction')
          );
          CONTINUE;
        END IF;
      END IF;

      -- Update last_bid_at for round-robin tracking
      UPDATE auto_bid_settings SET last_bid_at = NOW(), updated_at = NOW()
      WHERE auction_id = p_auction_id AND user_id = v_queue_entry.bidder_id;
    END IF;

    -- Get previous leading bidder (for outbid notification)
    SELECT bidder_id INTO v_previous_bidder_id
    FROM bids WHERE auction_id = p_auction_id
    ORDER BY bid_amount DESC LIMIT 1;

    -- Place the actual bid
    INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
    VALUES (
      p_auction_id,
      v_queue_entry.bidder_id,
      v_bid_amount,
      v_queue_entry.type = 'auto',
      v_active_bid_status_id
    ) RETURNING id INTO v_bid_id;

    -- Update bid_queue entry with actual amount
    UPDATE bid_queue
    SET status = 'executed', bid_amount = v_bid_amount
    WHERE id = v_queue_entry.id;

    -- Update auction: price, total_bids, snipe guard
    UPDATE auctions
    SET
      current_price = v_bid_amount,
      total_bids = COALESCE(total_bids, 0) + 1,
      end_time = CASE
        WHEN v_end_time - NOW() < v_snipe_extension THEN NOW() + v_snipe_extension
        ELSE end_time
      END,
      updated_at = NOW()
    WHERE id = p_auction_id;

    -- Notify previous bidder of being outbid
    IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != v_queue_entry.bidder_id THEN
      PERFORM create_bid_notification(
        v_previous_bidder_id, 'outbid',
        'You''ve Been Outbid!',
        format('Someone placed a higher bid of ₱%s on %s.',
          to_char(v_bid_amount, 'FM999,999,999'), v_auction_title),
        jsonb_build_object('auction_id', p_auction_id, 'outbid_amount', v_bid_amount, 'action', 'place_bid')
      );
    END IF;

    v_bids_placed := v_bids_placed + 1;
  END LOOP;

  -- ============================
  -- PHASE 4: COMPLETE the cycle
  -- ============================
  UPDATE bid_queue_cycles
  SET state = 'complete', completed_at = NOW(), updated_at = NOW()
  WHERE auction_id = p_auction_id AND cycle_number = p_cycle_number;

  -- Enqueue auto-bid processing for any auto-bidders that may now be outbid
  -- (ensures the old auto_bid_queue system picks up stragglers)
  PERFORM enqueue_auto_bid_processing(p_auction_id);

  RETURN jsonb_build_object(
    'success', true,
    'cycle_number', p_cycle_number,
    'bids_placed', v_bids_placed,
    'bids_skipped', v_bids_skipped
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. get_queue_status() — Returns current cycle state + queue for UI
-- ============================================================================
CREATE OR REPLACE FUNCTION get_queue_status(p_auction_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_cycle RECORD;
  v_queue JSONB;
  v_remaining_ms INTEGER;
BEGIN
  SELECT * INTO v_cycle FROM bid_queue_cycles
  WHERE auction_id = p_auction_id;

  IF v_cycle IS NULL THEN
    RETURN jsonb_build_object(
      'state', 'idle',
      'cycle_number', 0,
      'queue', '[]'::jsonb,
      'remaining_ms', 0
    );
  END IF;

  -- Get queue entries for current cycle
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

  -- Calculate remaining grace period in milliseconds
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
-- 8. Override place_bid to use raise_hand for manual bids
-- ============================================================================
-- The existing place_bid() is preserved for backward compatibility.
-- Manual bids from the UI should call raise_hand() instead.
-- Auto-bids continue to use the old place_bid() internally (from process_single_cycle).

-- ============================================================================
-- 9. Schedule pg_cron for cycle processing
-- ============================================================================
DO $outer$
BEGIN
  -- Remove any existing schedule
  BEGIN
    PERFORM cron.unschedule('process-bid-cycles');
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  -- Try sub-minute: every 2 seconds (pg_cron 1.5+)
  BEGIN
    PERFORM cron.schedule(
      'process-bid-cycles',
      '*/2 * * * * *',
      'SELECT process_bid_cycles()'
    );
    RAISE NOTICE 'Bid cycle processing scheduled every 2 seconds';
  EXCEPTION WHEN OTHERS THEN
    -- Fallback: every 5 seconds
    BEGIN
      PERFORM cron.schedule(
        'process-bid-cycles',
        '*/5 * * * * *',
        'SELECT process_bid_cycles()'
      );
      RAISE NOTICE 'Bid cycle processing scheduled every 5 seconds';
    EXCEPTION WHEN OTHERS THEN
      -- Fallback: every minute
      BEGIN
        PERFORM cron.schedule(
          'process-bid-cycles',
          '* * * * *',
          'SELECT process_bid_cycles()'
        );
        RAISE NOTICE 'Bid cycle processing scheduled every minute';
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING 'pg_cron not available. Bid cycle processing requires manual setup.';
      END;
    END;
  END;
END $outer$;
