-- Migration: Fix process_auto_bids RPC to use correct status_id
-- Date: 2026-01-31
-- Description: Updates the process_auto_bids function to lookup the 'active' status_id from bid_statuses table
--              instead of trying to insert a null into the status_id column.

CREATE OR REPLACE FUNCTION process_auto_bids(
  p_auction_id UUID,
  p_current_bidder_id UUID,
  p_current_price NUMERIC,
  p_increment NUMERIC
) RETURNS VOID AS $$
DECLARE
  v_auto_bid RECORD;
  v_next_bid_amount NUMERIC;
  v_outbid_user_id UUID;
  v_active_bid_status_id UUID;
BEGIN
  -- 1. Get the 'active' status ID for the new bid
  SELECT id INTO v_active_bid_status_id FROM bid_statuses WHERE status_name = 'active' LIMIT 1;
  
  IF v_active_bid_status_id IS NULL THEN
    RAISE WARNING 'System Error: Active bid status not found during auto-bid processing';
    RETURN;
  END IF;

  -- Find active auto-bids for other users that can beat the current price
  FOR v_auto_bid IN 
    SELECT user_id, max_bid_amount
    FROM auto_bid_settings
    WHERE auction_id = p_auction_id
      AND is_active = TRUE
      AND user_id != p_current_bidder_id -- Don't bid against self
      AND max_bid_amount >= (p_current_price + p_increment)
    ORDER BY max_bid_amount DESC, created_at ASC -- Highest max bid priority, then FIFO
  LOOP
    v_next_bid_amount := p_current_price + p_increment;

    -- Double check if we can afford the next increment
    IF v_auto_bid.max_bid_amount >= v_next_bid_amount THEN
      -- Place Auto Bid
      INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, status_id)
      VALUES (p_auction_id, v_auto_bid.user_id, v_next_bid_amount, TRUE, v_active_bid_status_id);

      -- Update Auction
      UPDATE auctions
      SET 
        current_price = v_next_bid_amount,
        total_bids = total_bids + 1
      WHERE id = p_auction_id;

      -- Update local tracking variable for the loop (in case multiple auto-bids compete)
      p_current_price := v_next_bid_amount;
      p_current_bidder_id := v_auto_bid.user_id;
      
      -- If multiple auto-bidders exist, the loop continues and they outbid each other
      -- until one reaches their max.
    ELSE
      -- User cannot afford next increment, disable their auto-bid?
      -- Optionally: Update auto_bid_settings SET is_active = FALSE WHERE ...
      -- For now, we leave it active but they just won't bid.
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
