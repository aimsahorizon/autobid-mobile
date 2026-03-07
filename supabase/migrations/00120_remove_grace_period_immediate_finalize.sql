-- ============================================================================
-- Migration: Remove grace period, enable immediate finalization
-- ============================================================================
-- Flow change: Both lock → Both confirm (with finality warning) → immediate finalize
-- No more 15s grace period or skip-grace-period mechanism.
-- Withdrawing confirmation resets both locks (handled client-side).

-- 1. Drop grace period skip columns (no longer needed)
ALTER TABLE auction_transactions
  DROP COLUMN IF EXISTS seller_agreed_to_skip_grace_period,
  DROP COLUMN IF EXISTS buyer_agreed_to_skip_grace_period;

-- 2. Update finalize_transaction RPC:
--    Remove grace period elapsed check — finalize immediately when both confirmed.
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

  -- Finalize immediately (no grace period check)
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
    'Both parties confirmed. Transaction proceeds to delivery phase.',
    'admin_approved',
    NOW()
  );

  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
