-- ============================================================================
-- Migration 00164: Fix resolve_dispute RPC table references
-- Uses existing refund_deposit() and record_penalty() functions
-- ============================================================================

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
  v_resolution_desc TEXT;
  v_notif_type_id UUID;
  v_penalty_result JSON;
  v_seller_refunded BOOLEAN;
  v_buyer_refunded BOOLEAN;
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

  -- Auto-determine penalized user from resolution type
  IF p_resolution = 'penalize_seller' THEN
    p_penalized_user_id := v_txn.seller_id;
  ELSIF p_resolution = 'penalize_buyer' THEN
    p_penalized_user_id := v_txn.buyer_id;
  END IF;

  SELECT full_name INTO v_admin_name FROM users WHERE id = p_admin_id;

  -- Get notification type
  BEGIN
    SELECT id INTO v_notif_type_id FROM notification_types WHERE type_name = 'transaction_update' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    v_notif_type_id := NULL;
  END;

  -- 1. Refund both deposits using the existing refund_deposit() function
  BEGIN
    v_seller_refunded := refund_deposit(v_txn.auction_id, v_txn.seller_id);
  EXCEPTION WHEN OTHERS THEN
    v_seller_refunded := FALSE;
  END;

  BEGIN
    v_buyer_refunded := refund_deposit(v_txn.auction_id, v_txn.buyer_id);
  EXCEPTION WHEN OTHERS THEN
    v_buyer_refunded := FALSE;
  END;

  -- 2. If penalizing, use record_penalty()
  IF p_resolution IN ('penalize_seller', 'penalize_buyer') THEN
    BEGIN
      v_penalty_result := record_penalty(
        p_user_id := p_penalized_user_id,
        p_reason := 'Dispute resolution: found at fault in transaction ' || p_transaction_id::text,
        p_transaction_id := p_transaction_id,
        p_auction_id := v_txn.auction_id
      );
    EXCEPTION WHEN OTHERS THEN
      v_penalty_result := NULL;
    END;

    v_resolution_desc := 'Dispute resolved: ' ||
      CASE p_resolution
        WHEN 'penalize_seller' THEN 'Seller penalized (suspended). '
        WHEN 'penalize_buyer' THEN 'Buyer penalized (suspended). '
      END ||
      'Both deposits refunded.';

    -- Notify penalized user
    BEGIN
      IF v_notif_type_id IS NOT NULL THEN
        INSERT INTO notifications (user_id, type_id, title, message, data, is_read)
        VALUES (
          p_penalized_user_id,
          v_notif_type_id,
          'Account Suspended',
          'Your account has been suspended due to dispute resolution.',
          jsonb_build_object(
            'transaction_id', p_transaction_id,
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

  -- 5. Notify both parties
  BEGIN
    IF v_notif_type_id IS NOT NULL THEN
      INSERT INTO notifications (user_id, type_id, title, message, data, is_read)
      VALUES
        (v_txn.seller_id, v_notif_type_id, 'Dispute Resolved', v_resolution_desc, jsonb_build_object('transaction_id', p_transaction_id, 'resolution', p_resolution, 'type', 'dispute_resolved'), false),
        (v_txn.buyer_id, v_notif_type_id, 'Dispute Resolved', v_resolution_desc, jsonb_build_object('transaction_id', p_transaction_id, 'resolution', p_resolution, 'type', 'dispute_resolved'), false);
    END IF;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  RETURN jsonb_build_object(
    'success', true,
    'resolution', p_resolution,
    'seller_deposit_refunded', COALESCE(v_seller_refunded, false),
    'buyer_deposit_refunded', COALESCE(v_buyer_refunded, false)
  );
END;
$$;
