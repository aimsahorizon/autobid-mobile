-- ============================================================================
-- AutoBid Mobile - Migration 00079: Add Seller Rejection Reason
-- ============================================================================
-- Adds seller_rejection_reason column to auction_transactions to allow sellers
-- to provide a reason when cancelling a deal.
-- ============================================================================

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'seller_rejection_reason'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN seller_rejection_reason TEXT;
    END IF;
END $$;
