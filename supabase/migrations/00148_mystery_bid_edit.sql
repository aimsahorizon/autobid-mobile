-- Migration 00148: Allow editing mystery bids before deadline
-- Users can now update their sealed bid amount as long as the auction is still live.

-- ========================================================================
-- 1. Update place_mystery_bid to UPSERT instead of reject existing bids
-- ========================================================================

CREATE OR REPLACE FUNCTION place_mystery_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_amount NUMERIC
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_existing_bid RECORD;
  v_min_bid NUMERIC;
  v_active_status_id UUID;
BEGIN
  SELECT a.*, s.status_name
  INTO v_auction
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

  IF v_auction IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction not found');
  END IF;
  IF v_auction.status_name != 'live' THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction is not active');
  END IF;
  IF v_auction.bidding_type != 'mystery' THEN
    RETURN json_build_object('success', FALSE, 'error', 'This is not a mystery auction');
  END IF;
  IF v_auction.end_time <= NOW() THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction has ended');
  END IF;
  IF v_auction.seller_id = p_bidder_id THEN
    RETURN json_build_object('success', FALSE, 'error', 'Seller cannot bid on their own auction');
  END IF;

  v_min_bid := v_auction.starting_price;
  IF p_amount < v_min_bid THEN
    RETURN json_build_object('success', FALSE, 'error',
      'Bid must be at least ₱' || v_min_bid::TEXT);
  END IF;

  -- Check if user already has a bid
  SELECT * INTO v_existing_bid
  FROM bids
  WHERE auction_id = p_auction_id AND bidder_id = p_bidder_id;

  IF v_existing_bid IS NOT NULL THEN
    -- Update existing bid amount
    UPDATE bids
    SET bid_amount = p_amount, created_at = NOW()
    WHERE id = v_existing_bid.id;

    RETURN json_build_object(
      'success', TRUE,
      'message', 'Your sealed bid has been updated successfully',
      'updated', TRUE
    );
  END IF;

  -- New bid: set flag so trigger allows insertion
  PERFORM set_config('app.mystery_bid_allowed', 'true', TRUE);

  SELECT id INTO v_active_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;

  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id, created_at)
  VALUES (p_auction_id, p_bidder_id, p_amount, FALSE, v_active_status_id, NOW());

  PERFORM set_config('app.mystery_bid_allowed', 'false', TRUE);

  UPDATE auctions
  SET total_bids = total_bids + 1, updated_at = NOW()
  WHERE id = p_auction_id;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Your sealed bid has been placed successfully',
    'updated', FALSE
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
