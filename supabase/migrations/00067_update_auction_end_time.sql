-- ============================================================================
-- AutoBid Mobile - Migration 00067: Update Auction End Time
-- Allows sellers to update auction end time for pending/approved listings
-- ============================================================================

CREATE OR REPLACE FUNCTION update_auction_end_time(
  p_auction_id UUID,
  p_new_end_time TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_status_name TEXT;
BEGIN
  -- Fetch the auction and verify ownership
  SELECT a.*, ast.status_name
  INTO v_auction
  FROM auctions a
  JOIN auction_statuses ast ON a.status_id = ast.id
  WHERE a.id = p_auction_id
    AND a.seller_id = auth.uid();

  -- Validate auction exists and belongs to current user
  IF v_auction IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction not found or access denied'
    );
  END IF;

  -- Only allow updates for pending_approval or approved status
  IF v_auction.status_name NOT IN ('pending_approval', 'approved') THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Can only update end time for pending or approved auctions'
    );
  END IF;

  -- Validate new end time is in the future
  IF p_new_end_time <= NOW() THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'End time must be in the future'
    );
  END IF;

  -- Validate new end time is after start time
  IF p_new_end_time <= v_auction.start_time THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'End time must be after start time'
    );
  END IF;

  -- Validate auction duration (max 90 days)
  IF p_new_end_time > v_auction.start_time + INTERVAL '90 days' THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction cannot run for more than 90 days'
    );
  END IF;

  -- Update the end time
  UPDATE auctions
  SET end_time = p_new_end_time,
      updated_at = NOW()
  WHERE id = p_auction_id;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Auction end time updated successfully',
    'new_end_time', p_new_end_time
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_auction_end_time(UUID, TIMESTAMPTZ) TO authenticated;

COMMENT ON FUNCTION update_auction_end_time IS 
'Allows sellers to update the auction end time for their pending or approved listings';
