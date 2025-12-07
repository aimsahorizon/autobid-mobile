# Fix: Account Creation Error

## Problem
**Error Message:** "failed to send email otp database error saving new users"

## Root Cause
The error occurs during user registration when the `initialize_user_tokens()` trigger fails after a new user is created in `auth.users` table. This happens due to:

1. **Function name mismatch**: The triggers referenced `update_updated_at_column()` but the actual function is named `update_updated_at()`
2. **Missing error handling**: The trigger would fail the entire user creation if token initialization failed
3. **Potential constraint conflicts**: The UNIQUE constraint on `user_subscriptions` could cause issues

## Solution

### Step 1: Run the Fix Script
Open your **Supabase SQL Editor** and run the following file:
```
sql/fix_token_initialization.sql
```

This script will:
- Drop and recreate the `initialize_user_tokens()` function with proper error handling
- Fix the trigger function names from `update_updated_at_column()` to `update_updated_at()`
- Add exception handling to prevent user creation failures
- Verify all triggers are properly created

### Step 2: Test Account Creation
After running the fix script:
1. Try creating a new account via the registration flow
2. The email OTP should now send successfully
3. User creation should complete without database errors
4. New users should automatically receive:
   - 10 bidding tokens
   - 1 listing token
   - Free subscription plan

## What Changed

### Before:
```sql
CREATE OR REPLACE FUNCTION initialize_user_tokens()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
    VALUES (NEW.id, 10, 1);

    INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
    VALUES (NEW.id, 'free', true, NOW());

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

### After:
```sql
CREATE OR REPLACE FUNCTION initialize_user_tokens()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert token balance (ignore if already exists)
    INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
    VALUES (NEW.id, 10, 1)
    ON CONFLICT (user_id) DO NOTHING;

    -- Insert free subscription (check if exists first)
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
```

## Key Improvements

1. **Error Handling**: Added `EXCEPTION` block to catch and log errors without failing user creation
2. **Conflict Resolution**: Uses `ON CONFLICT DO NOTHING` for token balances
3. **Existence Check**: Checks if subscription exists before inserting
4. **Graceful Degradation**: Even if token initialization fails, user account is still created

## Files Updated
- `sql/pricing_tokens.sql` - Fixed trigger function names and improved error handling
- `sql/fix_token_initialization.sql` - New fix script to apply changes to database
