-- ============================================================================
-- AutoBid Mobile - Migration 00080: Add Rejection Photos
-- ============================================================================
-- Adds column to store photo proof URL(s) when a buyer rejects a delivery
-- ============================================================================

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'buyer_rejection_photos'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN buyer_rejection_photos TEXT[];
    END IF;
END $$;
