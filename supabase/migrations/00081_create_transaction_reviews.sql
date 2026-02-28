-- ============================================================================
-- AutoBid Mobile - Migration 00081: Create Transaction Reviews
-- ============================================================================
-- Creates transaction_reviews table to allow buyers and sellers to rate each other.
-- ============================================================================

CREATE TABLE IF NOT EXISTS transaction_reviews (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES auction_transactions(id) ON DELETE CASCADE,
  reviewer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reviewee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint: one review per user per transaction
  UNIQUE(transaction_id, reviewer_id)
);

-- Index for reviews
CREATE INDEX idx_transaction_reviews_transaction_id ON transaction_reviews(transaction_id);
CREATE INDEX idx_transaction_reviews_reviewee_id ON transaction_reviews(reviewee_id);

-- RLS Policies
ALTER TABLE transaction_reviews ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view reviews"
  ON transaction_reviews FOR SELECT
  USING (true);

CREATE POLICY "Users can create their own reviews"
  ON transaction_reviews FOR INSERT
  WITH CHECK (
    reviewer_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_reviews.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
      AND t.status = 'sold'
    )
  );

CREATE POLICY "Users can update their own reviews"
  ON transaction_reviews FOR UPDATE
  USING (reviewer_id = auth.uid());

-- Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE transaction_reviews;
