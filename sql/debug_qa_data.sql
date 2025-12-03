-- ============================================================================
-- DEBUG Q&A DATA
-- Run this to check if Q&A tables exist and have data
-- ============================================================================

-- 1. Check if Q&A tables exist
SELECT
  'listing_questions' as table_name,
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'listing_questions')
    THEN 'EXISTS ✓'
    ELSE 'MISSING ✗ - Run sql/11_qa_schema.sql'
  END as status
UNION ALL
SELECT
  'listing_question_likes' as table_name,
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'listing_question_likes')
    THEN 'EXISTS ✓'
    ELSE 'MISSING ✗ - Run sql/11_qa_schema.sql'
  END as status;

-- 2. Check RLS is enabled
SELECT
  schemaname,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename IN ('listing_questions', 'listing_question_likes')
ORDER BY tablename;

-- 3. Count total questions
SELECT
  COUNT(*) as total_questions,
  COUNT(CASE WHEN answer IS NOT NULL THEN 1 END) as answered_questions,
  COUNT(CASE WHEN answer IS NULL THEN 1 END) as unanswered_questions
FROM listing_questions;

-- 4. Show all questions with details
SELECT
  lq.id,
  lq.listing_id,
  lq.question,
  lq.category,
  lq.answer,
  lq.likes_count,
  lq.is_public,
  lq.created_at,
  SUBSTRING(lq.asker_id::text, 1, 8) as asker_id_partial
FROM listing_questions lq
ORDER BY lq.created_at DESC
LIMIT 20;

-- 5. Check RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('listing_questions', 'listing_question_likes')
ORDER BY tablename, policyname;

-- 6. Get current user ID (for inserting test data)
SELECT auth.uid() as current_user_id;

-- 7. Get some active listing IDs (for inserting test data)
SELECT
  id,
  brand,
  model,
  status,
  created_at
FROM listings
WHERE status = 'active'
ORDER BY created_at DESC
LIMIT 5;

-- ============================================================================
-- TO INSERT TEST Q&A DATA:
-- ============================================================================
-- Copy a listing_id from query #7 and current user ID from query #6, then run:
/*
INSERT INTO listing_questions (listing_id, asker_id, question, category, is_public)
VALUES
  ('YOUR_LISTING_ID'::uuid, auth.uid(), 'What is the current mileage of this vehicle?', 'condition', true),
  ('YOUR_LISTING_ID'::uuid, auth.uid(), 'Has this car been in any accidents?', 'history', true),
  ('YOUR_LISTING_ID'::uuid, auth.uid(), 'Does it have a spare tire?', 'features', true);
*/
