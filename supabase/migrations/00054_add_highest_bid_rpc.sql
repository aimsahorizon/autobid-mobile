-- Add helper RPC for getting highest bid for an auction
-- This ensures we can reliably retrieve the winning bid

CREATE OR REPLACE FUNCTION public.get_highest_bid(auction_id_param uuid)
RETURNS TABLE(bidder_id uuid, bid_amount NUMERIC) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    b.bidder_id,
    b.bid_amount
  FROM public.bids b
  WHERE b.auction_id = auction_id_param
  ORDER BY b.bid_amount DESC, b.created_at DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Verify the bids table has correct data structure
-- This view helps diagnose issues with bid retrieval
CREATE OR REPLACE VIEW public.auction_bid_summary AS
SELECT 
  a.id as auction_id,
  a.title,
  a.current_price,
  a.total_bids,
  COUNT(b.id) as actual_bid_count,
  MAX(b.bid_amount) as max_bid_amount,
  (SELECT bidder_id FROM public.bids WHERE auction_id = a.id ORDER BY bid_amount DESC LIMIT 1) as top_bidder_id
FROM public.auctions a
LEFT JOIN public.bids b ON a.id = b.auction_id
GROUP BY a.id, a.title, a.current_price, a.total_bids
ORDER BY a.created_at DESC;

-- Grant execute on RPC to authenticated users
GRANT EXECUTE ON FUNCTION public.get_highest_bid(uuid) TO authenticated;
