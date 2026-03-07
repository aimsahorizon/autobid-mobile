-- ============================================================================
-- Migration 00116: Add two-way consent columns to installment_plans
-- Both buyer and seller must confirm the plan before it becomes active
-- ============================================================================

ALTER TABLE installment_plans
ADD COLUMN IF NOT EXISTS buyer_confirmed_plan BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS seller_confirmed_plan BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS proposed_by UUID REFERENCES auth.users(id);

-- Backfill: existing plans (created before consent feature) should be treated as confirmed
UPDATE installment_plans
SET buyer_confirmed_plan = TRUE, seller_confirmed_plan = TRUE
WHERE buyer_confirmed_plan = FALSE AND seller_confirmed_plan = FALSE;

-- installment_payments: allow participants to delete (needed for plan re-editing)
DROP POLICY IF EXISTS installment_payments_delete ON installment_payments;
CREATE POLICY installment_payments_delete ON installment_payments
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM installment_plans ip
      JOIN auction_transactions t ON t.id = ip.transaction_id
      WHERE ip.id = installment_payments.installment_plan_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );
