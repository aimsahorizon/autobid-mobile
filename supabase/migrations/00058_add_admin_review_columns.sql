-- ============================================================================
-- AutoBid Mobile - Migration 00058: Add Admin Review Columns
-- ============================================================================
-- Adds admin review columns to auction_transactions table
-- ============================================================================

-- Add admin_notes column if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'admin_notes'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN admin_notes TEXT;
    END IF;
END $$;

-- Add reviewed_by column if not exists
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'auction_transactions' AND column_name = 'reviewed_by'
    ) THEN
        ALTER TABLE auction_transactions ADD COLUMN reviewed_by UUID REFERENCES users(id);
    END IF;
END $$;

-- Create index for admin queries
CREATE INDEX IF NOT EXISTS idx_auction_transactions_admin_review 
  ON auction_transactions(admin_approved, seller_confirmed, buyer_confirmed);

-- Drop existing admin policies first, then recreate
DROP POLICY IF EXISTS "Admins can view all transactions" ON auction_transactions;
DROP POLICY IF EXISTS "Admins can update transactions" ON auction_transactions;

-- Allow admins to view all transaction data (using admin_users table)
CREATE POLICY "Admins can view all transactions"
  ON auction_transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      WHERE au.user_id = auth.uid()
      AND au.is_active = true
    )
  );

CREATE POLICY "Admins can update transactions"
  ON auction_transactions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      WHERE au.user_id = auth.uid()
      AND au.is_active = true
    )
  );

-- Policies for transaction_forms (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_forms') THEN
    DROP POLICY IF EXISTS "Admins can view all forms" ON transaction_forms;
    CREATE POLICY "Admins can view all forms"
      ON transaction_forms FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM admin_users au
          WHERE au.user_id = auth.uid()
          AND au.is_active = true
        )
      );
  END IF;
END $$;

-- Policies for transaction_chat_messages (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_chat_messages') THEN
    DROP POLICY IF EXISTS "Admins can view all chat" ON transaction_chat_messages;
    CREATE POLICY "Admins can view all chat"
      ON transaction_chat_messages FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM admin_users au
          WHERE au.user_id = auth.uid()
          AND au.is_active = true
        )
      );
  END IF;
END $$;

-- Policies for transaction_timeline (if table exists)
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'transaction_timeline') THEN
    DROP POLICY IF EXISTS "Admins can view all timeline" ON transaction_timeline;
    DROP POLICY IF EXISTS "Admins can insert timeline" ON transaction_timeline;
    
    CREATE POLICY "Admins can view all timeline"
      ON transaction_timeline FOR SELECT
      USING (
        EXISTS (
          SELECT 1 FROM admin_users au
          WHERE au.user_id = auth.uid()
          AND au.is_active = true
        )
      );
    
    CREATE POLICY "Admins can insert timeline"
      ON transaction_timeline FOR INSERT
      WITH CHECK (
        EXISTS (
          SELECT 1 FROM admin_users au
          WHERE au.user_id = auth.uid()
          AND au.is_active = true
        )
      );
  END IF;
END $$;
