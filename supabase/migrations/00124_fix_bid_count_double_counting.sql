-- Fix: Drop the trigger that double-counts total_bids.
--
-- ROOT CAUSE:
--   trigger_update_auction_current_price (migration 00052) fires AFTER INSERT
--   on bids and sets total_bids = COUNT(*). Then the calling function
--   (place_bid / submit_turn_bid / give_next_turn) ALSO does
--   total_bids = total_bids + 1, overwriting the trigger's correct value
--   with count+1 — resulting in +1 excess on every bid.
--
-- FIX:
--   Drop the trigger. All bidding functions already update total_bids and
--   current_price inline, so the trigger is redundant.
--   Restore inline updates in place_bid (previously removed in this migration).

-- 1. Drop the conflicting trigger
DROP TRIGGER IF EXISTS trigger_update_auction_current_price ON bids;
DROP FUNCTION IF EXISTS update_auction_current_price();

-- 2. Restore place_bid with inline total_bids + current_price updates
--    (Based on 00104 version, which is the canonical non-queue bidding path)
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
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;

  IF v_active_bid_status_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'System Error: Active bid status not found');
  END IF;

  SELECT current_price, bid_increment, end_time, status_id
  INTO v_current_price, v_min_increment, v_end_time, v_status_id
  FROM auctions
  WHERE id = p_auction_id
  FOR UPDATE;

  SELECT status_name INTO v_auction_status
  FROM auction_statuses WHERE id = v_status_id;

  IF v_auction_status NOT IN ('live', 'active') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction is not live');
  END IF;

  IF NOW() > v_end_time THEN
    RETURN jsonb_build_object('success', false, 'error', 'Auction has ended');
  END IF;

  IF p_amount < (v_current_price + v_min_increment) THEN
    RETURN jsonb_build_object('success', false, 'error', 'Bid amount too low. Minimum required: ' || (v_current_price + v_min_increment));
  END IF;

  SELECT bidder_id INTO v_previous_bidder_id
  FROM bids WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC LIMIT 1;

  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
  VALUES (p_auction_id, p_bidder_id, p_amount, p_is_auto_bid, v_active_bid_status_id)
  RETURNING id INTO v_bid_id;

  UPDATE auctions
  SET
    current_price = p_amount,
    total_bids = COALESCE(total_bids, 0) + 1,
    end_time = CASE
      WHEN v_end_time - NOW() < v_snipe_extension THEN NOW() + v_snipe_extension
      ELSE end_time
    END
  WHERE id = p_auction_id;

  IF v_previous_bidder_id IS NOT NULL AND v_previous_bidder_id != p_bidder_id THEN
    SELECT COALESCE(title, 'this auction') INTO v_auction_title
    FROM auctions WHERE id = p_auction_id;

    PERFORM create_bid_notification(
      v_previous_bidder_id, 'outbid',
      'You''ve Been Outbid!',
      format('Someone placed a higher bid of ₱%s on %s.',
        to_char(p_amount, 'FM999,999,999'), v_auction_title),
      jsonb_build_object('auction_id', p_auction_id, 'outbid_amount', p_amount, 'action', 'place_bid')
    );
  END IF;

  PERFORM enqueue_auto_bid_processing(p_auction_id);

  RETURN jsonb_build_object('success', true, 'bid_id', v_bid_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Backfill: Fix any existing auctions with incorrect total_bids
UPDATE auctions a
SET 
  total_bids = COALESCE(
    (SELECT COUNT(*) FROM bids WHERE auction_id = a.id),
    0
  ),
  current_price = GREATEST(
    COALESCE(
      (SELECT MAX(bid_amount) FROM bids WHERE auction_id = a.id),
      a.starting_price
    ),
    a.starting_price
  ),
  updated_at = NOW();
