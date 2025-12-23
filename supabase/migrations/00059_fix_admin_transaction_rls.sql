-- ============================================================================
-- AutoBid Mobile - Migration 00059: Fix Admin Transaction RLS
-- ============================================================================
-- Fixes admin RLS policies to check admin_users table instead of users.role
-- ============================================================================

-- Drop existing admin policies if they exist (from migration 00058)
DROP POLICY IF EXISTS "Admins can view all transactions" ON auction_transactions;
DROP POLICY IF EXISTS "Admins can update transactions" ON auction_transactions;
DROP POLICY IF EXISTS "Admins can view all forms" ON transaction_forms;
DROP POLICY IF EXISTS "Admins can view all chat" ON transaction_chat_messages;
DROP POLICY IF EXISTS "Admins can view all timeline" ON transaction_timeline;
DROP POLICY IF EXISTS "Admins can insert timeline" ON transaction_timeline;

-- Recreate admin policies using admin_users table
-- Admins can view ALL transactions
CREATE POLICY "Admins can view all transactions"
  ON auction_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      WHERE au.user_id = auth.uid()
      AND au.is_active = true
    )
  );

-- Admins can update ANY transaction
CREATE POLICY "Admins can update transactions"
  ON auction_transactions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      WHERE au.user_id = auth.uid()
      AND au.is_active = true
    )
  );

-- Check if transaction_forms table exists before creating policy
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_forms') THEN
    EXECUTE '
      CREATE POLICY "Admins can view all forms"
        ON transaction_forms FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM admin_users au
            WHERE au.user_id = auth.uid()
            AND au.is_active = true
          )
        )
    ';
  END IF;
END $$;

-- Check if transaction_chat_messages table exists before creating policy
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_chat_messages') THEN
    EXECUTE '
      CREATE POLICY "Admins can view all chat"
        ON transaction_chat_messages FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM admin_users au
            WHERE au.user_id = auth.uid()
            AND au.is_active = true
          )
        )
    ';
  END IF;
END $$;

-- Check if transaction_timeline table exists before creating policy
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_timeline') THEN
    EXECUTE '
      CREATE POLICY "Admins can view all timeline"
        ON transaction_timeline FOR SELECT
        USING (
          EXISTS (
            SELECT 1 FROM admin_users au
            WHERE au.user_id = auth.uid()
            AND au.is_active = true
          )
        )
    ';
    
    EXECUTE '
      CREATE POLICY "Admins can insert timeline"
        ON transaction_timeline FOR INSERT
        WITH CHECK (
          EXISTS (
            SELECT 1 FROM admin_users au
            WHERE au.user_id = auth.uid()
            AND au.is_active = true
          )
        )
    ';
  END IF;
END $$;

-- ============================================================================
-- Debug: Check current transaction count
-- ============================================================================
-- Run this to verify transactions exist:
-- SELECT COUNT(*) FROM auction_transactions;
-- SELECT * FROM auction_transactions LIMIT 5;
