-- ============================================================================
-- AutoBid Mobile - Migration 00113: Create installment tracking tables
-- Supports installment payment plans for post-auction transactions
-- ============================================================================

-- Add payment_method column to auction_transactions table to track agreed payment type
ALTER TABLE auction_transactions
ADD COLUMN IF NOT EXISTS payment_method TEXT NOT NULL DEFAULT 'full_payment';
-- Possible values: 'full_payment', 'installment'

-- ============================================================================
-- Table: installment_plans
-- Linked to a transaction, tracks the overall installment agreement
-- ============================================================================
CREATE TABLE IF NOT EXISTS installment_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID NOT NULL REFERENCES auction_transactions(id) ON DELETE CASCADE,
  total_amount NUMERIC(12, 2) NOT NULL,
  down_payment NUMERIC(12, 2) NOT NULL DEFAULT 0,
  remaining_amount NUMERIC(12, 2) NOT NULL,
  total_paid NUMERIC(12, 2) NOT NULL DEFAULT 0,
  num_installments INTEGER NOT NULL DEFAULT 1,
  frequency TEXT NOT NULL DEFAULT 'monthly', -- weekly, bi-weekly, monthly
  start_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status TEXT NOT NULL DEFAULT 'active', -- active, completed, defaulted
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(transaction_id)
);

-- ============================================================================
-- Table: installment_payments
-- Individual payment records within an installment plan
-- ============================================================================
CREATE TABLE IF NOT EXISTS installment_payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  installment_plan_id UUID NOT NULL REFERENCES installment_plans(id) ON DELETE CASCADE,
  payment_number INTEGER NOT NULL,
  amount NUMERIC(12, 2) NOT NULL,
  due_date DATE NOT NULL,
  paid_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'pending', -- pending, submitted, confirmed, rejected
  proof_image_url TEXT,
  rejection_reason TEXT,
  submitted_by UUID REFERENCES auth.users(id),
  confirmed_by UUID REFERENCES auth.users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_installment_plans_transaction
  ON installment_plans(transaction_id);

CREATE INDEX IF NOT EXISTS idx_installment_payments_plan
  ON installment_payments(installment_plan_id);

CREATE INDEX IF NOT EXISTS idx_installment_payments_status
  ON installment_payments(status);

-- ============================================================================
-- RLS Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE installment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment_payments ENABLE ROW LEVEL SECURITY;

-- installment_plans: buyer and seller of the transaction can read
CREATE POLICY installment_plans_select ON installment_plans
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = installment_plans.transaction_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- installment_plans: only participants can insert (typically set during agreement)
CREATE POLICY installment_plans_insert ON installment_plans
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = installment_plans.transaction_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- installment_plans: participants can update
CREATE POLICY installment_plans_update ON installment_plans
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = installment_plans.transaction_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- installment_payments: buyer and seller can read
CREATE POLICY installment_payments_select ON installment_payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM installment_plans ip
      JOIN auction_transactions t ON t.id = ip.transaction_id
      WHERE ip.id = installment_payments.installment_plan_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- installment_payments: buyer can insert (submit payments)
CREATE POLICY installment_payments_insert ON installment_payments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM installment_plans ip
      JOIN auction_transactions t ON t.id = ip.transaction_id
      WHERE ip.id = installment_payments.installment_plan_id
        AND t.buyer_id = auth.uid()
    )
  );

-- installment_payments: both can update (buyer submits proof, seller confirms/rejects)
CREATE POLICY installment_payments_update ON installment_payments
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM installment_plans ip
      JOIN auction_transactions t ON t.id = ip.transaction_id
      WHERE ip.id = installment_payments.installment_plan_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- ============================================================================
-- Storage bucket for payment proof images
-- ============================================================================
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment-proofs', 'payment-proofs', false)
ON CONFLICT (id) DO NOTHING;

-- Storage policies for payment proofs
CREATE POLICY payment_proofs_upload ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'payment-proofs'
    AND auth.role() = 'authenticated'
  );

CREATE POLICY payment_proofs_read ON storage.objects
  FOR SELECT USING (
    bucket_id = 'payment-proofs'
    AND auth.role() = 'authenticated'
  );

-- ============================================================================
-- Trigger to auto-update installment plan totals when payments are confirmed
-- ============================================================================
CREATE OR REPLACE FUNCTION update_installment_plan_totals()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'confirmed' AND (OLD.status IS NULL OR OLD.status != 'confirmed') THEN
    UPDATE installment_plans
    SET total_paid = total_paid + NEW.amount,
        remaining_amount = remaining_amount - NEW.amount,
        updated_at = NOW(),
        status = CASE
          WHEN (total_paid + NEW.amount) >= total_amount THEN 'completed'
          ELSE status
        END
    WHERE id = NEW.installment_plan_id;
  END IF;

  -- If payment is rejected after being confirmed, reverse the totals
  IF NEW.status = 'rejected' AND OLD.status = 'confirmed' THEN
    UPDATE installment_plans
    SET total_paid = total_paid - OLD.amount,
        remaining_amount = remaining_amount + OLD.amount,
        updated_at = NOW(),
        status = 'active'
    WHERE id = NEW.installment_plan_id;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER trg_update_installment_totals
  AFTER UPDATE ON installment_payments
  FOR EACH ROW
  EXECUTE FUNCTION update_installment_plan_totals();

-- ============================================================================
-- Enable realtime for installment tables (safe — skip if already added)
-- ============================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'installment_plans'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE installment_plans;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'installment_payments'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE installment_payments;
  END IF;
END $$;
