-- ============================================================================
-- Migration 00127: SECURITY DEFINER RPC functions for installment payments
-- Fixes RLS chain issue where nested policy sub-queries on installment_payments
-- fail to resolve through installment_plans → auction_transactions.
-- ============================================================================

-- ============================================================================
-- 1. Generate payment schedule (bypasses RLS, verifies participant)
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_installment_schedule(
  p_plan_id UUID,
  p_down_payment NUMERIC,
  p_remaining NUMERIC,
  p_num_installments INTEGER,
  p_frequency TEXT,
  p_start_date DATE
)
RETURNS SETOF installment_payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_per_payment NUMERIC;
  v_due_date DATE;
  v_amount NUMERIC;
BEGIN
  -- Verify the caller is a participant in the transaction
  IF NOT EXISTS (
    SELECT 1 FROM installment_plans ip
    JOIN auction_transactions t ON t.id = ip.transaction_id
    WHERE ip.id = p_plan_id
      AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
  ) THEN
    RAISE EXCEPTION 'Unauthorized: not a transaction participant';
  END IF;

  -- Delete any existing payments for this plan (handles re-generation)
  DELETE FROM installment_payments WHERE installment_plan_id = p_plan_id;

  -- Calculate per-payment amount
  v_per_payment := FLOOR(p_remaining / p_num_installments);

  -- Down payment (payment #0) with 3-day grace
  IF p_down_payment > 0 THEN
    INSERT INTO installment_payments (installment_plan_id, payment_number, amount, due_date, status)
    VALUES (p_plan_id, 0, p_down_payment, p_start_date + INTERVAL '3 days', 'pending');
  END IF;

  -- Regular installments
  FOR i IN 1..p_num_installments LOOP
    -- Calculate due date
    IF p_frequency = 'no_schedule' THEN
      v_due_date := '9999-12-31'::DATE;
    ELSIF p_frequency = 'weekly' THEN
      v_due_date := p_start_date + (7 * i) * INTERVAL '1 day';
    ELSIF p_frequency = 'bi-weekly' THEN
      v_due_date := p_start_date + (14 * i) * INTERVAL '1 day';
    ELSE -- monthly (default)
      v_due_date := p_start_date + (i || ' months')::INTERVAL;
    END IF;

    -- Last payment gets rounding remainder
    IF i = p_num_installments THEN
      v_amount := p_remaining - (v_per_payment * (p_num_installments - 1));
    ELSE
      v_amount := v_per_payment;
    END IF;

    INSERT INTO installment_payments (installment_plan_id, payment_number, amount, due_date, status)
    VALUES (p_plan_id, i, v_amount, v_due_date, 'pending');
  END LOOP;

  -- Return all generated payments
  RETURN QUERY
    SELECT * FROM installment_payments
    WHERE installment_plan_id = p_plan_id
    ORDER BY payment_number;
END;
$$;

-- ============================================================================
-- 2. Fetch payments for a plan (bypasses RLS, verifies participant)
-- ============================================================================
CREATE OR REPLACE FUNCTION get_plan_payments(p_plan_id UUID)
RETURNS SETOF installment_payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify the caller is a participant in the transaction
  IF NOT EXISTS (
    SELECT 1 FROM installment_plans ip
    JOIN auction_transactions t ON t.id = ip.transaction_id
    WHERE ip.id = p_plan_id
      AND (t.buyer_id = auth.uid() OR t.seller_id = auth.uid())
  ) THEN
    RETURN; -- Return empty set for unauthorized
  END IF;

  RETURN QUERY
    SELECT * FROM installment_payments
    WHERE installment_plan_id = p_plan_id
    ORDER BY payment_number;
END;
$$;

-- ============================================================================
-- 3. Add missing DELETE policy on installment_payments
--    (needed by updatePlan which deletes old schedule before regenerating)
-- ============================================================================
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

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION generate_installment_schedule TO authenticated;
GRANT EXECUTE ON FUNCTION get_plan_payments TO authenticated;

-- ============================================================================
-- 4. Fix INSERT policy: allow both buyer AND seller to insert payments
--    (original policy only allowed buyer, blocking seller-proposed plans)
-- ============================================================================
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

-- ============================================================================
-- 5. Trigger: auto-generate payment schedule when a plan is inserted
--    Runs as SECURITY DEFINER to bypass RLS on installment_payments.
--    Also sets payment_method = 'installment' on the transaction.
-- ============================================================================
CREATE OR REPLACE FUNCTION auto_generate_installment_payments()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_per_payment NUMERIC;
  v_due_date DATE;
  v_amount NUMERIC;
BEGIN
  -- Calculate per-payment amount
  v_per_payment := FLOOR(NEW.remaining_amount / NEW.num_installments);

  -- Down payment (payment #0) with 3-day grace period
  IF NEW.down_payment > 0 THEN
    INSERT INTO installment_payments (installment_plan_id, payment_number, amount, due_date, status)
    VALUES (NEW.id, 0, NEW.down_payment, NEW.start_date + INTERVAL '3 days', 'pending');
  END IF;

  -- Regular installments
  FOR i IN 1..NEW.num_installments LOOP
    -- Calculate due date based on frequency
    IF NEW.frequency = 'no_schedule' THEN
      v_due_date := '9999-12-31'::DATE;
    ELSIF NEW.frequency = 'weekly' THEN
      v_due_date := NEW.start_date + (7 * i) * INTERVAL '1 day';
    ELSIF NEW.frequency = 'bi-weekly' THEN
      v_due_date := NEW.start_date + (14 * i) * INTERVAL '1 day';
    ELSE -- monthly (default)
      v_due_date := NEW.start_date + (i || ' months')::INTERVAL;
    END IF;

    -- Last payment gets rounding remainder
    IF i = NEW.num_installments THEN
      v_amount := NEW.remaining_amount - (v_per_payment * (NEW.num_installments - 1));
    ELSE
      v_amount := v_per_payment;
    END IF;

    INSERT INTO installment_payments (installment_plan_id, payment_number, amount, due_date, status)
    VALUES (NEW.id, i, v_amount, v_due_date, 'pending');
  END LOOP;

  -- Auto-set payment method on the transaction
  UPDATE auction_transactions
  SET payment_method = 'installment'
  WHERE id = NEW.transaction_id;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_generate_installment_payments ON installment_plans;
CREATE TRIGGER trg_auto_generate_installment_payments
  AFTER INSERT ON installment_plans
  FOR EACH ROW
  EXECUTE FUNCTION auto_generate_installment_payments();
