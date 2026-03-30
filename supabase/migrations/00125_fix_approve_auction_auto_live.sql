-- Fix: approve_auction should check auto_live_after_approval flag
-- If true: set status to 'live' with start_time = NOW() and end_time = NOW() + 7 days
-- If false: set status to 'approved' so seller can choose when to go live

CREATE OR REPLACE FUNCTION approve_auction(
  p_auction_id UUID,
  p_admin_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_target_status_id UUID;
  v_auto_live BOOLEAN;
  v_target_status TEXT;
BEGIN
  -- Check admin permission
  IF NOT is_admin(p_admin_id) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Unauthorized');
  END IF;

  -- Check auto_live preference
  SELECT auto_live_after_approval INTO v_auto_live
  FROM auctions WHERE id = p_auction_id;

  IF v_auto_live = TRUE THEN
    v_target_status := 'live';
  ELSE
    v_target_status := 'approved';
  END IF;

  SELECT id INTO v_target_status_id
  FROM auction_statuses WHERE status_name = v_target_status;

  -- Update auction
  IF v_auto_live = TRUE THEN
    UPDATE auctions
    SET status_id = v_target_status_id,
        start_time = NOW(),
        end_time = NOW() + INTERVAL '7 days',
        updated_at = NOW()
    WHERE id = p_auction_id;
  ELSE
    UPDATE auctions
    SET status_id = v_target_status_id, updated_at = NOW()
    WHERE id = p_auction_id;
  END IF;

  -- Log moderation action
  INSERT INTO auction_moderation (auction_id, moderator_id, action)
  VALUES (p_auction_id, (SELECT id FROM admin_users WHERE user_id = p_admin_id), 'approve');

  RETURN json_build_object('success', TRUE, 'auto_live', COALESCE(v_auto_live, FALSE));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
