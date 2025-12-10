-- ============================================================================
-- Test Admin Listings Query
-- This tests the exact query structure that admin_supabase_datasource.dart uses
-- ============================================================================

-- Test 1: Basic auction fetch (verify table structure)
SELECT
  'Test 1: Basic Auction Fetch' as test_name,
  a.id,
  a.title,
  a.seller_id,
  a.status_id,
  a.starting_price,
  a.reserve_price,
  a.created_at
FROM auctions a
LIMIT 3;

-- Test 2: Auction with status (JOIN test)
SELECT
  'Test 2: Auction with Status' as test_name,
  a.id,
  a.title,
  ast.status_name
FROM auctions a
LEFT JOIN auction_statuses ast ON a.status_id = ast.id
LIMIT 3;

-- Test 3: Auction with seller (FK test)
SELECT
  'Test 3: Auction with Seller' as test_name,
  a.id,
  a.title,
  u.full_name as seller_name,
  u.email as seller_email
FROM auctions a
LEFT JOIN users u ON a.seller_id = u.id
LIMIT 3;

-- Test 4: Auction with vehicle (one-to-one relationship test)
SELECT
  'Test 4: Auction with Vehicle' as test_name,
  a.id,
  a.title,
  av.brand,
  av.model,
  av.year,
  av.mileage,
  av.condition
FROM auctions a
LEFT JOIN auction_vehicles av ON a.id = av.auction_id
LIMIT 3;

-- Test 5: Auction with photos (one-to-many relationship test)
SELECT
  'Test 5: Auction with Photos' as test_name,
  a.id,
  a.title,
  COUNT(ap.id) as photo_count,
  STRING_AGG(ap.photo_url, ', ' ORDER BY ap.is_primary DESC, ap.display_order) as photo_urls
FROM auctions a
LEFT JOIN auction_photos ap ON a.id = ap.auction_id
GROUP BY a.id, a.title
LIMIT 3;

-- Test 6: Complete query (matches Supabase PostgREST nested query structure)
-- This simulates what Supabase .select() does with nested relationships
SELECT
  'Test 6: Complete Nested Query' as test_name,
  jsonb_build_object(
    'id', a.id,
    'title', a.title,
    'seller_id', a.seller_id,
    'status_id', a.status_id,
    'starting_price', a.starting_price,
    'reserve_price', a.reserve_price,
    'created_at', a.created_at,
    'auction_statuses', jsonb_build_object(
      'status_name', ast.status_name
    ),
    'users', jsonb_build_object(
      'full_name', u.full_name,
      'email', u.email
    ),
    'auction_vehicles', (
      SELECT jsonb_build_object(
        'brand', av.brand,
        'model', av.model,
        'year', av.year,
        'variant', av.variant,
        'mileage', av.mileage,
        'condition', av.condition
      )
      FROM auction_vehicles av
      WHERE av.auction_id = a.id
    ),
    'auction_photos', (
      SELECT jsonb_agg(
        jsonb_build_object(
          'photo_url', ap.photo_url,
          'is_primary', ap.is_primary
        )
        ORDER BY ap.is_primary DESC, ap.display_order
      )
      FROM auction_photos ap
      WHERE ap.auction_id = a.id
    )
  ) as complete_listing_data
FROM auctions a
LEFT JOIN auction_statuses ast ON a.status_id = ast.id
LEFT JOIN users u ON a.seller_id = u.id
LIMIT 3;

-- Test 7: Check if admin review fields exist
SELECT
  'Test 7: Admin Review Fields' as test_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'auctions'
AND column_name IN ('submitted_at', 'review_notes', 'reviewed_at', 'reviewed_by')
ORDER BY column_name;

-- Test 8: Verify RLS policies for admin
SELECT
  'Test 8: Admin RLS Policies' as test_name,
  schemaname,
  tablename,
  policyname,
  cmd,
  roles
FROM pg_policies
WHERE tablename IN ('auctions', 'auction_vehicles', 'auction_photos')
AND policyname ILIKE '%admin%'
ORDER BY tablename, policyname;

-- Test 9: Check admin user setup
SELECT
  'Test 9: Admin User Setup' as test_name,
  u.email,
  u.username,
  u.full_name,
  au.is_active as is_admin_active,
  ar.role_name,
  ar.display_name as role_display_name
FROM admin_users au
JOIN users u ON au.user_id = u.id
JOIN admin_roles ar ON au.role_id = ar.id
WHERE u.email = 'admin@autobid.dev';

-- Test 10: Count listings by status (what admin stats needs)
SELECT
  'Test 10: Listings by Status' as test_name,
  ast.status_name,
  COUNT(a.id) as listing_count
FROM auction_statuses ast
LEFT JOIN auctions a ON a.status_id = ast.id
GROUP BY ast.status_name
ORDER BY listing_count DESC;

-- ============================================================================
-- EXPECTED RESULTS:
-- ============================================================================
-- Test 1-5: Should return auction data if listings exist
-- Test 6: Should return properly nested JSON structure matching Supabase format
-- Test 7: Should show 4 rows if migration 00033 was applied, 0 rows if not
-- Test 8: Should show admin RLS policies created in migration 00032
-- Test 9: Should show admin@autobid.dev with super_admin role
-- Test 10: Should show count of listings in each status

-- ============================================================================
-- TROUBLESHOOTING:
-- ============================================================================
-- If Test 7 returns 0 rows: Run migration 00033
-- If Test 8 returns 0 rows: Run migration 00032
-- If Test 9 returns 0 rows: Admin user not set up, run migration 00032
-- If Test 10 shows 0 for all: No listings exist in database yet
