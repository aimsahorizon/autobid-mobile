-- ============================================================================
-- FIX: Token Initialization Error on User Registration
-- ============================================================================
-- This script fixes the "database error saving new users" issue
-- Run this in your Supabase SQL Editor
-- ============================================================================

-- Step 1: Drop existing trigger (if exists)
DROP TRIGGER IF EXISTS on_user_created_initialize_tokens ON auth.users;

-- Step 2: Recreate the function with proper error handling
CREATE OR REPLACE FUNCTION initialize_user_tokens()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert token balance (ignore if already exists)
    INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
    VALUES (NEW.id, 10, 1)
    ON CONFLICT (user_id) DO NOTHING;

    -- Insert free subscription (ignore if already exists)
    -- Note: The UNIQUE constraint is on (user_id, is_active) but only when is_active = true
    -- So we check if subscription already exists before inserting
    IF NOT EXISTS (
        SELECT 1 FROM user_subscriptions
        WHERE user_id = NEW.id AND is_active = true
    ) THEN
        INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
        VALUES (NEW.id, 'free', true, NOW());
    END IF;

    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail user creation
        RAISE WARNING 'Failed to initialize tokens for user %: %', NEW.id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Step 3: Recreate the trigger
CREATE TRIGGER on_user_created_initialize_tokens
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION initialize_user_tokens();

-- Step 4: Fix the triggers for updated_at (use correct function name)
DROP TRIGGER IF EXISTS update_user_token_balances_updated_at ON user_token_balances;
DROP TRIGGER IF EXISTS update_user_subscriptions_updated_at ON user_subscriptions;

CREATE TRIGGER update_user_token_balances_updated_at
    BEFORE UPDATE ON user_token_balances
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_user_subscriptions_updated_at
    BEFORE UPDATE ON user_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- Verification: Check if triggers are created successfully
-- ============================================================================
SELECT
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name IN (
    'on_user_created_initialize_tokens',
    'update_user_token_balances_updated_at',
    'update_user_subscriptions_updated_at'
);
