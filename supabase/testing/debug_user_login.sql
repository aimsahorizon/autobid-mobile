-- Debug script to check user authentication issues
-- Replace 'YOUR_USERNAME_HERE' with your actual username

-- 1. Check if username exists in users table (case-sensitive check)
SELECT
  id,
  username,
  email,
  is_active,
  is_verified,
  created_at
FROM users
WHERE username = 'nekolaiv';

-- 2. Check for case sensitivity issues (case-insensitive check)
SELECT
  id,
  username,
  email,
  is_active,
  is_verified,
  created_at
FROM users
WHERE LOWER(username) = LOWER('YOUR_USERNAME_HERE');

-- 3. Check if user exists in auth.users
SELECT
  au.id,
  au.email,
  au.email_confirmed_at,
  au.encrypted_password IS NOT NULL as has_password,
  au.created_at as auth_created_at
FROM auth.users au
WHERE au.email IN (
  SELECT email FROM users WHERE LOWER(username) = LOWER('YOUR_USERNAME_HERE')
);

-- 4. Check for whitespace or special characters in username
SELECT
  id,
  username,
  email,
  LENGTH(username) as username_length,
  LENGTH(TRIM(username)) as trimmed_length,
  username = TRIM(username) as is_trimmed,
  encode(username::bytea, 'hex') as username_hex
FROM users
WHERE LOWER(username) = LOWER('YOUR_USERNAME_HERE');

-- 5. List all usernames (to verify exact spelling)
SELECT
  username,
  email,
  is_active
FROM users
ORDER BY created_at DESC
LIMIT 20;

-- 6. Check for duplicate usernames
SELECT
  username,
  COUNT(*) as count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- 7. Full diagnostic query
SELECT
  u.id as user_id,
  u.username,
  u.email,
  u.is_active,
  u.is_verified,
  au.id as auth_id,
  au.email_confirmed_at IS NOT NULL as email_confirmed,
  au.encrypted_password IS NOT NULL as has_password,
  u.created_at as user_created,
  au.created_at as auth_created
FROM users u
LEFT JOIN auth.users au ON u.id = au.id
WHERE LOWER(u.username) = LOWER('YOUR_USERNAME_HERE');
