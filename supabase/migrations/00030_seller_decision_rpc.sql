-- ============================================================================
-- AutoBid Mobile - Migration 00030: Seller Decision After Auction Ends
-- RPC function for seller to decide whether to proceed or cancel after auction
-- ============================================================================

CREATE OR REPLACE FUNCTION seller_decide_after_auction(
  p_auction_id UUID,
  p_proceed BOOLEAN
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_ended_status_id UUID;
  v_in_transaction_status_id UUID;
  v_cancelled_status_id UUID;
BEGIN
  -- ========================================================================
  -- STEP 1: Get auction and verify ownership
  -- ========================================================================
  SELECT * INTO v_auction
  FROM auctions
  WHERE id = p_auction_id
    AND seller_id = auth.uid();

  IF v_auction IS NULL THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction not found or access denied'
    );
  END IF;

  -- ========================================================================
  -- STEP 2: Get status IDs
  -- ========================================================================
  SELECT id INTO v_ended_status_id
  FROM auction_statuses
  WHERE status_name = 'ended';

  SELECT id INTO v_in_transaction_status_id
  FROM auction_statuses
  WHERE status_name = 'in_transaction';

  SELECT id INTO v_cancelled_status_id
  FROM auction_statuses
  WHERE status_name = 'cancelled';

  -- ========================================================================
  -- STEP 3: Verify auction is in 'ended' status
  -- ========================================================================
  IF v_auction.status_id != v_ended_status_id THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Auction is not in ended status. Current status does not allow this action.'
    );
  END IF;

  -- ========================================================================
  -- STEP 4: Execute seller's decision
  -- ========================================================================
  IF p_proceed THEN
    -- Seller chooses to proceed to transaction
    UPDATE auctions
    SET status_id = v_in_transaction_status_id,
        updated_at = NOW()
    WHERE id = p_auction_id;

    RETURN json_build_object(
      'success', TRUE,
      'status', 'in_transaction',
      'message', 'Proceeding to transaction. You can now negotiate with the buyer.'
    );
  ELSE
    -- Seller chooses to cancel
    UPDATE auctions
    SET status_id = v_cancelled_status_id,
        updated_at = NOW()
    WHERE id = p_auction_id;

    RETURN json_build_object(
      'success', TRUE,
      'status', 'cancelled',
      'message', 'Auction cancelled. The listing has been removed from active auctions.'
    );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object(
      'success', FALSE,
      'error', 'Failed to process decision: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION seller_decide_after_auction TO authenticated;

-- ============================================================================
-- EXPLANATION:
-- ============================================================================
-- PURPOSE:
--   Allows seller to decide whether to proceed or cancel after auction ends
--
-- WORKFLOW:
--   1. Auction ends (status: 'ended')
--   2. Seller reviews results (reserve price met? satisfied with bid?)
--   3. Seller clicks "Proceed" or "Cancel" in UI
--   4. This RPC updates auction status accordingly
--
-- PARAMETERS:
--   - p_auction_id: UUID of the auction
--   - p_proceed: TRUE = proceed to transaction, FALSE = cancel
--
-- RETURNS:
--   JSON object with:
--   - success: boolean
--   - status: new status name ('in_transaction' or 'cancelled')
--   - message: user-friendly message
--   - error: error message if failed
--
-- SECURITY:
--   - SECURITY DEFINER: Runs with function creator's privileges
--   - Row-level check: Verifies seller_id = auth.uid()
--   - Status validation: Only works if auction is in 'ended' status
--
-- USAGE EXAMPLE:
--   SELECT seller_decide_after_auction('auction-uuid-here', TRUE);  -- Proceed
--   SELECT seller_decide_after_auction('auction-uuid-here', FALSE); -- Cancel
-- ============================================================================

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
