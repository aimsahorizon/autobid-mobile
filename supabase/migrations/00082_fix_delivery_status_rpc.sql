-- ============================================================================
-- AutoBid Mobile - Migration 00082: Fix Delivery Status RPC & Constraints
-- ============================================================================
-- Fixes mismatch between RPC event types and timeline check constraints
-- ============================================================================

-- 1. Update the check constraint on transaction_timeline to allow both snake_case and camelCase for delivery events
ALTER TABLE transaction_timeline DROP CONSTRAINT IF EXISTS transaction_timeline_event_type_check;

ALTER TABLE transaction_timeline ADD CONSTRAINT transaction_timeline_event_type_check
  CHECK (event_type IN (
    'created', 
    'message_sent', 
    'form_submitted', 
    'form_reviewed',
    'form_confirmed', 
    'admin_review',
    'admin_submitted', 
    'admin_approved', 
    'delivery_started', 
    'deliveryStarted',
    'delivery_completed', 
    'deliveryCompleted',
    'completed', 
    'cancelled',
    'disputed',
    'deposit_refunded',
    'transaction_started'
  ));

-- 2. Correct the update_delivery_status RPC function to use the allowed types
CREATE OR REPLACE FUNCTION update_delivery_status(
  p_transaction_id UUID,
  p_seller_id UUID,
  p_delivery_status TEXT
)
RETURNS JSON AS $$
DECLARE
  v_transaction RECORD;
  v_title TEXT;
  v_description TEXT;
  v_event_type TEXT;
BEGIN
  -- Get transaction and verify seller
  SELECT * INTO v_transaction
  FROM auction_transactions
  WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'error', 'Transaction not found');
  END IF;

  IF v_transaction.seller_id != p_seller_id THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized - not the seller');
  END IF;

  IF v_transaction.admin_approved != TRUE THEN
    RETURN json_build_object('success', FALSE, 'error', 'Transaction not yet approved by admin');
  END IF;

  -- Determine timeline event details
  CASE p_delivery_status
    WHEN 'preparing' THEN
      v_title := 'Preparing Vehicle';
      v_description := 'Seller is preparing the vehicle for delivery';
      v_event_type := 'delivery_started';
    WHEN 'in_transit' THEN
      v_title := 'In Transit';
      v_description := 'Vehicle is being transported to buyer';
      v_event_type := 'delivery_started';
    WHEN 'delivered' THEN
      v_title := 'Vehicle Delivered';
      v_description := 'Vehicle has been delivered to buyer - awaiting confirmation';
      v_event_type := 'delivery_completed';
    ELSE
      v_title := 'Status Updated';
      v_description := 'Delivery status updated to: ' || p_delivery_status;
      v_event_type := 'delivery_started';
  END CASE;

  -- Update delivery status
  UPDATE auction_transactions
  SET 
    delivery_status = p_delivery_status,
    delivery_started_at = CASE 
      WHEN p_delivery_status = 'preparing' AND delivery_started_at IS NULL 
      THEN NOW() 
      ELSE delivery_started_at 
    END,
    updated_at = NOW()
  WHERE id = p_transaction_id;

  -- Add timeline event
  INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_name)
  VALUES (p_transaction_id, v_title, v_description, v_event_type, 'Seller');

  RETURN json_build_object('success', TRUE, 'status', p_delivery_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
