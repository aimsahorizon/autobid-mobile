-- ============================================================================
-- Migration 00161: Dispute Resolution System
-- When buyer rejects delivery AND seller objects, a dispute is raised.
-- Admin investigates (views chat, evidence) and resolves:
--   - Refund both deposits
--   - Penalize one party (suspension + refund both deposits)
-- ============================================================================

-- 1. Add dispute columns to auction_transactions
ALTER TABLE auction_transactions
  ADD COLUMN IF NOT EXISTS seller_objection_reason TEXT,
  ADD COLUMN IF NOT EXISTS seller_objected_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS dispute_resolution TEXT CHECK (
    dispute_resolution IN ('refund_both', 'penalize_seller', 'penalize_buyer')
  ),
  ADD COLUMN IF NOT EXISTS dispute_resolved_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS dispute_resolved_by UUID REFERENCES profiles(id),
  ADD COLUMN IF NOT EXISTS dispute_admin_notes TEXT;

-- 2. Add 'disputed' to the status CHECK constraint
-- First drop existing constraint, then re-add with 'disputed'
DO $$
BEGIN
  -- Try to drop existing constraint (name may vary)
  BEGIN
    ALTER TABLE auction_transactions DROP CONSTRAINT IF EXISTS auction_transactions_status_check;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  BEGIN
    ALTER TABLE auction_transactions DROP CONSTRAINT IF EXISTS valid_status;
  EXCEPTION WHEN OTHERS THEN NULL;
  END;

  -- Re-add with disputed status
  ALTER TABLE auction_transactions ADD CONSTRAINT valid_status
    CHECK (status IN ('in_transaction', 'sold', 'deal_failed', 'disputed'));
END $$;

-- 3. RPC: Seller raises objection to buyer rejection
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

  -- Buyer must have rejected (status = deal_failed, buyer_acceptance_status = rejected)
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
  SELECT display_name INTO v_seller_name FROM profiles WHERE id = p_seller_id;

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

  -- Notify admin via notifications table
  INSERT INTO notifications (user_id, title, body, type, data)
  SELECT
    p.id,
    'Dispute Raised',
    'A dispute has been raised for transaction ' || p_transaction_id::text,
    'dispute',
    jsonb_build_object(
      'transaction_id', p_transaction_id,
      'seller_id', p_seller_id,
      'type', 'dispute_raised'
    )
  FROM profiles p
  WHERE p.role = 'admin';

  RETURN jsonb_build_object('success', true);
END;
$$;

-- 4. RPC: Admin resolves dispute
-- resolution: 'refund_both' | 'penalize_seller' | 'penalize_buyer'
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
  v_suspension_days INT := 30; -- Default 30-day suspension for lying
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

  -- Validate resolution
  IF p_resolution NOT IN ('refund_both', 'penalize_seller', 'penalize_buyer') THEN
    RETURN jsonb_build_object('success', false, 'error', 'Invalid resolution type');
  END IF;

  -- If penalizing, must specify who
  IF p_resolution IN ('penalize_seller', 'penalize_buyer') AND p_penalized_user_id IS NULL THEN
    -- Auto-determine from resolution type
    IF p_resolution = 'penalize_seller' THEN
      p_penalized_user_id := v_txn.seller_id;
    ELSE
      p_penalized_user_id := v_txn.buyer_id;
    END IF;
  END IF;

  SELECT display_name INTO v_admin_name FROM profiles WHERE id = p_admin_id;

  -- 1. Refund BOTH deposits (regardless of resolution — deposits always returned)
  -- Refund seller deposit
  SELECT * INTO v_seller_deposit
  FROM auction_deposits
  WHERE auction_id = v_txn.auction_id
    AND user_id = v_txn.seller_id
    AND status = 'held';

  IF FOUND THEN
    UPDATE auction_deposits SET status = 'refunded', refunded_at = now()
    WHERE id = v_seller_deposit.id;

    UPDATE virtual_wallets
    SET balance = balance + v_seller_deposit.amount,
        updated_at = now()
    WHERE user_id = v_txn.seller_id;
  END IF;

  -- Refund buyer deposit
  SELECT * INTO v_buyer_deposit
  FROM auction_deposits
  WHERE auction_id = v_txn.auction_id
    AND user_id = v_txn.buyer_id
    AND status = 'held';

  IF FOUND THEN
    UPDATE auction_deposits SET status = 'refunded', refunded_at = now()
    WHERE id = v_buyer_deposit.id;

    UPDATE virtual_wallets
    SET balance = balance + v_buyer_deposit.amount,
        updated_at = now()
    WHERE user_id = v_txn.buyer_id;
  END IF;

  -- 2. If penalizing, suspend the user
  IF p_resolution IN ('penalize_seller', 'penalize_buyer') THEN
    SELECT display_name INTO v_penalized_name FROM profiles WHERE id = p_penalized_user_id;

    -- Insert suspension record
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

    -- Notify penalized user
    INSERT INTO notifications (user_id, title, body, type, data)
    VALUES (
      p_penalized_user_id,
      'Account Suspended',
      'Your account has been suspended for ' || v_suspension_days || ' days due to dispute resolution.',
      'suspension',
      jsonb_build_object(
        'transaction_id', p_transaction_id,
        'suspension_days', v_suspension_days,
        'type', 'dispute_penalty'
      )
    );
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
  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES
    (v_txn.seller_id, 'Dispute Resolved', v_resolution_desc, 'dispute', jsonb_build_object('transaction_id', p_transaction_id, 'resolution', p_resolution, 'type', 'dispute_resolved')),
    (v_txn.buyer_id, 'Dispute Resolved', v_resolution_desc, 'dispute', jsonb_build_object('transaction_id', p_transaction_id, 'resolution', p_resolution, 'type', 'dispute_resolved'));

  RETURN jsonb_build_object('success', true, 'resolution', p_resolution);
END;
$$;

-- 5. RPC: Get dispute details (chat history + evidence) for admin
CREATE OR REPLACE FUNCTION get_dispute_details(p_transaction_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_txn RECORD;
  v_chat JSONB;
  v_timeline JSONB;
  v_seller_name TEXT;
  v_buyer_name TEXT;
BEGIN
  SELECT * INTO v_txn FROM auction_transactions WHERE id = p_transaction_id;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('success', false, 'error', 'Transaction not found');
  END IF;

  SELECT display_name INTO v_seller_name FROM profiles WHERE id = v_txn.seller_id;
  SELECT display_name INTO v_buyer_name FROM profiles WHERE id = v_txn.buyer_id;

  -- Get full chat history
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', m.id,
      'sender_id', m.sender_id,
      'sender_name', m.sender_name,
      'message', m.message,
      'created_at', m.created_at,
      'message_type', m.message_type
    ) ORDER BY m.created_at ASC
  ), '[]'::jsonb)
  INTO v_chat
  FROM transaction_chat_messages m
  WHERE m.transaction_id = p_transaction_id;

  -- Get timeline
  SELECT COALESCE(jsonb_agg(
    jsonb_build_object(
      'id', t.id,
      'title', t.title,
      'description', t.description,
      'event_type', t.event_type,
      'actor_name', t.actor_name,
      'created_at', t.created_at
    ) ORDER BY t.created_at ASC
  ), '[]'::jsonb)
  INTO v_timeline
  FROM transaction_timeline t
  WHERE t.transaction_id = p_transaction_id;

  RETURN jsonb_build_object(
    'success', true,
    'transaction', jsonb_build_object(
      'id', v_txn.id,
      'auction_id', v_txn.auction_id,
      'seller_id', v_txn.seller_id,
      'buyer_id', v_txn.buyer_id,
      'seller_name', COALESCE(v_seller_name, 'Unknown'),
      'buyer_name', COALESCE(v_buyer_name, 'Unknown'),
      'agreed_price', v_txn.agreed_price,
      'status', v_txn.status,
      'buyer_rejection_reason', v_txn.buyer_rejection_reason,
      'buyer_rejection_photos', v_txn.buyer_rejection_photos,
      'seller_objection_reason', v_txn.seller_objection_reason,
      'seller_objected_at', v_txn.seller_objected_at,
      'dispute_resolution', v_txn.dispute_resolution,
      'dispute_resolved_at', v_txn.dispute_resolved_at,
      'dispute_admin_notes', v_txn.dispute_admin_notes,
      'created_at', v_txn.created_at
    ),
    'chat_history', v_chat,
    'timeline', v_timeline
  );
END;
$$;
