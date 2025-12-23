-- ============================================================================
-- AutoBid Mobile - Admin Workflow Testing Guide
-- Test admin operations without a UI interface
-- ============================================================================

-- SETUP: You need to run these tests as a PostgreSQL superuser or Supabase service role
-- Connect to your Supabase database using the service role key

-- ============================================================================
-- STEP 1: CREATE TEST USERS
-- ============================================================================

-- Create a test seller user (normally done via Supabase Auth)
-- For testing, we'll insert directly into auth.users (use Supabase dashboard in production)

-- Insert into users table (assuming auth.user already exists)
INSERT INTO users (id, email, full_name, role_id, is_verified, is_active)
VALUES
  ('11111111-1111-1111-1111-111111111111', 'seller@test.com', 'Test Seller',
   (SELECT id FROM user_roles WHERE role_name = 'seller'), FALSE, TRUE),
  ('22222222-2222-2222-2222-222222222222', 'buyer@test.com', 'Test Buyer',
   (SELECT id FROM user_roles WHERE role_name = 'buyer'), FALSE, TRUE),
  ('33333333-3333-3333-3333-333333333333', 'admin@test.com', 'Super Admin',
   (SELECT id FROM user_roles WHERE role_name = 'both'), TRUE, TRUE);

-- ============================================================================
-- STEP 2: CREATE SUPER ADMIN
-- ============================================================================

-- Make the admin user a super admin
INSERT INTO admin_users (user_id, role_id, is_active, created_by)
VALUES (
  '33333333-3333-3333-3333-333333333333',
  (SELECT id FROM admin_roles WHERE role_name = 'super_admin'),
  TRUE,
  NULL
);

-- Verify admin was created
SELECT
  u.email,
  u.full_name,
  ar.display_name AS admin_role,
  au.is_active
FROM admin_users au
JOIN users u ON au.user_id = u.id
JOIN admin_roles ar ON au.role_id = ar.id;

-- ============================================================================
-- STEP 3: TEST KYC WORKFLOW
-- ============================================================================

-- Seller submits KYC document
INSERT INTO kyc_documents (
  user_id,
  status_id,
  selfie_url,
  document_type,
  submitted_at
)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  (SELECT id FROM kyc_statuses WHERE status_name = 'pending'),
  'https://example.com/selfie.jpg',
  'national_id',
  NOW()
);

-- Auto-add to review queue (this would normally be done via trigger)
INSERT INTO kyc_review_queue (
  kyc_document_id,
  sla_deadline
)
VALUES (
  (SELECT id FROM kyc_documents WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  NOW() + INTERVAL '48 hours'
);

-- View pending KYC reviews (what admin would see)
SELECT
  kd.id AS kyc_id,
  u.email,
  u.full_name,
  kd.document_type,
  kd.submitted_at,
  krq.sla_deadline,
  (krq.sla_deadline < NOW()) AS is_overdue
FROM kyc_review_queue krq
JOIN kyc_documents kd ON krq.kyc_document_id = kd.id
JOIN users u ON kd.user_id = u.id
ORDER BY krq.sla_deadline ASC;

-- Admin approves KYC
SELECT approve_kyc(
  (SELECT id FROM kyc_documents WHERE user_id = '11111111-1111-1111-1111-111111111111'),
  '33333333-3333-3333-3333-333333333333'
);

-- Verify KYC was approved
SELECT
  u.email,
  u.is_verified,
  ks.display_name AS kyc_status,
  kd.reviewed_at,
  admin_user.full_name AS reviewed_by
FROM users u
JOIN kyc_documents kd ON u.id = kd.user_id
JOIN kyc_statuses ks ON kd.status_id = ks.id
LEFT JOIN users admin_user ON kd.reviewed_by = admin_user.id
WHERE u.id = '11111111-1111-1111-1111-111111111111';

-- ============================================================================
-- STEP 4: TEST AUCTION APPROVAL WORKFLOW
-- ============================================================================

-- Seller creates an auction (now that they're KYC approved)
INSERT INTO auctions (
  seller_id,
  category_id,
  status_id,
  title,
  description,
  starting_price,
  bid_increment,
  deposit_amount,
  start_time,
  end_time
)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  (SELECT id FROM auction_categories WHERE category_name = 'electronics'),
  (SELECT id FROM auction_statuses WHERE status_name = 'pending_approval'),
  'iPhone 15 Pro Max',
  'Brand new iPhone 15 Pro Max 256GB',
  50000.00,
  500.00,
  5000.00,
  NOW() + INTERVAL '1 day',
  NOW() + INTERVAL '8 days'
);

-- View pending auctions (what moderator would see)
SELECT
  a.id AS auction_id,
  a.title,
  u.full_name AS seller,
  ac.display_name AS category,
  a.starting_price,
  a.created_at,
  ast.display_name AS status
FROM auctions a
JOIN users u ON a.seller_id = u.id
JOIN auction_categories ac ON a.category_id = ac.id
JOIN auction_statuses ast ON a.status_id = ast.id
WHERE ast.status_name = 'pending_approval'
ORDER BY a.created_at DESC;

-- Admin/Moderator approves auction
SELECT approve_auction(
  (SELECT id FROM auctions WHERE title = 'iPhone 15 Pro Max'),
  '33333333-3333-3333-3333-333333333333'
);

-- Verify auction was approved
SELECT
  a.title,
  ast.display_name AS status,
  am.action,
  am.created_at AS moderated_at
FROM auctions a
JOIN auction_statuses ast ON a.status_id = ast.id
LEFT JOIN auction_moderation am ON a.id = am.auction_id
WHERE a.title = 'iPhone 15 Pro Max';

-- ============================================================================
-- STEP 5: TEST BIDDING WORKFLOW
-- ============================================================================

-- Update auction to live status (simulating start_time reached)
UPDATE auctions
SET status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
WHERE title = 'iPhone 15 Pro Max';

-- Buyer places a bid
SELECT place_bid(
  (SELECT id FROM auctions WHERE title = 'iPhone 15 Pro Max'),
  '22222222-2222-2222-2222-222222222222',
  50500.00
);

-- View auction with current bid
SELECT
  a.title,
  a.starting_price,
  a.current_price,
  a.total_bids,
  u.full_name AS highest_bidder
FROM auctions a
LEFT JOIN bids b ON a.id = b.auction_id
  AND b.status_id = (SELECT id FROM bid_statuses WHERE status_name = 'active')
LEFT JOIN users u ON b.bidder_id = u.id
WHERE a.title = 'iPhone 15 Pro Max';

-- ============================================================================
-- STEP 6: TEST ADMIN DASHBOARD
-- ============================================================================

-- Get dashboard statistics
SELECT get_admin_dashboard_stats();

-- View recent admin actions (audit log)
SELECT
  u.full_name AS admin,
  aal.action,
  aal.resource_type,
  aal.created_at
FROM admin_audit_log aal
JOIN admin_users au ON aal.admin_id = au.id
JOIN users u ON au.user_id = u.id
ORDER BY aal.created_at DESC
LIMIT 20;

-- ============================================================================
-- STEP 7: TEST REPORTING & MODERATION
-- ============================================================================

-- User reports an auction
INSERT INTO reported_content (
  reporter_id,
  content_type,
  content_id,
  reason,
  description
)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  'auction',
  (SELECT id FROM auctions WHERE title = 'iPhone 15 Pro Max'),
  'Suspicious listing',
  'Price seems too good to be true'
);

-- View pending reports (what admin would see)
SELECT
  rc.id AS report_id,
  rc.content_type,
  reporter.full_name AS reported_by,
  rc.reason,
  rc.description,
  rc.status,
  rc.created_at
FROM reported_content rc
JOIN users reporter ON rc.reporter_id = reporter.id
WHERE rc.status = 'pending'
ORDER BY rc.created_at DESC;

-- Admin reviews and resolves report
UPDATE reported_content
SET
  status = 'resolved',
  reviewed_by = (SELECT id FROM admin_users WHERE user_id = '33333333-3333-3333-3333-333333333333'),
  reviewed_at = NOW()
WHERE id = (SELECT id FROM reported_content WHERE content_type = 'auction' LIMIT 1);

-- ============================================================================
-- STEP 8: VERIFY RLS POLICIES
-- ============================================================================

-- Test: Can regular user see their own KYC?
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims.sub TO '11111111-1111-1111-1111-111111111111';

SELECT * FROM kyc_documents WHERE user_id = '11111111-1111-1111-1111-111111111111';
-- Should succeed

-- Test: Can regular user see another user's KYC?
SELECT * FROM kyc_documents WHERE user_id = '22222222-2222-2222-2222-222222222222';
-- Should return empty (RLS blocks it)

RESET ROLE;

-- ============================================================================
-- STEP 9: CLEANUP TEST DATA (Optional)
-- ============================================================================

-- Uncomment to clean up test data
/*
DELETE FROM reported_content WHERE reporter_id IN ('22222222-2222-2222-2222-222222222222');
DELETE FROM bids WHERE auction_id IN (SELECT id FROM auctions WHERE seller_id = '11111111-1111-1111-1111-111111111111');
DELETE FROM auction_moderation WHERE auction_id IN (SELECT id FROM auctions WHERE seller_id = '11111111-1111-1111-1111-111111111111');
DELETE FROM auctions WHERE seller_id = '11111111-1111-1111-1111-111111111111';
DELETE FROM kyc_review_queue WHERE kyc_document_id IN (SELECT id FROM kyc_documents WHERE user_id = '11111111-1111-1111-1111-111111111111');
DELETE FROM kyc_documents WHERE user_id IN ('11111111-1111-1111-1111-111111111111');
DELETE FROM admin_users WHERE user_id = '33333333-3333-3333-3333-333333333333';
DELETE FROM users WHERE id IN ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222', '33333333-3333-3333-3333-333333333333');
*/

-- ============================================================================
-- END OF TESTING GUIDE
-- ============================================================================
