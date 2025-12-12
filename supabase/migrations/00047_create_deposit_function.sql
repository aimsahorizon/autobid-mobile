-- ============================================================================
-- AutoBid Mobile - Migration 00047: Create deposit function
-- Creates RPC function to handle deposit creation after successful payment
-- ============================================================================

-- Create or replace the create_deposit function
CREATE OR REPLACE FUNCTION create_deposit(
  p_auction_id UUID,
  p_user_id UUID,
  p_amount DECIMAL,
  p_payment_intent_id TEXT
)
RETURNS TABLE(deposit_id UUID, success BOOLEAN, message TEXT) AS $$
DECLARE
  v_deposit_id UUID;
  v_auction_seller_id UUID;
  v_transaction_type_id UUID;
  v_transaction_status_id UUID;
  v_transaction_id UUID;
BEGIN
  -- Verify auction exists
  SELECT seller_id INTO v_auction_seller_id
  FROM auctions
  WHERE id = p_auction_id;

  IF v_auction_seller_id IS NULL THEN
    RETURN QUERY SELECT 
      NULL::UUID,
      FALSE,
      'Auction not found'::TEXT;
    RETURN;
  END IF;

  -- Verify user is not the seller
  IF v_auction_seller_id = p_user_id THEN
    RETURN QUERY SELECT 
      NULL::UUID,
      FALSE,
      'Seller cannot deposit on their own auction'::TEXT;
    RETURN;
  END IF;

  -- Check if user has already deposited for this auction
  IF EXISTS (
    SELECT 1 FROM deposits
    WHERE auction_id = p_auction_id AND user_id = p_user_id AND is_refunded = FALSE
  ) THEN
    RETURN QUERY SELECT 
      NULL::UUID,
      FALSE,
      'You have already deposited for this auction'::TEXT;
    RETURN;
  END IF;

  -- Get transaction type ID for 'deposit'
  SELECT id INTO v_transaction_type_id
  FROM transaction_types
  WHERE type_name = 'deposit';

  IF v_transaction_type_id IS NULL THEN
    -- Fallback: create the deposit type if missing
    INSERT INTO transaction_types (type_name, description)
    VALUES ('deposit', 'Auction deposit payment')
    RETURNING id INTO v_transaction_type_id;
  END IF;

  -- Get transaction status ID for 'completed'
  SELECT id INTO v_transaction_status_id
  FROM transaction_statuses
  WHERE status_name = 'completed';

  IF v_transaction_status_id IS NULL THEN
    -- Fallback: use first status available
    SELECT id INTO v_transaction_status_id
    FROM transaction_statuses
    LIMIT 1;
  END IF;

  -- Create transaction record (using the correct schema)
  INSERT INTO transactions (
    user_id,
    auction_id,
    type_id,
    status_id,
    amount,
    external_transaction_id,
    metadata
  )
  VALUES (
    p_user_id,
    p_auction_id,
    v_transaction_type_id,
    v_transaction_status_id,
    p_amount,
    p_payment_intent_id,
    jsonb_build_object('payment_intent_id', p_payment_intent_id, 'type', 'auction_deposit')
  )
  RETURNING id INTO v_transaction_id;

  -- Create deposit record
  INSERT INTO deposits (transaction_id, auction_id, user_id, amount)
  VALUES (v_transaction_id, p_auction_id, p_user_id, p_amount)
  RETURNING deposits.id INTO v_deposit_id;

  -- Return success
  RETURN QUERY SELECT 
    v_deposit_id,
    TRUE,
    'Deposit created successfully'::TEXT;

EXCEPTION WHEN OTHERS THEN
  RETURN QUERY SELECT 
    NULL::UUID,
    FALSE,
    ('Error: ' || SQLERRM)::TEXT;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create has_user_deposited function
CREATE OR REPLACE FUNCTION has_user_deposited(
  p_auction_id UUID,
  p_user_id UUID
)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM deposits
    WHERE auction_id = p_auction_id 
    AND user_id = p_user_id 
    AND is_refunded = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
