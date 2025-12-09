-- ============================================================================
-- AutoBid Mobile - Migration 00026: Fix Reserve Price CHECK Constraint
-- Allow NULL reserve_price OR enforce reserve_price >= starting_price
-- Prevents constraint violation when reserve_price is not set during draft save
-- ============================================================================

-- ============================================================================
-- CRITICAL ROOT CAUSE ANALYSIS:
-- ============================================================================
-- The listing_drafts table has inline CHECK constraints that were auto-named by PostgreSQL.
-- When a draft is saved with starting_price set but reserve_price = NULL,
-- the constraint "reserve_price >= starting_price" evaluates to NULL >= number,
-- which PostgreSQL treats as FALSE, causing the constraint violation.
--
-- Similarly for starting_price, if NULL is saved, "starting_price > 0" fails.
--
-- We must DROP the auto-generated constraints and recreate them with NULL allowance.
-- ============================================================================

-- ============================================================================
-- STEP 1: Find and drop ALL check constraints on listing_drafts
-- ============================================================================
-- This approach drops ALL check constraints, then recreates only the ones we need

DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Loop through all check constraints on listing_drafts table
    FOR constraint_record IN
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'listing_drafts'
        AND constraint_type = 'CHECK'
        AND table_schema = 'public'
    LOOP
        -- Drop each constraint
        EXECUTE 'ALTER TABLE listing_drafts DROP CONSTRAINT IF EXISTS ' || quote_ident(constraint_record.constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_record.constraint_name;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Add new flexible constraints that allow NULL values
-- ============================================================================

-- Add starting_price constraint (allow NULL OR must be > 0)
ALTER TABLE listing_drafts
ADD CONSTRAINT listing_drafts_starting_price_check
CHECK (starting_price IS NULL OR starting_price > 0);

-- Add reserve_price constraint (allow NULL OR must be >= starting_price)
-- CRITICAL: This allows reserve_price to be NULL while starting_price is set
ALTER TABLE listing_drafts
ADD CONSTRAINT listing_drafts_reserve_price_check
CHECK (reserve_price IS NULL OR (starting_price IS NOT NULL AND reserve_price >= starting_price));

-- Add ai_price_confidence constraint (allow NULL OR must be between 0 and 1)
ALTER TABLE listing_drafts
ADD CONSTRAINT listing_drafts_ai_price_confidence_check
CHECK (ai_price_confidence IS NULL OR (ai_price_confidence >= 0 AND ai_price_confidence <= 1));

-- ============================================================================
-- EXPLANATION OF FIX:
-- ============================================================================
-- OLD CONSTRAINTS (from migration 00018):
--   starting_price CHECK (starting_price > 0)
--   reserve_price CHECK (reserve_price >= starting_price)
--   ai_price_confidence CHECK (ai_price_confidence BETWEEN 0 AND 1)
--
-- PROBLEM:
--   When user fills Step 9 (Pricing) with starting_price = 100000 but leaves
--   reserve_price empty (NULL), the saveDraft() operation fails because:
--   NULL >= 100000 evaluates to NULL/FALSE in PostgreSQL
--
-- NEW CONSTRAINTS (this migration):
--   starting_price IS NULL OR starting_price > 0
--   reserve_price IS NULL OR (starting_price IS NOT NULL AND reserve_price >= starting_price)
--   ai_price_confidence IS NULL OR (ai_price_confidence >= 0 AND ai_price_confidence <= 1)
--
-- SOLUTION:
--   Drafts can now be saved with partial pricing data
--   Validation still enforced at submission in submit_listing_from_draft() RPC (line 39-44)
--   Users can set starting_price without setting reserve_price
-- ============================================================================

-- ============================================================================
-- VERIFICATION QUERY (run after migration):
-- ============================================================================
-- SELECT constraint_name, check_clause
-- FROM information_schema.check_constraints
-- WHERE constraint_schema = 'public'
-- AND constraint_name LIKE '%listing_drafts%'
-- ORDER BY constraint_name;
-- ============================================================================

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
