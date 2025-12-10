-- Drop old policies if they exist
DROP POLICY IF EXISTS "Sellers view own transactions" ON auction_transactions;
DROP POLICY IF EXISTS "Buyers view own transactions" ON auction_transactions;
DROP POLICY IF EXISTS "Sellers update own transactions" ON auction_transactions;
DROP POLICY IF EXISTS "Buyers update own transactions" ON auction_transactions;

-- Create new policies with correct column names
CREATE POLICY "Sellers view own transactions"
  ON auction_transactions
  FOR SELECT
  USING (seller_id = auth.uid());

CREATE POLICY "Buyers view own transactions"
  ON auction_transactions
  FOR SELECT
  USING (buyer_id = auth.uid());

CREATE POLICY "Sellers update own transactions"
  ON auction_transactions
  FOR UPDATE
  USING (seller_id = auth.uid())
  WITH CHECK (seller_id = auth.uid());

CREATE POLICY "Buyers update own transactions"
  ON auction_transactions
  FOR UPDATE
  USING (buyer_id = auth.uid())
  WITH CHECK (buyer_id = auth.uid());

CREATE POLICY "Allow trigger inserts"
  ON auction_transactions
  FOR INSERT
  WITH CHECK (true);