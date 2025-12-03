-- =====================================================
-- Payment Transactions Schema for PayMongo Integration
-- =====================================================
-- This schema stores payment transaction records
-- for token purchases and subscriptions
-- =====================================================

-- Create enum for payment status
CREATE TYPE payment_status AS ENUM (
  'pending',
  'processing',
  'succeeded',
  'failed',
  'cancelled',
  'refunded'
);

-- Create enum for payment method type
CREATE TYPE payment_method_type AS ENUM (
  'card',
  'gcash',
  'paymaya',
  'grab_pay'
);

-- Payment transactions table
CREATE TABLE IF NOT EXISTS payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- PayMongo payment details
  payment_intent_id TEXT, -- PayMongo payment intent ID
  payment_method_id TEXT, -- PayMongo payment method ID
  source_id TEXT, -- PayMongo source ID (for e-wallets)

  -- Transaction details
  amount DECIMAL(10, 2) NOT NULL, -- Amount in PHP
  currency TEXT NOT NULL DEFAULT 'PHP',
  status payment_status NOT NULL DEFAULT 'pending',
  payment_method payment_method_type NOT NULL,

  -- Item details
  item_type TEXT NOT NULL, -- 'token_package' or 'subscription'
  item_id TEXT NOT NULL, -- package_id or subscription plan
  description TEXT,

  -- Billing information
  billing_name TEXT,
  billing_email TEXT,
  billing_phone TEXT,

  -- Additional metadata
  metadata JSONB DEFAULT '{}'::jsonb,

  -- Payment gateway response
  paymongo_response JSONB, -- Store full PayMongo response
  error_message TEXT, -- Store error message if failed

  -- Timestamps
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_at TIMESTAMPTZ, -- When payment was completed

  -- Indexes
  CONSTRAINT valid_amount CHECK (amount > 0)
);

-- Indexes for better query performance
CREATE INDEX idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX idx_payment_transactions_payment_intent ON payment_transactions(payment_intent_id);
CREATE INDEX idx_payment_transactions_created_at ON payment_transactions(created_at DESC);

-- Updated timestamp trigger
CREATE TRIGGER update_payment_transactions_updated_at
  BEFORE UPDATE ON payment_transactions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- =====================================================
-- Helper Functions
-- =====================================================

-- Function to create a payment transaction
CREATE OR REPLACE FUNCTION create_payment_transaction(
  p_user_id UUID,
  p_amount DECIMAL,
  p_payment_method payment_method_type,
  p_item_type TEXT,
  p_item_id TEXT,
  p_description TEXT,
  p_billing_name TEXT DEFAULT NULL,
  p_billing_email TEXT DEFAULT NULL,
  p_billing_phone TEXT DEFAULT NULL,
  p_metadata JSONB DEFAULT '{}'::jsonb
) RETURNS UUID AS $$
DECLARE
  v_transaction_id UUID;
BEGIN
  INSERT INTO payment_transactions (
    user_id,
    amount,
    payment_method,
    item_type,
    item_id,
    description,
    billing_name,
    billing_email,
    billing_phone,
    metadata
  ) VALUES (
    p_user_id,
    p_amount,
    p_payment_method,
    p_item_type,
    p_item_id,
    p_description,
    p_billing_name,
    p_billing_email,
    p_billing_phone,
    p_metadata
  )
  RETURNING id INTO v_transaction_id;

  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update payment transaction with PayMongo IDs
CREATE OR REPLACE FUNCTION update_payment_transaction_ids(
  p_transaction_id UUID,
  p_payment_intent_id TEXT DEFAULT NULL,
  p_payment_method_id TEXT DEFAULT NULL,
  p_source_id TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  UPDATE payment_transactions
  SET
    payment_intent_id = COALESCE(p_payment_intent_id, payment_intent_id),
    payment_method_id = COALESCE(p_payment_method_id, payment_method_id),
    source_id = COALESCE(p_source_id, source_id),
    updated_at = NOW()
  WHERE id = p_transaction_id;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to update payment status
CREATE OR REPLACE FUNCTION update_payment_status(
  p_transaction_id UUID,
  p_status payment_status,
  p_paymongo_response JSONB DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
DECLARE
  v_user_id UUID;
  v_item_type TEXT;
  v_item_id TEXT;
  v_amount DECIMAL;
BEGIN
  -- Get transaction details
  SELECT user_id, item_type, item_id, amount
  INTO v_user_id, v_item_type, v_item_id, v_amount
  FROM payment_transactions
  WHERE id = p_transaction_id;

  -- Update transaction status
  UPDATE payment_transactions
  SET
    status = p_status,
    paymongo_response = COALESCE(p_paymongo_response, paymongo_response),
    error_message = p_error_message,
    paid_at = CASE WHEN p_status = 'succeeded' THEN NOW() ELSE paid_at END,
    updated_at = NOW()
  WHERE id = p_transaction_id;

  -- If payment succeeded, process the purchase
  IF p_status = 'succeeded' AND v_item_type = 'token_package' THEN
    -- Get package details from pricing repository
    -- This will be handled in the application layer
    -- Just mark the transaction as successful here
    NULL;
  END IF;

  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's payment history
CREATE OR REPLACE FUNCTION get_user_payment_history(
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
) RETURNS TABLE (
  id UUID,
  amount DECIMAL,
  status payment_status,
  payment_method payment_method_type,
  item_type TEXT,
  description TEXT,
  created_at TIMESTAMPTZ,
  paid_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    pt.id,
    pt.amount,
    pt.status,
    pt.payment_method,
    pt.item_type,
    pt.description,
    pt.created_at,
    pt.paid_at
  FROM payment_transactions pt
  WHERE pt.user_id = p_user_id
  ORDER BY pt.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- Row Level Security (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- Users can view their own payment transactions
CREATE POLICY payment_transactions_select_own
  ON payment_transactions
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users cannot insert payment transactions directly (use function)
CREATE POLICY payment_transactions_insert_none
  ON payment_transactions
  FOR INSERT
  WITH CHECK (false);

-- Users cannot update payment transactions directly (use function)
CREATE POLICY payment_transactions_update_none
  ON payment_transactions
  FOR UPDATE
  USING (false);

-- Users cannot delete payment transactions
CREATE POLICY payment_transactions_delete_none
  ON payment_transactions
  FOR DELETE
  USING (false);

-- =====================================================
-- Test Data (for development/testing)
-- =====================================================

-- Example test data (uncomment to add)
/*
-- Create a test payment transaction
SELECT create_payment_transaction(
  p_user_id := auth.uid(),
  p_amount := 99.00,
  p_payment_method := 'gcash'::payment_method_type,
  p_item_type := 'token_package',
  p_item_id := 'bidding_small',
  p_description := '5 Bidding Tokens',
  p_billing_name := 'Juan Dela Cruz',
  p_billing_email := 'juan@example.com',
  p_billing_phone := '+639171234567',
  p_metadata := '{"package_tokens": 5, "bonus_tokens": 0}'::jsonb
);
*/

-- =====================================================
-- PayMongo Webhook Events Table (Optional)
-- =====================================================
-- Store webhook events from PayMongo for audit trail

CREATE TABLE IF NOT EXISTS paymongo_webhook_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  event_id TEXT UNIQUE NOT NULL, -- PayMongo event ID
  event_type TEXT NOT NULL, -- payment.paid, payment.failed, etc.
  resource_type TEXT NOT NULL, -- payment_intent, source, etc.
  resource_id TEXT NOT NULL, -- ID of the resource
  payload JSONB NOT NULL, -- Full webhook payload
  processed BOOLEAN DEFAULT FALSE,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_webhook_events_event_id ON paymongo_webhook_events(event_id);
CREATE INDEX idx_webhook_events_processed ON paymongo_webhook_events(processed);
CREATE INDEX idx_webhook_events_created_at ON paymongo_webhook_events(created_at DESC);

-- =====================================================
-- Comments for documentation
-- =====================================================

COMMENT ON TABLE payment_transactions IS 'Stores all payment transactions for token purchases and subscriptions';
COMMENT ON COLUMN payment_transactions.payment_intent_id IS 'PayMongo Payment Intent ID for card payments';
COMMENT ON COLUMN payment_transactions.source_id IS 'PayMongo Source ID for e-wallet payments';
COMMENT ON COLUMN payment_transactions.metadata IS 'Additional metadata about the transaction';
COMMENT ON COLUMN payment_transactions.paymongo_response IS 'Full PayMongo API response for debugging';

COMMENT ON TABLE paymongo_webhook_events IS 'Stores webhook events from PayMongo for audit trail and debugging';
