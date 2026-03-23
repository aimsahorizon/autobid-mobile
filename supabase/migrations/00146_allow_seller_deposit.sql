-- ============================================================================
-- AutoBid Mobile - Migration 00146: Allow seller deposits
-- Removes the seller block from create_deposit so both buyer and seller
-- can pay deposits for the same auction (required by new policy system).
-- Also refunds any "phantom" wallet debits where seller paid but no
-- deposit record was created due to the old guard.
-- ============================================================================

-- 1. Replace create_deposit to allow seller deposits
CREATE OR REPLACE FUNCTION create_deposit(
  p_auction_id UUID,
  p_user_id UUID,
  p_amount DECIMAL,
  p_payment_intent_id TEXT
)
RETURNS TABLE(deposit_id UUID, success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
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

  -- (Seller check removed: both buyer and seller must deposit under new policy)

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
    INSERT INTO transaction_types (type_name, description)
    VALUES ('deposit', 'Auction deposit payment')
    RETURNING id INTO v_transaction_type_id;
  END IF;

  -- Get transaction status ID for 'completed'
  SELECT id INTO v_transaction_status_id
  FROM transaction_statuses
  WHERE status_name = 'completed';

  IF v_transaction_status_id IS NULL THEN
    SELECT id INTO v_transaction_status_id
    FROM transaction_statuses
    LIMIT 1;
  END IF;

  -- Create transaction record
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
$$;


-- 2. Refund phantom wallet debits for sellers who paid but got no deposit record.
--    These are wallet transactions with category='deposit' where the reference_id
--    (auction_id) has a seller_id matching the wallet owner, but no deposit row exists.
DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT wt.id AS wt_id, w.user_id, wt.amount, wt.reference_id AS auction_id
    FROM virtual_wallet_transactions wt
    JOIN virtual_wallets w ON w.id = wt.wallet_id
    JOIN auctions a ON a.id = wt.reference_id::uuid
    WHERE wt.category = 'deposit'
      AND wt.type = 'debit'
      AND a.seller_id = w.user_id
      AND NOT EXISTS (
        SELECT 1 FROM deposits d
        WHERE d.auction_id = a.id AND d.user_id = w.user_id AND d.is_refunded = FALSE
      )
  LOOP
    -- Credit back to wallet
    UPDATE virtual_wallets
    SET balance = balance + r.amount,
        updated_at = now()
    WHERE user_id = r.user_id;

    -- Record the refund transaction
    INSERT INTO virtual_wallet_transactions (wallet_id, user_id, type, amount, category, reference_id, description, balance_after)
    SELECT w.id, w.user_id, 'credit', r.amount, 'deposit_return', r.auction_id::text,
           'Refund: seller deposit failed to record (migration fix)',
           w.balance
    FROM virtual_wallets w
    WHERE w.user_id = r.user_id;

    RAISE NOTICE 'Refunded phantom seller deposit: user=%, auction=%, amount=%',
      r.user_id, r.auction_id, r.amount;
  END LOOP;
END;
$$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
