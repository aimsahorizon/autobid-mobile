-- Cancel Deal Next Winner Logic
-- When a buyer cancels, the next winner selection must:
--   1. Exclude ALL bids from the previous winning bidder (they may have multiple bids)
--   2. Return NULL if only 1 unique bidder exists (no next winner possible)
--   3. Skip bids with 'lost' or 'refunded' status

-- Function: Get the next eligible winner for an auction, excluding a specific bidder
CREATE OR REPLACE FUNCTION public.get_next_eligible_winner(
  p_transaction_id UUID
)
RETURNS TABLE(
  bidder_id    UUID,
  bidder_name  TEXT,
  bid_amount   NUMERIC,
  bid_id       UUID
)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id UUID;
  v_current_buyer_id UUID;
BEGIN
  -- Resolve auction_id and current buyer from the transaction
  SELECT at.auction_id, at.buyer_id
    INTO v_auction_id, v_current_buyer_id
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RETURN; -- empty result
  END IF;

  -- Count unique bidders excluding the current buyer
  -- If <= 0 unique other bidders, no next winner is possible
  IF (
    SELECT COUNT(DISTINCT b.bidder_id)
      FROM public.bids b
      LEFT JOIN public.bid_statuses bs ON b.status_id = bs.id
     WHERE b.auction_id = v_auction_id
       AND b.bidder_id != v_current_buyer_id
       AND (bs.status_name IS NULL OR bs.status_name NOT IN ('lost', 'refunded'))
  ) = 0 THEN
    RETURN; -- no eligible next winner
  END IF;

  -- Return eligible bidders ordered by highest bid, excluding current buyer
  RETURN QUERY
    SELECT
      b.bidder_id,
      COALESCE(u.full_name, u.display_name, 'Unknown')::TEXT AS bidder_name,
      b.bid_amount,
      b.id AS bid_id
    FROM public.bids b
    LEFT JOIN public.bid_statuses bs ON b.status_id = bs.id
    LEFT JOIN public.users u ON b.bidder_id = u.id
    WHERE b.auction_id = v_auction_id
      AND b.bidder_id != v_current_buyer_id
      AND (bs.status_name IS NULL OR bs.status_name NOT IN ('lost', 'refunded'))
    ORDER BY b.bid_amount DESC;
END;
$$;

-- Convenience function: get just the top next winner (single row)
CREATE OR REPLACE FUNCTION public.get_top_next_winner(
  p_transaction_id UUID
)
RETURNS TABLE(
  bidder_id    UUID,
  bidder_name  TEXT,
  bid_amount   NUMERIC,
  bid_id       UUID
)
LANGUAGE sql SECURITY DEFINER AS $$
  SELECT * FROM public.get_next_eligible_winner(p_transaction_id) LIMIT 1;
$$;

-- Function: count unique eligible bidders (excluding the current buyer)
-- Returns 0 if no next winner is possible
CREATE OR REPLACE FUNCTION public.count_eligible_next_bidders(
  p_transaction_id UUID
)
RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id UUID;
  v_current_buyer_id UUID;
  v_count INT;
BEGIN
  SELECT at.auction_id, at.buyer_id
    INTO v_auction_id, v_current_buyer_id
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RETURN 0;
  END IF;

  SELECT COUNT(DISTINCT b.bidder_id)
    INTO v_count
    FROM public.bids b
    LEFT JOIN public.bid_statuses bs ON b.status_id = bs.id
   WHERE b.auction_id = v_auction_id
     AND b.bidder_id != v_current_buyer_id
     AND (bs.status_name IS NULL OR bs.status_name NOT IN ('lost', 'refunded'));

  RETURN v_count;
END;
$$;
