-- Fix: Remove inline total_bids/current_price updates from place_bid and process_auto_bids
-- The trigger update_auction_current_price (migration 00052) already handles these correctly
-- via COUNT(*) and MAX(bid_amount). Having both causes double counting.

-- 1. Fix place_bid: keep only snipe guard in the UPDATE
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
BEGIN
  -- Lock the auction row for update to prevent race conditions
  SELECT current_price, bid_increment, end_time, status_id
  INTO v_current_price, v_min_increment, v_end_time, v_status_id
  FROM auctions
  WHERE id = p_auction_id
  FOR UPDATE;

  -- Get status name
  SELECT status_name INTO v_auction_status
  FROM auction_statuses
  WHERE id = v_status_id;

  -- Validation: Auction must be live
  IF v_auction_status != 'live' AND v_auction_status != 'active' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction is not live');
  END IF;

  -- Validation: Auction must not be ended
  IF NOW() > v_end_time THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction has ended');
  END IF;

  -- Validation: Bid amount
  IF p_amount < (v_current_price + v_min_increment) THEN
     RETURN jsonb_build_object('success', false, 'error', 'Bid amount too low. Minimum required: ' || (v_current_price + v_min_increment));
  END IF;

  -- Insert Bid (trigger update_auction_current_price handles total_bids and current_price)
  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid)
  VALUES (p_auction_id, p_bidder_id, p_amount, p_is_auto_bid)
  RETURNING id INTO v_bid_id;

  -- Snipe Guard only: Extend time if within last 5 minutes
  IF v_end_time - NOW() < v_snipe_extension THEN
    UPDATE auctions
    SET end_time = NOW() + v_snipe_extension
    WHERE id = p_auction_id;
  END IF;

  -- Trigger Auto-bids
  PERFORM process_auto_bids(p_auction_id, p_bidder_id, p_amount, v_min_increment);

  RETURN jsonb_build_object('success', true, 'bid_id', v_bid_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Fix process_auto_bids: remove inline total_bids/current_price updates
CREATE OR REPLACE FUNCTION process_auto_bids(
  p_auction_id UUID,
  p_current_bidder_id UUID,
  p_current_price NUMERIC,
  p_increment NUMERIC
) RETURNS VOID AS $$
DECLARE
  v_auto_bid RECORD;
  v_next_bid_amount NUMERIC;
BEGIN
  FOR v_auto_bid IN 
    SELECT user_id, max_bid_amount
    FROM auto_bid_settings
    WHERE auction_id = p_auction_id
      AND is_active = TRUE
      AND user_id != p_current_bidder_id
      AND max_bid_amount >= (p_current_price + p_increment)
    ORDER BY max_bid_amount DESC, created_at ASC
  LOOP
    v_next_bid_amount := p_current_price + p_increment;

    IF v_auto_bid.max_bid_amount >= v_next_bid_amount THEN
      -- Insert auto bid (trigger handles total_bids and current_price)
      INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid)
      VALUES (p_auction_id, v_auto_bid.user_id, v_next_bid_amount, TRUE);

      p_current_price := v_next_bid_amount;
      p_current_bidder_id := v_auto_bid.user_id;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Backfill: Fix any existing auctions with incorrect total_bids
UPDATE auctions a
SET 
  total_bids = COALESCE(
    (SELECT COUNT(*) FROM bids WHERE auction_id = a.id),
    0
  ),
  current_price = COALESCE(
    (SELECT MAX(bid_amount) FROM bids WHERE auction_id = a.id),
    a.starting_price
  ),
  updated_at = NOW();
