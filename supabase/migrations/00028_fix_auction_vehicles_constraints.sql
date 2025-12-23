-- ============================================================================
-- AutoBid Mobile - Migration 00028: Fix auction_vehicles CHECK Constraints
-- Allow NULL values for optional numeric fields
-- Prevents check_violation errors during listing submission
-- ============================================================================

-- ============================================================================
-- CRITICAL ROOT CAUSE ANALYSIS:
-- ============================================================================
-- The auction_vehicles table has CHECK constraints that fail when NULL values
-- are inserted for optional fields like cylinder_count, horsepower, etc.
--
-- Example: cylinder_count > 0 fails when NULL is passed
-- PostgreSQL evaluates NULL > 0 as FALSE, causing constraint violation
--
-- These fields should be optional during listing creation since users may not
-- have complete vehicle specifications.
-- ============================================================================

-- ============================================================================
-- STEP 1: Drop all problematic constraints on auction_vehicles
-- ============================================================================

DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Loop through all check constraints on auction_vehicles table
    FOR constraint_record IN
        SELECT constraint_name
        FROM information_schema.table_constraints
        WHERE table_name = 'auction_vehicles'
        AND constraint_type = 'CHECK'
        AND table_schema = 'public'
    LOOP
        -- Drop each constraint
        EXECUTE 'ALTER TABLE auction_vehicles DROP CONSTRAINT IF EXISTS ' || quote_ident(constraint_record.constraint_name);
        RAISE NOTICE 'Dropped constraint: %', constraint_record.constraint_name;
    END LOOP;
END $$;

-- ============================================================================
-- STEP 2: Add new NULL-safe constraints
-- ============================================================================

-- Year constraint (required if provided, reasonable range)
ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_year_check
CHECK (year IS NULL OR (year >= 1900 AND year <= EXTRACT(YEAR FROM NOW()) + 1));

-- Mechanical specs (optional, but must be positive if provided)
ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_cylinder_count_check
CHECK (cylinder_count IS NULL OR cylinder_count > 0);

ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_horsepower_check
CHECK (horsepower IS NULL OR horsepower > 0);

ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_torque_check
CHECK (torque IS NULL OR torque > 0);

-- Capacity (optional, but must be positive if provided)
ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_seating_capacity_check
CHECK (seating_capacity IS NULL OR seating_capacity > 0);

ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_door_count_check
CHECK (door_count IS NULL OR door_count > 0);

-- Mileage and ownership (can be 0 for brand new cars)
ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_mileage_check
CHECK (mileage IS NULL OR mileage >= 0);

ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_previous_owners_check
CHECK (previous_owners IS NULL OR previous_owners >= 0);

-- AI confidence score (optional, but must be between 0 and 1 if provided)
ALTER TABLE auction_vehicles
ADD CONSTRAINT auction_vehicles_ai_price_confidence_check
CHECK (ai_price_confidence IS NULL OR (ai_price_confidence >= 0 AND ai_price_confidence <= 1));

-- ============================================================================
-- STEP 3: Update auction_photos category constraint to match actual usage
-- ============================================================================

-- Drop existing category constraint
ALTER TABLE auction_photos
DROP CONSTRAINT IF EXISTS auction_photos_category_check;

-- Add flexible category constraint (allow any string category from photo_urls JSONB)
-- Categories from listing_drafts.photo_urls can be any string, not just predefined values
ALTER TABLE auction_photos
ADD CONSTRAINT auction_photos_category_check
CHECK (category IS NOT NULL AND LENGTH(category) > 0);

-- ============================================================================
-- EXPLANATION:
-- ============================================================================
-- OLD CONSTRAINTS (from migration 00021):
--   cylinder_count > 0
--   horsepower > 0
--   torque > 0
--   seating_capacity > 0
--   door_count > 0
--   mileage >= 0
--   previous_owners >= 0
--   ai_price_confidence BETWEEN 0 AND 1
--   category IN ('exterior', 'interior', 'engine', 'damage', 'documents', 'other')
--
-- PROBLEM:
--   - When NULL values are passed for optional fields, PostgreSQL evaluates
--     NULL > 0 as FALSE, causing check_violation errors
--   - Category constraint was too restrictive - listing_drafts.photo_urls
--     uses custom category names (e.g., "Front View", "Dashboard", etc.)
--
-- NEW CONSTRAINTS:
--   - All numeric constraints now: field IS NULL OR field > 0
--   - Allows optional fields to be NULL during listing creation
--   - Category constraint now just checks category is not empty
--   - Validation still enforced where needed (year range, non-negative values)
-- ============================================================================

-- ============================================================================
-- VERIFICATION QUERY (run after migration):
-- ============================================================================
-- SELECT constraint_name, check_clause
-- FROM information_schema.check_constraints
-- WHERE constraint_schema = 'public'
-- AND constraint_name LIKE '%auction_vehicles%'
-- ORDER BY constraint_name;
-- ============================================================================

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
