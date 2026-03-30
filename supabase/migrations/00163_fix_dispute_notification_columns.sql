-- ============================================================================
-- Migration 00163: Fix dispute resolution notification column names
-- The notifications table uses (type_id, message) but 00161 used (type, body).
-- This causes raise_seller_objection and resolve_dispute RPCs to fail entirely.
-- Also ensures dispute columns exist on auction_transactions (in case 00161 failed).
-- ============================================================================

-- 0. Ensure dispute columns exist on auction_transactions
ALTER TABLE auction_transactions
  ADD COLUMN IF NOT EXISTS seller_objection_reason TEXT,
  ADD COLUMN IF NOT EXISTS seller_objected_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS dispute_resolution TEXT,
  ADD COLUMN IF NOT EXISTS dispute_resolved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS dispute_resolved_by UUID REFERENCES users(id),
  ADD COLUMN IF NOT EXISTS dispute_admin_notes TEXT;

-- Ensure 'disputed' is in the status CHECK constraint
DO $$
BEGIN
  BEGIN
    ALTER TABLE auction_transactions DROP CONSTRAINT IF EXISTS auction_transactions_status_check;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  BEGIN
    ALTER TABLE auction_transactions DROP CONSTRAINT IF EXISTS valid_status;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;
  ALTER TABLE auction_transactions ADD CONSTRAINT valid_status
    CHECK (status IN ('in_transaction', 'sold', 'deal_failed', 'disputed'));
END $$;

-- 1. Fix raise_seller_objection RPC
CREATE OR REPLACE FUNCTION raise_seller_objection(
  p_transaction_id UUID,
  p_seller_id UUID,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_txn RECORD;
  v_seller_name TEXT;
  v_notif_type_id UUID;
BEGIN
  -- Validate transaction
  SELECT * INTO v_txn FROM auction_transactions WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transaction not found');
  END IF;

  -- Must be the seller
  IF v_txn.seller_id != p_seller_id THEN
    RETURN jsonb_build_object('success', false, 'error', 'Only the seller can raise an objection');
  END IF;

  -- Buyer must have rejected
  IF v_txn.buyer_acceptance_status != 'rejected' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Buyer has not rejected delivery');
  END IF;

  -- Cannot object twice
  IF v_txn.seller_objection_reason IS NOT NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Objection already raised');
  END IF;

  -- Reason required
  IF p_reason IS NULL OR trim(p_reason) = '' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Objection reason is required');
  END IF;

  -- Get seller name
  SELECT full_name INTO v_seller_name FROM users WHERE id = p_seller_id;

  -- Update transaction: set disputed status and objection fields
  UPDATE auction_transactions
  SET
    status = 'disputed',
    seller_objection_reason = trim(p_reason),
    seller_objected_at = now(),
    updated_at = now()
  WHERE id = p_transaction_id;

  -- Add timeline event
  INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_id, actor_name)
  VALUES (
    p_transaction_id,
    'Dispute Raised',
    'Seller objected to buyer rejection: ' || trim(p_reason),
    'disputed',
    p_seller_id,
    COALESCE(v_seller_name, 'Seller')
  );

  -- Notify admins (wrapped in exception handler so notification failure doesn't block dispute)
  BEGIN
    SELECT id INTO v_notif_type_id FROM notification_types WHERE type_name = 'transaction_update' LIMIT 1;

    IF v_notif_type_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, type_id, title, message, data, is_read)
      SELECT
        au.user_id,
        v_notif_type_id,
        'Dispute Raised',
        'A dispute has been raised for transaction ' || p_transaction_id::text,
        jsonb_build_object(
          'transaction_id', p_transaction_id,
          'seller_id', p_seller_id,
          'type', 'dispute_raised'
        ),
        false
      FROM admin_users au
      JOIN users u ON u.id = au.user_id
      WHERE au.is_active = true;
    END IF;
  EXCEPTION WHEN OTHERS THEN
    -- Don't fail the dispute just because notification failed
    NULL;
  END;

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 2. Fix resolve_dispute RPC
CREATE OR REPLACE FUNCTION resolve_dispute(
  p_transaction_id UUID,
  p_admin_id UUID,
  p_resolution TEXT,
  p_penalized_user_id UUID DEFAULT NULL,
  p_admin_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_txn RECORD;
  v_admin_name TEXT;
  v_penalized_name TEXT;
  v_seller_deposit RECORD;
  v_buyer_deposit RECORD;
  v_resolution_desc TEXT;
  v_suspension_days INT := 30;
  v_notif_type_id UUID;
BEGIN
  -- Validate transaction
  SELECT * INTO v_txn FROM auction_transactions WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transaction not found');
  END IF;

  -- Must be in disputed status
  IF v_txn.status != 'disputed' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transaction is not in disputed status');
  END IF;

  -- Valid resolution
  IF p_resolution NOT IN ('refund_both', 'penalize_seller', 'penalize_buyer') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid resolution');
  END IF;

  -- Penalized user required for penalty resolutions
  IF p_resolution IN ('penalize_seller', 'penalize_buyer') AND p_penalized_user_id IS NULL THEN
    RETURN jsonb_build_object('success', false, 'error', 'Penalized user ID required');
  END IF;

  SELECT full_name INTO v_admin_name FROM users WHERE id = p_admin_id;

  -- Get notification type
  SELECT id INTO v_notif_type_id FROM notification_types WHERE type_name = 'transaction_update' LIMIT 1;

  -- 1. Refund both deposits
  SELECT * INTO v_seller_deposit FROM auction_deposits
    WHERE transaction_id = p_transaction_id AND depositor_type = 'seller' AND status = 'held'
    LIMIT 1;

  IF v_seller_deposit IS NOT NULL THEN
    UPDATE auction_deposits SET status = 'refunded', refunded_at = now()
    WHERE id = v_seller_deposit.id;

    UPDATE virtual_wallets
    SET balance = balance + v_seller_deposit.amount, updated_at = now()
    WHERE user_id = v_txn.seller_id;
  END IF;

  SELECT * INTO v_buyer_deposit FROM auction_deposits
    WHERE transaction_id = p_transaction_id AND depositor_type = 'buyer' AND status = 'held'
    LIMIT 1;

  IF v_buyer_deposit IS NOT NULL THEN
    UPDATE auction_deposits SET status = 'refunded', refunded_at = now()
    WHERE id = v_buyer_deposit.id;

    UPDATE virtual_wallets
    SET balance = balance + v_buyer_deposit.amount, updated_at = now()
    WHERE user_id = v_txn.buyer_id;
  END IF;

  -- 2. If penalizing, suspend the user
  IF p_resolution IN ('penalize_seller', 'penalize_buyer') THEN
    SELECT full_name INTO v_penalized_name FROM users WHERE id = p_penalized_user_id;

    INSERT INTO user_suspensions (user_id, reason, suspended_at, suspended_until, is_permanent)
    VALUES (
      p_penalized_user_id,
      'Dispute resolution: found to be dishonest in transaction ' || p_transaction_id::text,
      now(),
      now() + (v_suspension_days || ' days')::interval,
      false
    );

    v_resolution_desc := 'Dispute resolved: ' ||
      CASE p_resolution
        WHEN 'penalize_seller' THEN 'Seller penalized (suspended ' || v_suspension_days || ' days). '
        WHEN 'penalize_buyer' THEN 'Buyer penalized (suspended ' || v_suspension_days || ' days). '
      END ||
      'Both deposits refunded.';

    -- Notify penalized user (wrapped in exception handler)
    BEGIN
      IF v_notif_type_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, type_id, title, message, data, is_read)
        VALUES (
          p_penalized_user_id,
          v_notif_type_id,
          'Account Suspended',
          'Your account has been suspended for ' || v_suspension_days || ' days due to dispute resolution.',
          jsonb_build_object(
            'transaction_id', p_transaction_id,
            'suspension_days', v_suspension_days,
            'type', 'dispute_penalty'
          ),
          false
        );
      END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  ELSE
    v_resolution_desc := 'Dispute resolved: Both deposits refunded. No penalties applied.';
  END IF;

  -- 3. Update transaction
  UPDATE auction_transactions
  SET
    status = 'deal_failed',
    dispute_resolution = p_resolution,
    dispute_resolved_at = now(),
    dispute_resolved_by = p_admin_id,
    dispute_admin_notes = p_admin_notes,
    updated_at = now()
  WHERE id = p_transaction_id;

  -- 4. Timeline event
  INSERT INTO transaction_timeline (transaction_id, title, description, event_type, actor_id, actor_name)
  VALUES (
    p_transaction_id,
    'Dispute Resolved',
    COALESCE(v_resolution_desc, 'Dispute resolved by admin'),
    'completed',
    p_admin_id,
    COALESCE(v_admin_name, 'Admin')
  );

  -- 5. Notify both parties (wrapped in exception handler)
  BEGIN
    IF v_notif_type_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, type_id, title, message, data, is_read)
      VALUES
        (v_txn.seller_id, v_notif_type_id, 'Dispute Resolved', v_resolution_desc, jsonb_build_object('transaction_id', p_transaction_id, 'resolution', p_resolution, 'type', 'dispute_resolved'), false),
        (v_txn.buyer_id, v_notif_type_id, 'Dispute Resolved', v_resolution_desc, jsonb_build_object('transaction_id', p_transaction_id, 'resolution', p_resolution, 'type', 'dispute_resolved'), false);
    END IF;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  RETURN jsonb_build_object('success', true, 'resolution', p_resolution);
END;
$$;
