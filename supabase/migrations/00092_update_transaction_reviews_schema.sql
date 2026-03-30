-- ============================================================================
-- AutoBid Mobile - Migration 00092: Update Transaction Reviews Schema
-- ============================================================================
-- Adds specific rating categories to transaction_reviews table.
-- ============================================================================

ALTER TABLE transaction_reviews
ADD COLUMN IF NOT EXISTS rating_communication INTEGER CHECK (rating_communication >= 1 AND rating_communication <= 5),
ADD COLUMN IF NOT EXISTS rating_reliability INTEGER CHECK (rating_reliability >= 1 AND rating_reliability <= 5);

COMMENT ON COLUMN transaction_reviews.rating IS 'Overall rating (1-5)';
COMMENT ON COLUMN transaction_reviews.rating_communication IS 'Rating for communication (1-5)';
COMMENT ON COLUMN transaction_reviews.rating_reliability IS 'Rating for reliability/punctuality (1-5)';
