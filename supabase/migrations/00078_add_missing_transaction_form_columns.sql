-- ============================================================================
-- AutoBid Mobile - Migration 00078: Add Missing Transaction Form Columns
-- ============================================================================
-- Adds missing columns to transaction_forms table to match application logic
-- ============================================================================

DO $$ 
BEGIN
    -- Shared Fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'contact_number') THEN
        ALTER TABLE transaction_forms ADD COLUMN contact_number TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'handover_time_slot') THEN
        ALTER TABLE transaction_forms ADD COLUMN handover_time_slot TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'pickup_or_delivery') THEN
        ALTER TABLE transaction_forms ADD COLUMN pickup_or_delivery TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'delivery_address') THEN
        ALTER TABLE transaction_forms ADD COLUMN delivery_address TEXT;
    END IF;

    -- Seller Specific Fields
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'release_of_mortgage') THEN
        ALTER TABLE transaction_forms ADD COLUMN release_of_mortgage BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'new_issues_disclosure') THEN
        ALTER TABLE transaction_forms ADD COLUMN new_issues_disclosure TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'fuel_level') THEN
        ALTER TABLE transaction_forms ADD COLUMN fuel_level TEXT;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'accessories_included') THEN
        ALTER TABLE transaction_forms ADD COLUMN accessories_included TEXT;
    END IF;

    -- Buyer Specific Fields (Acknowledgments)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'reviewed_vehicle_condition') THEN
        ALTER TABLE transaction_forms ADD COLUMN reviewed_vehicle_condition BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'understood_auction_terms') THEN
        ALTER TABLE transaction_forms ADD COLUMN understood_auction_terms BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'will_arrange_insurance') THEN
        ALTER TABLE transaction_forms ADD COLUMN will_arrange_insurance BOOLEAN DEFAULT FALSE;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'transaction_forms' AND column_name = 'accepts_as_is_condition') THEN
        ALTER TABLE transaction_forms ADD COLUMN accepts_as_is_condition BOOLEAN DEFAULT FALSE;
    END IF;

END $$;
