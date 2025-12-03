-- ============================================================================
-- QUICK Q&A TEST SETUP
-- Run this to verify Q&A tables exist and insert test data
-- ============================================================================

-- 1. Check if tables exist
SELECT
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'listing_questions')
    THEN 'listing_questions EXISTS ✓'
    ELSE 'listing_questions MISSING ✗ - Run sql/11_qa_schema.sql'
  END as table_status
UNION ALL
SELECT
  CASE
    WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'listing_question_likes')
    THEN 'listing_question_likes EXISTS ✓'
    ELSE 'listing_question_likes MISSING ✗ - Run sql/11_qa_schema.sql'
  END;

-- 2. Count existing questions
SELECT COUNT(*) as total_questions FROM listing_questions;

-- 3. Insert test question (update listing_id and asker_id with real values)
-- IMPORTANT: Replace 'YOUR_LISTING_ID' with actual listing ID from your app
-- IMPORTANT: Replace 'YOUR_USER_ID' with your actual user ID

-- To get your user ID:
-- SELECT auth.uid();

-- To get a listing ID:
-- SELECT id, brand, model FROM listings WHERE status = 'active' LIMIT 1;

/*
INSERT INTO listing_questions (listing_id, asker_id, question, category)
VALUES (
  'YOUR_LISTING_ID'::uuid,
  'YOUR_USER_ID'::uuid,
  'What is the current mileage of this vehicle?',
  'condition'
);
*/

-- 4. View all questions
SELECT
  lq.id,
  lq.question,
  lq.category,
  lq.likes_count,
  lq.created_at,
  l.brand,
  l.model
FROM listing_questions lq
LEFT JOIN listings l ON l.id = lq.listing_id
ORDER BY lq.created_at DESC
LIMIT 10;

-- 5. Check RLS policies
SELECT
  tablename,
  policyname,
  cmd,
  qual
FROM pg_policies
WHERE tablename = 'listing_questions';
