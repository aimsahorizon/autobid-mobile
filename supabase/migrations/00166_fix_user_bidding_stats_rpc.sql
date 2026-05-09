-- ============================================================
-- Fix get_user_bidding_stats RPC for current schema
-- - Use bids.bidder_id (not bids.user_id)
-- - Keep RPC as SECURITY DEFINER to bypass profile RLS
-- - Ensure authenticated users can execute it
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_bidding_stats(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_total_bids INT := 0;
  v_total_wins INT := 0;
  v_bidding_rate NUMERIC := 0;
  v_total_transactions INT := 0;
  v_completed_transactions INT := 0;
  v_self_cancelled INT := 0;
  v_success_rate NUMERIC := 0;
  v_cancellation_rate NUMERIC := 0;
  v_profile_photo TEXT := '';
  v_username TEXT := '';
  v_full_name TEXT := '';
  v_province TEXT;
  v_city TEXT;
BEGIN
  SELECT
    COALESCE(u.profile_photo_url, ''),
    COALESCE(u.username, ''),
    TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')),
    ua.province,
    ua.city
  INTO v_profile_photo, v_username, v_full_name, v_province, v_city
  FROM users u
  LEFT JOIN LATERAL (
    SELECT province, city
    FROM user_addresses
    WHERE user_id = u.id
    ORDER BY is_default DESC, created_at DESC
    LIMIT 1
  ) ua ON true
  WHERE u.id = p_user_id;

  SELECT COUNT(*)
  INTO v_total_bids
  FROM bids
  WHERE bidder_id = p_user_id;

  SELECT COUNT(*)
  INTO v_total_wins
  FROM auction_transactions
  WHERE buyer_id = p_user_id
    AND status IN ('in_transaction', 'sold');

  IF v_total_bids > 0 THEN
    v_bidding_rate := ROUND((v_total_wins::NUMERIC / v_total_bids) * 100, 1);
  END IF;

  SELECT COUNT(*)
  INTO v_total_transactions
  FROM auction_transactions
  WHERE buyer_id = p_user_id OR seller_id = p_user_id;

  SELECT COUNT(*)
  INTO v_completed_transactions
  FROM auction_transactions
  WHERE (buyer_id = p_user_id OR seller_id = p_user_id)
    AND status = 'sold';

  SELECT COUNT(DISTINCT cp.transaction_id)
  INTO v_self_cancelled
  FROM cancellation_penalties cp
  WHERE cp.user_id = p_user_id;

  IF v_total_transactions > 0 THEN
    v_success_rate := ROUND((v_completed_transactions::NUMERIC / v_total_transactions) * 100, 1);
    v_cancellation_rate := ROUND((v_self_cancelled::NUMERIC / v_total_transactions) * 100, 1);
  END IF;

  RETURN json_build_object(
    'user_id', p_user_id,
    'profile_photo_url', COALESCE(v_profile_photo, ''),
    'username', COALESCE(v_username, ''),
    'full_name', COALESCE(NULLIF(v_full_name, ''), 'User'),
    'province', v_province,
    'city', v_city,
    'total_bids', COALESCE(v_total_bids, 0),
    'total_wins', COALESCE(v_total_wins, 0),
    'bidding_rate', COALESCE(v_bidding_rate, 0),
    'total_transactions', COALESCE(v_total_transactions, 0),
    'completed_transactions', COALESCE(v_completed_transactions, 0),
    'self_cancelled_transactions', COALESCE(v_self_cancelled, 0),
    'success_rate', COALESCE(v_success_rate, 0),
    'cancellation_rate', COALESCE(v_cancellation_rate, 0)
  );
END;
$$;

REVOKE ALL ON FUNCTION get_user_bidding_stats(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION get_user_bidding_stats(UUID) TO authenticated;
