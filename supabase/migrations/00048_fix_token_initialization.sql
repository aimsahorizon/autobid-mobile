-- ============================================================================
-- AutoBid Mobile - Migration 00048: Fix token initialization
-- Ensures all users get default tokens regardless of when they're created
-- ============================================================================

-- Drop the old trigger on auth.users
DROP TRIGGER IF EXISTS on_user_created_initialize_tokens ON auth.users;

-- Create new trigger on public.users table instead
DROP TRIGGER IF EXISTS on_public_user_created_initialize_tokens ON users;

CREATE TRIGGER on_public_user_created_initialize_tokens
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION initialize_user_tokens();

-- Backfill: Initialize tokens for existing users who don't have them
DO $$
DECLARE
  user_record RECORD;
  v_balance_exists BOOLEAN;
  v_subscription_exists BOOLEAN;
BEGIN
  FOR user_record IN SELECT id FROM users
  LOOP
    -- Check if user already has token balance
    SELECT EXISTS(
      SELECT 1 FROM user_token_balances WHERE user_id = user_record.id
    ) INTO v_balance_exists;
    
    -- Check if user already has subscription
    SELECT EXISTS(
      SELECT 1 FROM user_subscriptions WHERE user_id = user_record.id AND is_active = TRUE
    ) INTO v_subscription_exists;

    -- Create token balance if missing
    IF NOT v_balance_exists THEN
      INSERT INTO user_token_balances (user_id, bidding_tokens, listing_tokens)
      VALUES (user_record.id, 10, 1)
      ON CONFLICT (user_id) DO NOTHING;
      
      RAISE NOTICE 'Created token balance for user %', user_record.id;
    END IF;

    -- Create free subscription if missing
    IF NOT v_subscription_exists THEN
      INSERT INTO user_subscriptions (user_id, plan, is_active, start_date)
      VALUES (user_record.id, 'free', TRUE, NOW())
      ON CONFLICT DO NOTHING;
      
      RAISE NOTICE 'Created subscription for user %', user_record.id;
    END IF;
  END LOOP;
END $$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
