-- ============================================================
-- Dev Test Mode: Update auction end time bypass for active/live auctions
-- Purpose: allow seller-side dev testing from Active Listing Detail page
-- while still respecting core time-range safety constraints.
-- ============================================================

CREATE OR REPLACE FUNCTION update_auction_end_time_dev(
  p_auction_id UUID,
  p_new_end_time TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
BEGIN
  -- Fetch auction and verify seller ownership.
  SELECT a.*
  INTO v_auction
  FROM auctions a
  WHERE a.id = p_auction_id
    AND a.seller_id = auth.uid();

  IF v_auction IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction not found or access denied'
    );
  END IF;

  -- Keep safety checks to avoid violating table constraints.
  IF p_new_end_time <= NOW() + INTERVAL '1 minute' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'End time must be in the future'
    );
  END IF;

  IF p_new_end_time <= v_auction.start_time THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'End time must be after start time'
    );
  END IF;

  IF p_new_end_time > v_auction.start_time + INTERVAL '90 days' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction cannot run for more than 90 days'
    );
  END IF;

  -- Dev bypass: no status restriction here.
  UPDATE auctions
  SET end_time = p_new_end_time,
      updated_at = NOW()
  WHERE id = p_auction_id;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Auction end time updated successfully (dev)',
    'new_end_time', p_new_end_time
  );
EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION update_auction_end_time_dev(UUID, TIMESTAMPTZ) TO authenticated;

COMMENT ON FUNCTION update_auction_end_time_dev IS
  'Dev test mode only: update auction end time for seller-owned auctions without pending/approved status restriction.';
