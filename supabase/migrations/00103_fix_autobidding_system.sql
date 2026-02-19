-- Migration: Complete Autobidding System Overhaul
-- Date: 2026-02-18
-- Description: 
--   1. Add bid_increment column to auto_bid_settings (per-user custom increment)
--   2. Rewrite process_auto_bids with proper proxy bidding algorithm (Copart/eBay style)
--      - No self-bidding: uses iterative loop instead of pre-fetched cursor
--      - Bid max when next increment exceeds max (don't waste remainder)
--      - Deactivate auto-bid when max is exhausted
--   3. Add outbid notification creation (in-app via notifications table)
--   4. Add auto-bid exhausted notification
--   5. Add helper function for saving auto-bid settings with increment
--   6. Update place_bid to pass user-specific increment to process_auto_bids

-- ============================================================================
-- 1. Add bid_increment column to auto_bid_settings
-- ============================================================================
ALTER TABLE auto_bid_settings 
  ADD COLUMN IF NOT EXISTS bid_increment NUMERIC(12, 2);

-- Default existing rows to null (will fall back to auction's bid_increment)
COMMENT ON COLUMN auto_bid_settings.bid_increment IS 
  'Per-user custom bid increment. NULL means use auction default bid_increment.';

-- ============================================================================
-- 2. Helper: Create notification for a user
-- ============================================================================
CREATE OR REPLACE FUNCTION create_bid_notification(
  p_user_id UUID,
  p_type_name TEXT,
  p_title TEXT,
  p_message TEXT,
  p_data JSONB DEFAULT NULL
) RETURNS VOID AS $$
DECLARE
  v_type_id UUID;
BEGIN
  SELECT id INTO v_type_id FROM notification_types WHERE type_name = p_type_name LIMIT 1;
  
  -- Fallback: if specific type not found, try 'outbid' for bid-related notifications
  IF v_type_id IS NULL THEN
    SELECT id INTO v_type_id FROM notification_types WHERE type_name = 'outbid' LIMIT 1;
  END IF;

  IF v_type_id IS NULL THEN
    RAISE WARNING 'Notification type % not found, skipping notification', p_type_name;
    RETURN;
  END IF;

  INSERT INTO notifications (user_id, type_id, title, message, data, is_read)
  VALUES (p_user_id, v_type_id, p_title, p_message, COALESCE(p_data, '{}'::jsonb), FALSE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 3. Rewrite process_auto_bids with proxy bidding algorithm
-- ============================================================================
CREATE OR REPLACE FUNCTION process_auto_bids(
  p_auction_id UUID,
  p_current_bidder_id UUID,
  p_current_price NUMERIC,
  p_increment NUMERIC  -- auction's default min increment (fallback)
) RETURNS VOID AS $$
DECLARE
  v_active_bid_status_id UUID;
  v_top_autobidder RECORD;
  v_second_autobidder RECORD;
  v_next_bid_amount NUMERIC;
  v_effective_increment NUMERIC;
  v_loop_count INT := 0;
  v_max_loops INT := 500; -- Safety: prevent infinite loops
  v_auction_title TEXT;
  v_has_competing_autobids BOOLEAN := TRUE;
BEGIN
  -- 1. Get the 'active' status ID
  SELECT id INTO v_active_bid_status_id 
  FROM bid_statuses WHERE status_name = 'active' LIMIT 1;
  
  IF v_active_bid_status_id IS NULL THEN
    RAISE WARNING 'Active bid status not found during auto-bid processing';
    RETURN;
  END IF;

  -- Get auction title for notification messages
  SELECT COALESCE(
    (SELECT title FROM vehicles v JOIN auctions a ON a.vehicle_id = v.id WHERE a.id = p_auction_id),
    'this auction'
  ) INTO v_auction_title;

  -- ========================================================================
  -- PROXY BIDDING ALGORITHM (Copart/eBay style)
  -- 
  -- Instead of iterating through all autobidders in a pre-fetched cursor,
  -- we repeatedly find the TOP autobidder who can beat the current price.
  -- This naturally handles:
  --   - No self-bidding (we exclude current winning bidder each iteration)
  --   - Competing autobidders outbidding each other
  --   - Bid-to-max when increment exceeds remaining budget
  -- ========================================================================
  
  WHILE v_has_competing_autobids AND v_loop_count < v_max_loops LOOP
    v_loop_count := v_loop_count + 1;
    
    -- Find the highest-max autobidder who is NOT the current winning bidder
    SELECT user_id, max_bid_amount, COALESCE(bid_increment, p_increment) AS effective_increment
    INTO v_top_autobidder
    FROM auto_bid_settings
    WHERE auction_id = p_auction_id
      AND is_active = TRUE
      AND user_id != p_current_bidder_id  -- Never bid against yourself
      AND max_bid_amount > p_current_price  -- Must be able to beat current price
    ORDER BY max_bid_amount DESC, created_at ASC  -- Highest max wins, FIFO tiebreak
    LIMIT 1;

    -- No eligible autobidder found → exit
    IF v_top_autobidder IS NULL THEN
      v_has_competing_autobids := FALSE;
      EXIT;
    END IF;

    -- Use autobidder's custom increment, but never below auction minimum
    v_effective_increment := GREATEST(v_top_autobidder.effective_increment, p_increment);

    -- Calculate next bid amount
    v_next_bid_amount := p_current_price + v_effective_increment;

    -- Check if the autobidder can afford the full increment
    IF v_next_bid_amount > v_top_autobidder.max_bid_amount THEN
      -- Cannot afford full increment: bid their max instead (don't waste remainder)
      -- But only if max > current price (already checked above)
      v_next_bid_amount := v_top_autobidder.max_bid_amount;

      -- Ensure max is still at least current + auction min increment
      IF v_next_bid_amount < p_current_price + p_increment THEN
        -- Cannot even meet minimum increment. Deactivate and notify.
        UPDATE auto_bid_settings 
        SET is_active = FALSE, updated_at = NOW()
        WHERE auction_id = p_auction_id AND user_id = v_top_autobidder.user_id;

        PERFORM create_bid_notification(
          v_top_autobidder.user_id,
          'outbid',
          'Auto-Bid Max Reached',
          format('Your auto-bid maximum of ₱%s has been reached on %s. The current bid is ₱%s. Increase your maximum to stay in the auction.',
            to_char(v_top_autobidder.max_bid_amount, 'FM999,999,999'),
            v_auction_title,
            to_char(p_current_price, 'FM999,999,999')
          ),
          jsonb_build_object(
            'auction_id', p_auction_id,
            'max_bid_amount', v_top_autobidder.max_bid_amount,
            'current_price', p_current_price,
            'action', 'increase_max_bid'
          )
        );

        -- Continue loop to check other autobidders
        CONTINUE;
      END IF;
    END IF;

    -- Now check: is there a SECOND autobidder competing?
    -- In proxy bidding, the winner only needs to bid enough to beat the second-highest
    SELECT user_id, max_bid_amount, COALESCE(bid_increment, p_increment) AS effective_increment
    INTO v_second_autobidder
    FROM auto_bid_settings
    WHERE auction_id = p_auction_id
      AND is_active = TRUE
      AND user_id != p_current_bidder_id
      AND user_id != v_top_autobidder.user_id
      AND max_bid_amount > p_current_price
    ORDER BY max_bid_amount DESC, created_at ASC
    LIMIT 1;

    IF v_second_autobidder IS NOT NULL 
       AND v_second_autobidder.max_bid_amount >= p_current_price + p_increment THEN
      -- Two autobidders competing: they bid against each other
      -- The top autobidder needs to bid just one increment above second's max
      -- (or their own max, whichever is lower)
      
      -- Second autobidder bids their max (or one increment above current)
      DECLARE
        v_second_bid NUMERIC;
        v_second_effective_inc NUMERIC;
      BEGIN
        v_second_effective_inc := GREATEST(v_second_autobidder.effective_increment, p_increment);
        v_second_bid := LEAST(
          v_second_autobidder.max_bid_amount,
          GREATEST(p_current_price + v_second_effective_inc, p_current_price + p_increment)
        );

        -- Ensure second bid meets minimum increment
        IF v_second_bid >= p_current_price + p_increment THEN
          -- Place second autobidder's bid
          INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
          VALUES (p_auction_id, v_second_autobidder.user_id, v_second_bid, TRUE, v_active_bid_status_id);

          UPDATE auctions SET current_price = v_second_bid, total_bids = total_bids + 1
          WHERE id = p_auction_id;

          p_current_price := v_second_bid;
          p_current_bidder_id := v_second_autobidder.user_id;

          -- Check if second autobidder hit their max
          IF v_second_bid >= v_second_autobidder.max_bid_amount THEN
            UPDATE auto_bid_settings 
            SET is_active = FALSE, updated_at = NOW()
            WHERE auction_id = p_auction_id AND user_id = v_second_autobidder.user_id;

            PERFORM create_bid_notification(
              v_second_autobidder.user_id,
              'outbid',
              'Auto-Bid Max Reached',
              format('Your auto-bid maximum of ₱%s has been reached on %s. Increase your maximum to stay in the auction.',
                to_char(v_second_autobidder.max_bid_amount, 'FM999,999,999'),
                v_auction_title
              ),
              jsonb_build_object(
                'auction_id', p_auction_id,
                'max_bid_amount', v_second_autobidder.max_bid_amount,
                'current_price', v_second_bid,
                'action', 'increase_max_bid'
              )
            );
          END IF;

          -- Now top autobidder responds: bid one increment above
          v_next_bid_amount := p_current_price + GREATEST(v_top_autobidder.effective_increment, p_increment);
          IF v_next_bid_amount > v_top_autobidder.max_bid_amount THEN
            -- Bid max if can't afford full increment but can still beat current
            IF v_top_autobidder.max_bid_amount > p_current_price AND 
               v_top_autobidder.max_bid_amount >= p_current_price + p_increment THEN
              v_next_bid_amount := v_top_autobidder.max_bid_amount;
            ELSIF v_top_autobidder.max_bid_amount <= p_current_price THEN
              -- Top can no longer beat second. Deactivate.
              UPDATE auto_bid_settings 
              SET is_active = FALSE, updated_at = NOW()
              WHERE auction_id = p_auction_id AND user_id = v_top_autobidder.user_id;

              PERFORM create_bid_notification(
                v_top_autobidder.user_id,
                'outbid',
                'Auto-Bid Max Reached',
                format('Your auto-bid maximum of ₱%s has been reached on %s. You have been outbid at ₱%s.',
                  to_char(v_top_autobidder.max_bid_amount, 'FM999,999,999'),
                  v_auction_title,
                  to_char(p_current_price, 'FM999,999,999')
                ),
                jsonb_build_object(
                  'auction_id', p_auction_id,
                  'max_bid_amount', v_top_autobidder.max_bid_amount,
                  'current_price', p_current_price,
                  'action', 'increase_max_bid'
                )
              );
              -- Loop continues to find any other autobidders
              CONTINUE;
            ELSE
              -- Can't meet minimum increment above current price
              UPDATE auto_bid_settings 
              SET is_active = FALSE, updated_at = NOW()
              WHERE auction_id = p_auction_id AND user_id = v_top_autobidder.user_id;

              PERFORM create_bid_notification(
                v_top_autobidder.user_id,
                'outbid',
                'Auto-Bid Max Reached',
                format('Your auto-bid maximum of ₱%s has been reached on %s. Current bid: ₱%s.',
                  to_char(v_top_autobidder.max_bid_amount, 'FM999,999,999'),
                  v_auction_title,
                  to_char(p_current_price, 'FM999,999,999')
                ),
                jsonb_build_object(
                  'auction_id', p_auction_id,
                  'max_bid_amount', v_top_autobidder.max_bid_amount,
                  'current_price', p_current_price,
                  'action', 'increase_max_bid'
                )
              );
              CONTINUE;
            END IF;
          END IF;
        END IF;
      END;
    END IF;

    -- Place the top autobidder's bid
    INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
    VALUES (p_auction_id, v_top_autobidder.user_id, v_next_bid_amount, TRUE, v_active_bid_status_id);

    UPDATE auctions SET current_price = v_next_bid_amount, total_bids = total_bids + 1
    WHERE id = p_auction_id;

    -- Notify the previous bidder they've been outbid
    IF p_current_bidder_id IS NOT NULL AND p_current_bidder_id != v_top_autobidder.user_id THEN
      PERFORM create_bid_notification(
        p_current_bidder_id,
        'outbid',
        'You''ve Been Outbid!',
        format('Someone placed a higher bid of ₱%s on %s.',
          to_char(v_next_bid_amount, 'FM999,999,999'),
          v_auction_title
        ),
        jsonb_build_object(
          'auction_id', p_auction_id,
          'outbid_amount', v_next_bid_amount,
          'action', 'place_bid'
        )
      );
    END IF;

    -- Update loop tracking variables
    p_current_price := v_next_bid_amount;
    p_current_bidder_id := v_top_autobidder.user_id;

    -- Check if top autobidder hit their max
    IF v_next_bid_amount >= v_top_autobidder.max_bid_amount THEN
      UPDATE auto_bid_settings 
      SET is_active = FALSE, updated_at = NOW()
      WHERE auction_id = p_auction_id AND user_id = v_top_autobidder.user_id;

      -- Don't notify yet - they're currently winning. 
      -- They'll be notified if/when someone outbids them.
    END IF;

    -- Check if there are any more competing autobidders
    -- (this prevents unnecessary loop iterations)
    IF NOT EXISTS (
      SELECT 1 FROM auto_bid_settings
      WHERE auction_id = p_auction_id
        AND is_active = TRUE
        AND user_id != p_current_bidder_id
        AND max_bid_amount > p_current_price
    ) THEN
      v_has_competing_autobids := FALSE;
    END IF;

  END LOOP;

  IF v_loop_count >= v_max_loops THEN
    RAISE WARNING 'Auto-bid loop hit maximum iterations (%) for auction %', v_max_loops, p_auction_id;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 4. Update place_bid to also notify the previous leading bidder
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

  -- 7. Insert Bid with STATUS_ID
  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
  VALUES (p_auction_id, p_bidder_id, p_amount, p_is_auto_bid, v_active_bid_status_id)
  RETURNING id INTO v_bid_id;

  -- 8. Update Auction (Current Price & Total Bids)
  UPDATE auctions
  SET 
    current_price = p_amount,
    total_bids = COALESCE(total_bids, 0) + 1,
    -- Snipe Guard: Extend time if within last 5 minutes
    end_time = CASE 
      WHEN v_end_time - NOW() < v_snipe_extension THEN NOW() + v_snipe_extension
      ELSE end_time
    END
  WHERE id = p_auction_id;

  -- 8b. Notify previous leading bidder they've been outbid (only if different user)
  IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != p_bidder_id THEN
    -- Get auction title for notification
    SELECT COALESCE(
      (SELECT title FROM vehicles v JOIN auctions a ON a.vehicle_id = v.id WHERE a.id = p_auction_id),
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

  -- 9. Trigger Auto-bids
  PERFORM process_auto_bids(p_auction_id, p_bidder_id, p_amount, v_min_increment);

  RETURN jsonb_build_object('success', true, 'bid_id', v_bid_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 5. RPC to save/update auto-bid settings (called from client)
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

  RETURN jsonb_build_object('success', true, 'settings_id', v_settings_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 6. RPC to get auto-bid settings for a user on an auction
-- ============================================================================
CREATE OR REPLACE FUNCTION get_auto_bid_settings(
  p_auction_id UUID,
  p_user_id UUID
) RETURNS JSONB AS $$
DECLARE
  v_settings RECORD;
BEGIN
  SELECT id, max_bid_amount, bid_increment, is_active, created_at, updated_at
  INTO v_settings
  FROM auto_bid_settings
  WHERE auction_id = p_auction_id AND user_id = p_user_id;

  IF v_settings IS NULL THEN
    RETURN jsonb_build_object('exists', false);
  END IF;

  RETURN jsonb_build_object(
    'exists', true,
    'id', v_settings.id,
    'max_bid_amount', v_settings.max_bid_amount,
    'bid_increment', v_settings.bid_increment,
    'is_active', v_settings.is_active,
    'created_at', v_settings.created_at,
    'updated_at', v_settings.updated_at
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 7. Enable realtime for notifications table
-- ============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
