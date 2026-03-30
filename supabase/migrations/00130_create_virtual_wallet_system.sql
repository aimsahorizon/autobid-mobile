-- ============================================================================
-- AutoBid Mobile - Migration 00130: Create Virtual Wallet System
-- Demo virtual wallet that acts as a bank account for all payments
-- ============================================================================

-- Virtual Wallets table
CREATE TABLE IF NOT EXISTS virtual_wallets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  balance DECIMAL(12,2) NOT NULL DEFAULT 100000.00,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(user_id)
);

-- Virtual Wallet Transactions table
CREATE TABLE IF NOT EXISTS virtual_wallet_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  wallet_id UUID NOT NULL REFERENCES virtual_wallets(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount DECIMAL(12,2) NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('credit', 'debit')),
  category TEXT NOT NULL CHECK (category IN ('deposit', 'deposit_return', 'token_purchase', 'subscription', 'top_up', 'withdrawal')),
  reference_id TEXT,
  description TEXT,
  balance_after DECIMAL(12,2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE virtual_wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE virtual_wallet_transactions ENABLE ROW LEVEL SECURITY;

-- Update category CHECK constraint to include 'withdrawal' (safe for re-runs)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.constraint_column_usage
    WHERE table_name = 'virtual_wallet_transactions'
      AND constraint_name = 'virtual_wallet_transactions_category_check'
  ) THEN
    ALTER TABLE virtual_wallet_transactions DROP CONSTRAINT virtual_wallet_transactions_category_check;
  END IF;
  ALTER TABLE virtual_wallet_transactions ADD CONSTRAINT virtual_wallet_transactions_category_check
    CHECK (category IN ('deposit', 'deposit_return', 'token_purchase', 'subscription', 'top_up', 'withdrawal'));
END $$;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own wallet" ON virtual_wallets;
CREATE POLICY "Users can view own wallet"
  ON virtual_wallets FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can view own transactions" ON virtual_wallet_transactions;
CREATE POLICY "Users can view own transactions"
  ON virtual_wallet_transactions FOR SELECT
  USING (auth.uid() = user_id);

-- Index
CREATE INDEX IF NOT EXISTS idx_vw_transactions_wallet ON virtual_wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_vw_transactions_user ON virtual_wallet_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_vw_transactions_category ON virtual_wallet_transactions(category);

-- Function: Get or create wallet for user
CREATE OR REPLACE FUNCTION get_or_create_wallet(p_user_id UUID)
RETURNS TABLE(wallet_id UUID, balance DECIMAL) AS $$
DECLARE
  v_wallet_id UUID;
  v_balance DECIMAL;
BEGIN
  SELECT vw.id, vw.balance INTO v_wallet_id, v_balance
  FROM virtual_wallets vw WHERE vw.user_id = p_user_id;

  IF v_wallet_id IS NULL THEN
    INSERT INTO virtual_wallets (user_id, balance)
    VALUES (p_user_id, 100000.00)
    RETURNING virtual_wallets.id, virtual_wallets.balance INTO v_wallet_id, v_balance;
  END IF;

  RETURN QUERY SELECT v_wallet_id, v_balance;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Debit from wallet
CREATE OR REPLACE FUNCTION wallet_debit(
  p_user_id UUID,
  p_amount DECIMAL,
  p_category TEXT,
  p_reference_id TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, new_balance DECIMAL, transaction_id UUID) AS $$
DECLARE
  v_wallet_id UUID;
  v_balance DECIMAL;
  v_new_balance DECIMAL;
  v_txn_id UUID;
BEGIN
  -- Get or create wallet
  SELECT vw.id, vw.balance INTO v_wallet_id, v_balance
  FROM virtual_wallets vw WHERE vw.user_id = p_user_id FOR UPDATE;

  IF v_wallet_id IS NULL THEN
    INSERT INTO virtual_wallets (user_id, balance)
    VALUES (p_user_id, 100000.00)
    RETURNING virtual_wallets.id, virtual_wallets.balance INTO v_wallet_id, v_balance;
  END IF;

  -- Check sufficient balance
  IF v_balance < p_amount THEN
    RETURN QUERY SELECT FALSE, 'Insufficient wallet balance'::TEXT, v_balance, NULL::UUID;
    RETURN;
  END IF;

  v_new_balance := v_balance - p_amount;

  -- Update balance
  UPDATE virtual_wallets SET balance = v_new_balance, updated_at = NOW()
  WHERE id = v_wallet_id;

  -- Record transaction
  INSERT INTO virtual_wallet_transactions (wallet_id, user_id, amount, type, category, reference_id, description, balance_after)
  VALUES (v_wallet_id, p_user_id, p_amount, 'debit', p_category, p_reference_id, p_description, v_new_balance)
  RETURNING virtual_wallet_transactions.id INTO v_txn_id;

  RETURN QUERY SELECT TRUE, 'Payment successful'::TEXT, v_new_balance, v_txn_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Credit to wallet (for deposit returns, top-ups)
CREATE OR REPLACE FUNCTION wallet_credit(
  p_user_id UUID,
  p_amount DECIMAL,
  p_category TEXT,
  p_reference_id TEXT DEFAULT NULL,
  p_description TEXT DEFAULT NULL
)
RETURNS TABLE(success BOOLEAN, message TEXT, new_balance DECIMAL, transaction_id UUID) AS $$
DECLARE
  v_wallet_id UUID;
  v_balance DECIMAL;
  v_new_balance DECIMAL;
  v_txn_id UUID;
BEGIN
  -- Get or create wallet
  SELECT vw.id, vw.balance INTO v_wallet_id, v_balance
  FROM virtual_wallets vw WHERE vw.user_id = p_user_id FOR UPDATE;

  IF v_wallet_id IS NULL THEN
    INSERT INTO virtual_wallets (user_id, balance)
    VALUES (p_user_id, 100000.00)
    RETURNING virtual_wallets.id, virtual_wallets.balance INTO v_wallet_id, v_balance;
  END IF;

  v_new_balance := v_balance + p_amount;

  -- Update balance
  UPDATE virtual_wallets SET balance = v_new_balance, updated_at = NOW()
  WHERE id = v_wallet_id;

  -- Record transaction
  INSERT INTO virtual_wallet_transactions (wallet_id, user_id, amount, type, category, reference_id, description, balance_after)
  VALUES (v_wallet_id, p_user_id, p_amount, 'credit', p_category, p_reference_id, p_description, v_new_balance)
  RETURNING virtual_wallet_transactions.id INTO v_txn_id;

  RETURN QUERY SELECT TRUE, 'Credit successful'::TEXT, v_new_balance, v_txn_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Return deposits to all bidders when auction ends
CREATE OR REPLACE FUNCTION return_auction_deposits(p_auction_id UUID)
RETURNS TABLE(user_id UUID, amount DECIMAL, success BOOLEAN) AS $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT d.user_id AS uid, d.amount AS dep_amount
    FROM deposits d
    WHERE d.auction_id = p_auction_id
      AND d.is_refunded = FALSE
  LOOP
    -- Credit each depositor's wallet
    PERFORM wallet_credit(
      r.uid,
      r.dep_amount,
      'deposit_return',
      p_auction_id::TEXT,
      'Deposit returned for ended auction'
    );

    -- Mark deposit as refunded
    UPDATE deposits
    SET is_refunded = TRUE, refunded_at = NOW()
    WHERE auction_id = p_auction_id AND deposits.user_id = r.uid;

    RETURN QUERY SELECT r.uid, r.dep_amount, TRUE;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function: Get wallet transaction history
CREATE OR REPLACE FUNCTION get_wallet_transactions(
  p_user_id UUID,
  p_limit INT DEFAULT 50,
  p_offset INT DEFAULT 0
)
RETURNS TABLE(
  id UUID,
  amount DECIMAL,
  type TEXT,
  category TEXT,
  reference_id TEXT,
  description TEXT,
  balance_after DECIMAL,
  created_at TIMESTAMPTZ
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    vwt.id, vwt.amount, vwt.type, vwt.category,
    vwt.reference_id, vwt.description, vwt.balance_after, vwt.created_at
  FROM virtual_wallet_transactions vwt
  WHERE vwt.user_id = p_user_id
  ORDER BY vwt.created_at DESC
  LIMIT p_limit OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Override end_auction to also return deposits to wallets
CREATE OR REPLACE FUNCTION end_auction(p_auction_id UUID)
RETURNS JSON AS $$
DECLARE
  v_ended_status_id UUID;
  v_sold_status_id UUID;
  v_unsold_status_id UUID;
  v_won_status_id UUID;
  v_lost_status_id UUID;
  v_winning_bid RECORD;
  result JSON;
BEGIN
  SELECT id INTO v_ended_status_id FROM auction_statuses WHERE status_name = 'ended';
  SELECT id INTO v_sold_status_id FROM auction_statuses WHERE status_name = 'sold';
  SELECT id INTO v_unsold_status_id FROM auction_statuses WHERE status_name = 'unsold';
  SELECT id INTO v_won_status_id FROM bid_statuses WHERE status_name = 'won';
  SELECT id INTO v_lost_status_id FROM bid_statuses WHERE status_name = 'lost';

  SELECT * INTO v_winning_bid
  FROM bids
  WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC
  LIMIT 1;

  IF v_winning_bid IS NOT NULL THEN
    UPDATE auctions SET status_id = v_sold_status_id WHERE id = p_auction_id;
    UPDATE bids SET status_id = v_won_status_id WHERE id = v_winning_bid.id;
    UPDATE bids SET status_id = v_lost_status_id
    WHERE auction_id = p_auction_id AND id != v_winning_bid.id;

    result := json_build_object('success', TRUE, 'winner_id', v_winning_bid.bidder_id, 'winning_amount', v_winning_bid.bid_amount);
  ELSE
    UPDATE auctions SET status_id = v_unsold_status_id WHERE id = p_auction_id;
    result := json_build_object('success', TRUE, 'winner_id', NULL, 'winning_amount', NULL);
  END IF;

  -- Return all deposits to bidders' virtual wallets
  PERFORM return_auction_deposits(p_auction_id);

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
