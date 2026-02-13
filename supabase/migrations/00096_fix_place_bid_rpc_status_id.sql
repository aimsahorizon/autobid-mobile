-- Migration: Fix place_bid RPC to use correct status_id
-- Date: 2026-01-31
-- Description: Updates the place_bid function to lookup the 'active' status_id from bid_statuses table
--              instead of trying to insert a text value or null into the status_id column.

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
     -- Special case: If this is the FIRST bid (current_price might be starting price with 0 bids)
     -- Simplified: Strict check.
     RETURN jsonb_build_object('success', false, 'error', 'Bid amount too low. Minimum required: ' || (v_current_price + v_min_increment));
  END IF;

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

  -- 9. Trigger Auto-bids
  PERFORM process_auto_bids(p_auction_id, p_bidder_id, p_amount, v_min_increment);

  RETURN jsonb_build_object('success', true, 'bid_id', v_bid_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
