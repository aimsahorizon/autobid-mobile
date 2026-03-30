-- ============================================================================
-- Migration: Remove admin approval dependency & add grace period skip flags
-- ============================================================================

-- 1. Add grace period skip columns
ALTER TABLE auction_transactions
  ADD COLUMN IF NOT EXISTS seller_agreed_to_skip_grace_period BOOLEAN DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS buyer_agreed_to_skip_grace_period BOOLEAN DEFAULT FALSE;

-- 2. Update finalize_transaction RPC to:
--    a) Remove admin approval requirement (auto-finalize after grace period)
--    b) Allow bypass when both parties agree to skip (5s handled client-side)
--    c) Set status to 'in_transaction' (ongoing), NOT 'sold' (completed)
CREATE OR REPLACE FUNCTION finalize_transaction(p_transaction_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_txn RECORD;
BEGIN
  SELECT * INTO v_txn
  FROM auction_transactions
  WHERE id = p_transaction_id
  FOR UPDATE;

  IF v_txn IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transaction not found');
  END IF;

  -- Already finalized
  IF v_txn.admin_approved THEN
    RETURN jsonb_build_object('success', true, 'already_finalized', true);
  END IF;

  -- Verify both confirmed
  IF NOT v_txn.seller_confirmed OR NOT v_txn.buyer_confirmed THEN
    RETURN jsonb_build_object('success', false, 'error', 'Both parties must confirm');
  END IF;

  -- Check: either grace period elapsed OR both agreed to skip
  IF v_txn.seller_agreed_to_skip_grace_period AND v_txn.buyer_agreed_to_skip_grace_period THEN
    -- Both agreed to skip: allow immediate finalization (5s countdown handled client-side)
    NULL; -- proceed
  ELSIF v_txn.both_confirmed_at IS NULL OR
        NOW() < v_txn.both_confirmed_at + interval '15 seconds' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Grace period has not elapsed');
  END IF;

  -- Finalize: set admin_approved flag (reused as "finalized" indicator)
  -- Keep status as 'in_transaction' (NOT 'sold') so it stays in active tab
  UPDATE auction_transactions SET
    admin_approved = TRUE,
    admin_approved_at = NOW(),
    updated_at = NOW()
  WHERE id = p_transaction_id;

  -- Add timeline event
  INSERT INTO transaction_timeline (transaction_id, title, description, event_type, created_at)
  VALUES (
    p_transaction_id,
    'Transaction Finalized',
    CASE
      WHEN v_txn.seller_agreed_to_skip_grace_period AND v_txn.buyer_agreed_to_skip_grace_period
      THEN 'Both parties agreed to skip the grace period. Transaction proceeds to delivery phase.'
      ELSE 'Grace period completed. Transaction proceeds to delivery phase.'
    END,
    'admin_approved',
    NOW()
  );

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Update RLS policies to allow users to update the new columns
-- (existing policies should already cover this since sellers/buyers can update their own transaction)
