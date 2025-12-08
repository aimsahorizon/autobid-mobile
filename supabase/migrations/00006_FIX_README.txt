-- ============================================================================
-- QUICK FIX REFERENCE: KYC Registration Database Error
-- ============================================================================

-- ERROR:
-- StorageException: infinite recursion detected in policy for relation "admin_users"

-- ROOT CAUSE:
-- Storage policies query admin_users table, which triggers admin_users RLS policies,
-- which query admin_users again = infinite recursion

-- SOLUTION:
-- Use SECURITY DEFINER functions to bypass RLS checks

-- ============================================================================
-- IMPLEMENTATION
-- ============================================================================

-- 1. BACKUP (optional but recommended):
--    Export your database before applying this fix
--    In Supabase: Project Settings > Backups

-- 2. DEPLOY THE FIX:
--    Open: supabase/migrations/00006_fix_recursion_kyc.sql
--    Copy all content
--    Paste into Supabase SQL Editor
--    Click "Run"

-- 3. VERIFY THE FIX:

-- Check functions were created:
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE 'is_current_user%'
ORDER BY routine_name;

-- Expected output (2 rows):
-- is_current_user_admin         | FUNCTION
-- is_current_user_super_admin   | FUNCTION

-- Check storage policies were recreated:
SELECT policyname, using_expression 
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
AND policyname LIKE '%Admins can%'
ORDER BY policyname;

-- Expected output (4 rows):
-- Admins can manage system assets
-- Admins can upload system assets
-- Admins can view all KYC documents
-- Admins can view all payment proofs

-- 4. TEST KYC UPLOAD:
--    Submit new KYC registration in Flutter app
--    Upload documents
--    Should succeed WITHOUT 500 error

-- ============================================================================
-- IF ISSUES PERSIST
-- ============================================================================

-- Check if functions exist:
\df is_current_user*

-- Check if policies exist:
SELECT * FROM pg_policies WHERE tablename = 'objects';

-- Rerun the fix (safe to run multiple times):
-- Open supabase/migrations/00006_fix_recursion_kyc.sql and run again

-- Check database logs for errors:
-- Supabase > Logs > Postgres / Function invocation / Storage

-- ============================================================================
-- KEY CHANGES
-- ============================================================================

BEFORE:
  Storage policy → Direct query to admin_users → Triggers admin_users RLS → Recursion

AFTER:
  Storage policy → Calls is_current_user_super_admin() → Executes as owner → No RLS recursion

-- ============================================================================
-- MIGRATION DETAILS
-- ============================================================================

File: supabase/migrations/00006_fix_recursion_kyc.sql

Sections:
1. Drop problematic storage policies
2. Create SECURITY DEFINER functions
3. Recreate storage policies using functions
4. Grant execute permissions
5. Create performance indexes

Time to deploy: < 1 second
Safe to re-run: YES
Rollback needed: NO
Breaking changes: NONE

-- ============================================================================
