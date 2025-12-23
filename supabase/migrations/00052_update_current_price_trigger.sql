-- Add trigger to automatically update auction current_price when a bid is placed

CREATE OR REPLACE FUNCTION update_auction_current_price()
RETURNS TRIGGER AS $$
BEGIN
  -- Always recalculate current_price and total_bids from actual bid data
  -- This ensures consistency even if bids are out of order or have any edge cases
  UPDATE auctions
  SET 
    current_price = (
      SELECT COALESCE(MAX(bid_amount), starting_price)
      FROM bids
      WHERE auction_id = NEW.auction_id
    ),
    total_bids = (
      SELECT COUNT(*)
      FROM bids
      WHERE auction_id = NEW.auction_id
    ),
    updated_at = NOW()
  WHERE id = NEW.auction_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on bids table
DROP TRIGGER IF EXISTS trigger_update_auction_current_price ON bids;
CREATE TRIGGER trigger_update_auction_current_price
  AFTER INSERT ON bids
  FOR EACH ROW
  EXECUTE FUNCTION update_auction_current_price();

-- Backfill: Update all existing auctions to reflect their actual highest bid and bid count
UPDATE auctions a
SET 
  current_price = COALESCE(
    (SELECT MAX(bid_amount) FROM bids WHERE auction_id = a.id),
    a.starting_price
  ),
  total_bids = COALESCE(
    (SELECT COUNT(*) FROM bids WHERE auction_id = a.id),
    0
  ),
  updated_at = NOW()
WHERE EXISTS (SELECT 1 FROM bids WHERE auction_id = a.id);
