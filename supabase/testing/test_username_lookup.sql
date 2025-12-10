-- Test username lookup to debug authentication issues
-- This tests the exact query that the app uses

-- Replace 'YOUR_USERNAME_HERE' with your actual username

-- Test 1: Exact match (what the app does)
SELECT
  'Test 1: Exact Match' as test_name,
  email,
  phone_number,
  is_active,
  is_verified,
  display_name
FROM users
WHERE username = 'nekolaiv';

-- Test 2: Case-insensitive match
SELECT
  'Test 2: Case-Insensitive Match' as test_name,
  username,
  email,
  is_active
FROM users
WHERE LOWER(username) = LOWER('nekolaiv');

-- Test 3: Check for whitespace issues
SELECT
  'Test 3: Whitespace Check' as test_name,
  username,
  email,
  LENGTH(username) as username_length,
  LENGTH(TRIM(username)) as trimmed_length,
  username = TRIM(username) as is_trimmed,
  '|' || username || '|' as username_with_pipes
FROM users
WHERE LOWER(TRIM(username)) = LOWER(TRIM('nekolaiv'));

-- Test 4: List similar usernames
SELECT
  'Test 4: Similar Usernames' as test_name,
  username,
  email,
  similarity(username, 'nekolaiv') as similarity_score
FROM users
WHERE username ILIKE '%nekolaiv%'
ORDER BY similarity_score DESC
LIMIT 5;

-- Test 5: Check auth.users connection
SELECT
  'Test 5: Auth Connection' as test_name,
  u.username,
  u.email as users_email,
  au.email as auth_email,
  au.email_confirmed_at IS NOT NULL as email_confirmed,
  au.encrypted_password IS NOT NULL as has_password
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE LOWER(u.username) = LOWER('nekolaiv');
