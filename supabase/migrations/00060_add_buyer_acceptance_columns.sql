-- ============================================================================
-- AutoBid Mobile - Migration 00060: Add Buyer Acceptance Columns
-- ============================================================================
-- Adds columns to track buyer acceptance/rejection after delivery
-- This enables the post-delivery confirmation flow
-- ============================================================================

-- Add buyer_acceptance_status column
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'buyer_acceptance_status'
    ) THEN
        ALTER TABLE auction_transactions 
        ADD COLUMN buyer_acceptance_status TEXT DEFAULT 'pending' 
        CHECK (buyer_acceptance_status IN ('pending', 'accepted', 'rejected'));
    END IF;
END $$;

-- Add buyer_accepted_at timestamp
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'buyer_accepted_at'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN buyer_accepted_at TIMESTAMPTZ;
    END IF;
END $$;

-- Add buyer_rejection_reason text
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'buyer_rejection_reason'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN buyer_rejection_reason TEXT;
    END IF;
END $$;

-- Add delivery_status if not exists (for completeness)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'delivery_status'
    ) THEN
        ALTER TABLE auction_transactions 
        ADD COLUMN delivery_status TEXT DEFAULT 'pending' 
        CHECK (delivery_status IN ('pending', 'preparing', 'in_transit', 'delivered', 'completed'));
    END IF;
END $$;

-- Add delivery timestamps if not exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'delivery_started_at'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN delivery_started_at TIMESTAMPTZ;
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'delivery_completed_at'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN delivery_completed_at TIMESTAMPTZ;
    END IF;
END $$;

-- Create index for delivery status queries
CREATE INDEX IF NOT EXISTS idx_auction_transactions_delivery 
  ON auction_transactions(delivery_status, buyer_acceptance_status);

-- Create function to handle buyer acceptance
CREATE OR REPLACE FUNCTION handle_buyer_acceptance(
  p_transaction_id UUID,
  p_buyer_id UUID,
  p_accepted BOOLEAN,
  p_rejection_reason TEXT DEFAULT NULL
)
RETURNS JSON AS $$
DECLARE
  v_transaction RECORD;
  v_result JSON;
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

-- Function to update delivery status (seller only)
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
    WHEN 'in_transit' THEN
      v_title := 'In Transit';
      v_description := 'Vehicle is being transported to buyer';
    WHEN 'delivered' THEN
      v_title := 'Vehicle Delivered';
      v_description := 'Vehicle has been delivered to buyer - awaiting confirmation';
    ELSE
      v_title := 'Status Updated';
      v_description := 'Delivery status updated to: ' || p_delivery_status;
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
  VALUES (p_transaction_id, v_title, v_description, 'deliveryStarted', 'Seller');

  RETURN json_build_object('success', TRUE, 'status', p_delivery_status);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION handle_buyer_acceptance TO authenticated;
GRANT EXECUTE ON FUNCTION update_delivery_status TO authenticated;
