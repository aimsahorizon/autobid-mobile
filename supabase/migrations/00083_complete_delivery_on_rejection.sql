-- ============================================================================
-- AutoBid Mobile - Migration 00083: Complete Delivery Status on Rejection
-- ============================================================================
-- Updates handle_buyer_acceptance to mark delivery_status as 'completed'
-- even on rejection, so the progress tracker reaches the final state.
-- ============================================================================

CREATE OR REPLACE FUNCTION handle_buyer_acceptance(
  p_transaction_id UUID,
  p_buyer_id UUID,
  p_accepted BOOLEAN,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_transaction RECORD;
BEGIN
  -- Get transaction and verify buyer
  SELECT * INTO v_transaction
  FROM auction_transactions
  WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'error', 'Transaction not found');
  END IF;

  IF v_transaction.buyer_id != p_buyer_id THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized - not the buyer');
  END IF;

  IF v_transaction.delivery_status != 'delivered' THEN
    RETURN json_build_object('success', FALSE, 'error', 'Vehicle must be delivered first');
  END IF;

  IF v_transaction.buyer_acceptance_status != 'pending' THEN
    RETURN json_build_object('success', FALSE, 'error', 'Already responded');
  END IF;

  -- Update transaction based on acceptance
  IF p_accepted THEN
    UPDATE auction_transactions
    SET 
      buyer_acceptance_status = 'accepted',
      buyer_accepted_at = NOW(),
      delivery_status = 'completed',
      delivery_completed_at = NOW(),
      status = 'sold',
      updated_at = NOW()
    WHERE id = p_transaction_id;

    -- Add timeline event
    INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_name)
    VALUES (p_transaction_id, 'Vehicle Accepted', 'Buyer confirmed receipt and accepted the vehicle', 'completed', 'Buyer');

  ELSE
    UPDATE auction_transactions
    SET 
      buyer_acceptance_status = 'rejected',
      buyer_accepted_at = NOW(),
      buyer_rejection_reason = p_rejection_reason,
      delivery_status = 'completed', -- Set to completed so tracker finishes
      delivery_completed_at = NOW(),
      status = 'deal_failed',
      updated_at = NOW()
    WHERE id = p_transaction_id;

    -- Add timeline event
    INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_name)
    VALUES (
      p_transaction_id, 
      'Vehicle Rejected', 
      COALESCE('Buyer rejected: ' || p_rejection_reason, 'Buyer rejected the vehicle'),
      'cancelled',
      'Buyer'
    );
  END IF;

  RETURN json_build_object(
    'success', TRUE,
    'status', CASE WHEN p_accepted THEN 'accepted' ELSE 'rejected' END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
