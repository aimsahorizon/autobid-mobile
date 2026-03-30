-- Migration: 00105_transaction_agreement_system.sql
-- Date: 2026-02-21
-- Description:
--   1. Remove admin approval requirement - transactions auto-proceed after both confirm + 15s grace
--   2. Add collaborative agreement form system (shared dynamic fields)
--   3. Add lock/confirm/finalize flow with grace period
--   4. Reuse seller_form_submitted/buyer_form_submitted as lock flags
--   5. Add both_confirmed_at timestamp for 15s grace period tracking

-- ============================================================================
-- 1. Add grace period tracking to auction_transactions
-- ============================================================================
ALTER TABLE auction_transactions
  ADD COLUMN IF NOT EXISTS both_confirmed_at TIMESTAMPTZ;

COMMENT ON COLUMN auction_transactions.both_confirmed_at IS
  'Timestamp when both parties confirmed. After 15 seconds grace period, transaction auto-finalizes.';

-- ============================================================================
-- 2. Create transaction_agreement_fields table (collaborative form)
-- ============================================================================
CREATE TABLE IF NOT EXISTS transaction_agreement_fields (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES auction_transactions(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  value TEXT DEFAULT '',
  field_type TEXT NOT NULL DEFAULT 'text',
  category TEXT NOT NULL DEFAULT 'general',
  options TEXT,
  added_by UUID REFERENCES users(id),
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_agreement_fields_txn
  ON transaction_agreement_fields(transaction_id);

ALTER TABLE transaction_agreement_fields ENABLE ROW LEVEL SECURITY;

-- Both buyer and seller can CRUD
DROP POLICY IF EXISTS agreement_fields_select ON transaction_agreement_fields;
CREATE POLICY agreement_fields_select
  ON transaction_agreement_fields FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_agreement_fields.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS agreement_fields_insert ON transaction_agreement_fields;
CREATE POLICY agreement_fields_insert
  ON transaction_agreement_fields FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_agreement_fields.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS agreement_fields_update ON transaction_agreement_fields;
CREATE POLICY agreement_fields_update
  ON transaction_agreement_fields FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_agreement_fields.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS agreement_fields_delete ON transaction_agreement_fields;
CREATE POLICY agreement_fields_delete
  ON transaction_agreement_fields FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_agreement_fields.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

-- ============================================================================
-- 3. Finalize transaction RPC (called after 15s grace period)
-- ============================================================================
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

  -- Verify grace period has passed (15 seconds)
  IF v_txn.both_confirmed_at IS NULL OR
     NOW() < v_txn.both_confirmed_at + interval '15 seconds' THEN
    RETURN jsonb_build_object('success', false, 'error', 'Grace period has not elapsed');
  END IF;

  -- Finalize: reuse admin_approved to indicate "ready for delivery"
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

-- ============================================================================
-- 4. Enable realtime for agreement fields
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'transaction_agreement_fields'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE transaction_agreement_fields;
  END IF;
END $$;
