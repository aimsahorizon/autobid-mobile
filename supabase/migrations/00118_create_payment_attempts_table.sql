-- ============================================================================
-- Migration 00118: Create installment_payment_attempts table
-- Tracks submission history so rejections/resubmissions are preserved
-- ============================================================================

CREATE TABLE IF NOT EXISTS installment_payment_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  payment_id UUID NOT NULL REFERENCES installment_payments(id) ON DELETE CASCADE,
  attempt_number INTEGER NOT NULL DEFAULT 1,
  amount NUMERIC(12, 2) NOT NULL,
  proof_image_url TEXT,
  status TEXT NOT NULL DEFAULT 'submitted', -- submitted, confirmed, rejected
  rejection_reason TEXT,
  submitted_by UUID REFERENCES auth.users(id),
  acted_by UUID REFERENCES auth.users(id),
  acted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payment_attempts_payment
  ON installment_payment_attempts(payment_id);

-- RLS
ALTER TABLE installment_payment_attempts ENABLE ROW LEVEL SECURITY;

-- Select: transaction participants can read
CREATE POLICY payment_attempts_select ON installment_payment_attempts
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM installment_payments ip
      JOIN installment_plans ipl ON ipl.id = ip.installment_plan_id
      JOIN auction_transactions t ON t.id = ipl.transaction_id
      WHERE ip.id = installment_payment_attempts.payment_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- Insert: participants can insert
CREATE POLICY payment_attempts_insert ON installment_payment_attempts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM installment_payments ip
      JOIN installment_plans ipl ON ipl.id = ip.installment_plan_id
      JOIN auction_transactions t ON t.id = ipl.transaction_id
      WHERE ip.id = installment_payment_attempts.payment_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- Update: participants can update (for seller to set rejection/confirmation)
CREATE POLICY payment_attempts_update ON installment_payment_attempts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM installment_payments ip
      JOIN installment_plans ipl ON ipl.id = ip.installment_plan_id
      JOIN auction_transactions t ON t.id = ipl.transaction_id
      WHERE ip.id = installment_payment_attempts.payment_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );
