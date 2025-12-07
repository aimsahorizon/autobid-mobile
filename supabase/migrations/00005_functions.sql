-- ============================================================================
-- AutoBid Mobile - RPC Functions & Business Logic
-- ============================================================================

-- ============================================================================
-- ENCRYPTION FUNCTIONS
-- ============================================================================

-- Encrypt sensitive fields using pgcrypto
CREATE OR REPLACE FUNCTION encrypt_field(plaintext TEXT, secret TEXT)
RETURNS BYTEA AS $$
BEGIN
  RETURN pgp_sym_encrypt(plaintext, secret);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Decrypt sensitive fields
CREATE OR REPLACE FUNCTION decrypt_field(ciphertext BYTEA, secret TEXT)
RETURNS TEXT AS $$
BEGIN
  RETURN pgp_sym_decrypt(ciphertext, secret);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- USER MANAGEMENT FUNCTIONS
-- ============================================================================

-- Get user full profile
CREATE OR REPLACE FUNCTION get_user_profile(user_uuid UUID)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'id', u.id,
    'email', u.email,
    'full_name', u.full_name,
    'profile_image_url', u.profile_image_url,
    'role', ur.display_name,
    'is_verified', u.is_verified,
    'is_active', u.is_active,
    'kyc_status', ks.display_name,
    'created_at', u.created_at
  ) INTO result
  FROM users u
  LEFT JOIN user_roles ur ON u.role_id = ur.id
  LEFT JOIN kyc_documents kd ON u.id = kd.user_id
  LEFT JOIN kyc_statuses ks ON kd.status_id = ks.id
  WHERE u.id = user_uuid;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- AUCTION FUNCTIONS
-- ============================================================================

-- Get active auctions with filters
CREATE OR REPLACE FUNCTION get_active_auctions(
  p_category_id UUID DEFAULT NULL,
  p_search TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 20,
  p_offset INTEGER DEFAULT 0
)
RETURNS TABLE (
  id UUID,
  title TEXT,
  description TEXT,
  starting_price NUMERIC,
  current_price NUMERIC,
  bid_increment NUMERIC,
  deposit_amount NUMERIC,
  start_time TIMESTAMPTZ,
  end_time TIMESTAMPTZ,
  total_bids INTEGER,
  category_name TEXT,
  seller_name TEXT,
  primary_image TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.title,
    a.description,
    a.starting_price,
    a.current_price,
    a.bid_increment,
    a.deposit_amount,
    a.start_time,
    a.end_time,
    a.total_bids,
    ac.display_name AS category_name,
    u.full_name AS seller_name,
    (SELECT image_url FROM auction_images WHERE auction_id = a.id AND is_primary = TRUE LIMIT 1) AS primary_image
  FROM auctions a
  JOIN auction_categories ac ON a.category_id = ac.id
  JOIN users u ON a.seller_id = u.id
  JOIN auction_statuses ast ON a.status_id = ast.id
  WHERE
    ast.status_name = 'live'
    AND (p_category_id IS NULL OR a.category_id = p_category_id)
    AND (p_search IS NULL OR a.title ILIKE '%' || p_search || '%' OR a.description ILIKE '%' || p_search || '%')
  ORDER BY a.created_at DESC
  LIMIT p_limit
  OFFSET p_offset;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Place a bid
CREATE OR REPLACE FUNCTION place_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_bid_amount NUMERIC
)
RETURNS JSON AS $$
DECLARE
  v_current_price NUMERIC;
  v_bid_increment NUMERIC;
  v_min_bid NUMERIC;
  v_bid_id UUID;
  v_active_status_id UUID;
  v_outbid_status_id UUID;
  result JSON;
BEGIN
  -- Get auction details
  SELECT current_price, bid_increment INTO v_current_price, v_bid_increment
  FROM auctions WHERE id = p_auction_id;

  -- Calculate minimum bid
  v_min_bid := v_current_price + v_bid_increment;

  -- Validate bid amount
  IF p_bid_amount < v_min_bid THEN
    RETURN json_build_object('success', FALSE, 'error', 'Bid amount too low');
  END IF;

  -- Get status IDs
  SELECT id INTO v_active_status_id FROM bid_statuses WHERE status_name = 'active';
  SELECT id INTO v_outbid_status_id FROM bid_statuses WHERE status_name = 'outbid';

  -- Mark previous bids as outbid
  UPDATE bids
  SET status_id = v_outbid_status_id
  WHERE auction_id = p_auction_id AND status_id = v_active_status_id;

  -- Insert new bid
  INSERT INTO bids (auction_id, bidder_id, status_id, bid_amount, is_auto_bid)
  VALUES (p_auction_id, p_bidder_id, v_active_status_id, p_bid_amount, FALSE)
  RETURNING id INTO v_bid_id;

  -- Update auction current price and bid count
  UPDATE auctions
  SET current_price = p_bid_amount, total_bids = total_bids + 1
  WHERE id = p_auction_id;

  -- Return success
  RETURN json_build_object('success', TRUE, 'bid_id', v_bid_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check and execute auto-bids
CREATE OR REPLACE FUNCTION execute_auto_bids(p_auction_id UUID)
RETURNS VOID AS $$
DECLARE
  v_current_price NUMERIC;
  v_bid_increment NUMERIC;
  v_auto_bid RECORD;
  v_new_bid_amount NUMERIC;
BEGIN
  -- Get auction details
  SELECT current_price, bid_increment INTO v_current_price, v_bid_increment
  FROM auctions WHERE id = p_auction_id;

  -- Loop through active auto-bid settings
  FOR v_auto_bid IN
    SELECT * FROM auto_bid_settings
    WHERE auction_id = p_auction_id AND is_active = TRUE
    ORDER BY max_bid_amount DESC
  LOOP
    v_new_bid_amount := v_current_price + v_bid_increment;

    IF v_auto_bid.max_bid_amount >= v_new_bid_amount THEN
      -- Execute auto-bid
      PERFORM place_bid(p_auction_id, v_auto_bid.user_id, v_new_bid_amount);
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- End auction
CREATE OR REPLACE FUNCTION end_auction(p_auction_id UUID)
RETURNS JSON AS $$
DECLARE
  v_ended_status_id UUID;
  v_sold_status_id UUID;
  v_unsold_status_id UUID;
  v_won_status_id UUID;
  v_lost_status_id UUID;
  v_winning_bid RECORD;
  result JSON;
BEGIN
  -- Get status IDs
  SELECT id INTO v_ended_status_id FROM auction_statuses WHERE status_name = 'ended';
  SELECT id INTO v_sold_status_id FROM auction_statuses WHERE status_name = 'sold';
  SELECT id INTO v_unsold_status_id FROM auction_statuses WHERE status_name = 'unsold';
  SELECT id INTO v_won_status_id FROM bid_statuses WHERE status_name = 'won';
  SELECT id INTO v_lost_status_id FROM bid_statuses WHERE status_name = 'lost';

  -- Get winning bid
  SELECT * INTO v_winning_bid
  FROM bids
  WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC
  LIMIT 1;

  IF v_winning_bid IS NOT NULL THEN
    -- Mark auction as sold
    UPDATE auctions SET status_id = v_sold_status_id WHERE id = p_auction_id;

    -- Mark winning bid
    UPDATE bids SET status_id = v_won_status_id WHERE id = v_winning_bid.id;

    -- Mark losing bids
    UPDATE bids SET status_id = v_lost_status_id
    WHERE auction_id = p_auction_id AND id != v_winning_bid.id;

    result := json_build_object('success', TRUE, 'winner_id', v_winning_bid.bidder_id, 'winning_amount', v_winning_bid.bid_amount);
  ELSE
    -- Mark auction as unsold
    UPDATE auctions SET status_id = v_unsold_status_id WHERE id = p_auction_id;

    result := json_build_object('success', TRUE, 'winner_id', NULL, 'winning_amount', NULL);
  END IF;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- ADMIN FUNCTIONS
-- ============================================================================

-- Check if user is admin
CREATE OR REPLACE FUNCTION is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users WHERE user_id = user_uuid AND is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Check if user is super admin
CREATE OR REPLACE FUNCTION is_super_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM admin_users au
    JOIN admin_roles ar ON au.role_id = ar.id
    WHERE au.user_id = user_uuid AND ar.role_name = 'super_admin' AND au.is_active = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Approve KYC
CREATE OR REPLACE FUNCTION approve_kyc(
  p_kyc_document_id UUID,
  p_admin_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_approved_status_id UUID;
  v_user_id UUID;
BEGIN
  -- Check admin permission
  IF NOT is_super_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  -- Get approved status
  SELECT id INTO v_approved_status_id FROM kyc_statuses WHERE status_name = 'approved';

  -- Update KYC document
  UPDATE kyc_documents
  SET
    status_id = v_approved_status_id,
    reviewed_at = NOW(),
    reviewed_by = p_admin_id,
    expires_at = NOW() + INTERVAL '1 year'
  WHERE id = p_kyc_document_id
  RETURNING user_id INTO v_user_id;

  -- Mark user as verified
  UPDATE users SET is_verified = TRUE WHERE id = v_user_id;

  -- Remove from review queue
  DELETE FROM kyc_review_queue WHERE kyc_document_id = p_kyc_document_id;

  RETURN json_build_object('success', TRUE, 'user_id', v_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Reject KYC
CREATE OR REPLACE FUNCTION reject_kyc(
  p_kyc_document_id UUID,
  p_admin_id UUID,
  p_reason TEXT
)
RETURNS JSON AS $$
DECLARE
  v_rejected_status_id UUID;
  v_user_id UUID;
BEGIN
  -- Check admin permission
  IF NOT is_super_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  -- Get rejected status
  SELECT id INTO v_rejected_status_id FROM kyc_statuses WHERE status_name = 'rejected';

  -- Update KYC document
  UPDATE kyc_documents
  SET
    status_id = v_rejected_status_id,
    reviewed_at = NOW(),
    reviewed_by = p_admin_id,
    rejection_reason = p_reason
  WHERE id = p_kyc_document_id
  RETURNING user_id INTO v_user_id;

  -- Remove from review queue
  DELETE FROM kyc_review_queue WHERE kyc_document_id = p_kyc_document_id;

  RETURN json_build_object('success', TRUE, 'user_id', v_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Approve auction
CREATE OR REPLACE FUNCTION approve_auction(
  p_auction_id UUID,
  p_admin_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_scheduled_status_id UUID;
BEGIN
  -- Check admin permission
  IF NOT is_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  -- Get scheduled status
  SELECT id INTO v_scheduled_status_id FROM auction_statuses WHERE status_name = 'scheduled';

  -- Update auction
  UPDATE auctions SET status_id = v_scheduled_status_id WHERE id = p_auction_id;

  -- Log moderation action
  INSERT INTO auction_moderation (auction_id, moderator_id, action)
  VALUES (p_auction_id, (SELECT id FROM admin_users WHERE user_id = p_admin_id), 'approve');

  RETURN json_build_object('success', TRUE);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Get admin dashboard statistics
CREATE OR REPLACE FUNCTION get_admin_dashboard_stats()
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'total_users', (SELECT COUNT(*) FROM users),
    'verified_users', (SELECT COUNT(*) FROM users WHERE is_verified = TRUE),
    'pending_kyc', (SELECT COUNT(*) FROM kyc_review_queue),
    'active_auctions', (SELECT COUNT(*) FROM auctions a JOIN auction_statuses ast ON a.status_id = ast.id WHERE ast.status_name = 'live'),
    'pending_auctions', (SELECT COUNT(*) FROM auctions a JOIN auction_statuses ast ON a.status_id = ast.id WHERE ast.status_name = 'pending_approval'),
    'total_bids_today', (SELECT COUNT(*) FROM bids WHERE created_at >= CURRENT_DATE),
    'total_revenue', (SELECT COALESCE(SUM(amount), 0) FROM transactions t JOIN transaction_statuses ts ON t.status_id = ts.id WHERE ts.status_name = 'completed')
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- AUDIT LOG FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION log_admin_action(
  p_admin_id UUID,
  p_action TEXT,
  p_resource_type TEXT,
  p_resource_id UUID,
  p_changes JSONB DEFAULT NULL
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO admin_audit_log (admin_id, action, resource_type, resource_id, changes)
  VALUES (
    (SELECT id FROM admin_users WHERE user_id = p_admin_id),
    p_action,
    p_resource_type,
    p_resource_id,
    p_changes
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- END OF FUNCTIONS
-- ============================================================================
