-- ============================================================================
-- Migration 00119: Fix installment_payments INSERT RLS + remove consent columns
-- ============================================================================

-- Fix: Allow both buyer and seller to insert payment schedule rows
-- (Previously only buyer could insert, causing RLS error when seller's
-- plan creation/edit triggered schedule generation)
DROP POLICY IF EXISTS installment_payments_insert ON installment_payments;
CREATE POLICY installment_payments_insert ON installment_payments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM installment_plans ip
      JOIN auction_transactions t ON t.id = ip.transaction_id
      WHERE ip.id = installment_payments.installment_plan_id
        AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
    )
  );

-- Remove consent columns (plan locking now follows the general agreement flow)
ALTER TABLE installment_plans
  DROP COLUMN IF EXISTS buyer_confirmed_plan,
  DROP COLUMN IF EXISTS seller_confirmed_plan;
