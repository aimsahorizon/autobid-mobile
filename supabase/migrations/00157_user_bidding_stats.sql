-- ============================================================
-- User Bidding & Transaction Stats RPC
-- Returns bidding rate, transaction success/cancellation rate
-- Cancellation only counts if THE USER themselves cancelled (penalized)
-- ============================================================

CREATE OR REPLACE FUNCTION get_user_bidding_stats(p_user_id UUID)
RETURNS JSON
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_total_bids INT;
  v_total_wins INT;
  v_bidding_rate NUMERIC;
  v_total_transactions INT;
  v_completed_transactions INT;
  v_self_cancelled INT;
  v_success_rate NUMERIC;
  v_cancellation_rate NUMERIC;
  v_profile_photo TEXT;
  v_username TEXT;
  v_full_name TEXT;
  v_province TEXT;
  v_city TEXT;
BEGIN
  -- Profile info
  SELECT
    u.profile_photo_url,
    u.username,
    TRIM(COALESCE(u.first_name, '') || ' ' || COALESCE(u.last_name, '')),
    ua.province,
    ua.city
  INTO v_profile_photo, v_username, v_full_name, v_province, v_city
  FROM users u
  LEFT JOIN LATERAL (
    SELECT province, city FROM user_addresses
    WHERE user_id = u.id AND is_default = true
    LIMIT 1
  ) ua ON true
  WHERE u.id = p_user_id;

  -- Bidding stats (buyer role)
  SELECT COUNT(*) INTO v_total_bids
  FROM bids WHERE user_id = p_user_id;

  SELECT COUNT(*) INTO v_total_wins
  FROM auction_transactions WHERE buyer_id = p_user_id AND status IN ('in_transaction', 'sold');

  v_bidding_rate := CASE WHEN v_total_bids > 0
    THEN ROUND((v_total_wins::NUMERIC / v_total_bids) * 100, 1)
    ELSE 0 END;

  -- Transaction stats (both roles)
  SELECT COUNT(*) INTO v_total_transactions
  FROM auction_transactions
  WHERE buyer_id = p_user_id OR seller_id = p_user_id;

  SELECT COUNT(*) INTO v_completed_transactions
  FROM auction_transactions
  WHERE (buyer_id = p_user_id OR seller_id = p_user_id)
    AND status = 'sold';

  -- Self-cancelled: user was penalized via cancellation_penalties
  SELECT COUNT(DISTINCT cp.transaction_id) INTO v_self_cancelled
  FROM cancellation_penalties cp
  WHERE cp.user_id = p_user_id;

  v_success_rate := CASE WHEN v_total_transactions > 0
    THEN ROUND((v_completed_transactions::NUMERIC / v_total_transactions) * 100, 1)
    ELSE 0 END;

  v_cancellation_rate := CASE WHEN v_total_transactions > 0
    THEN ROUND((v_self_cancelled::NUMERIC / v_total_transactions) * 100, 1)
    ELSE 0 END;

  RETURN json_build_object(
    'user_id', p_user_id,
    'profile_photo_url', COALESCE(v_profile_photo, ''),
    'username', COALESCE(v_username, ''),
    'full_name', COALESCE(v_full_name, ''),
    'province', v_province,
    'city', v_city,
    'total_bids', v_total_bids,
    'total_wins', v_total_wins,
    'bidding_rate', v_bidding_rate,
    'total_transactions', v_total_transactions,
    'completed_transactions', v_completed_transactions,
    'self_cancelled_transactions', v_self_cancelled,
    'success_rate', v_success_rate,
    'cancellation_rate', v_cancellation_rate
  );
END;
$$;
