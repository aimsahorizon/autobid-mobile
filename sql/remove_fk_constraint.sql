-- ============================================================================
-- REMOVE FOREIGN KEY CONSTRAINT TEMPORARILY
-- This allows users table to accept any UUID without checking auth.users
-- ============================================================================

-- Drop the foreign key constraint
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- The id column is still the primary key, just not linked to auth.users anymore
-- This allows registration to complete even if auth user doesn't exist yet

-- ============================================================================
-- DONE
-- Users table now accepts any UUID for id column
-- ============================================================================
