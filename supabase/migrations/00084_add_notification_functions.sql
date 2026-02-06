-- ============================================================================
-- AutoBid Mobile - Migration 00084: Add Notification Management Functions
-- ============================================================================
-- Adds missing RPC functions required by NotificationSupabaseDataSource
-- ============================================================================

-- Function to mark a single notification as read
CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id uuid)
RETURNS void AS $$
BEGIN
  UPDATE public.notifications
  SET is_read = true,
      read_at = now()
  WHERE id = p_notification_id
  AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for the current user
CREATE OR REPLACE FUNCTION public.mark_all_notifications_read()
RETURNS integer AS $$
DECLARE
  v_count integer;
BEGIN
  WITH updated AS (
    UPDATE public.notifications
    SET is_read = true,
        read_at = now()
    WHERE user_id = auth.uid()
    AND is_read = false
    RETURNING 1
  )
  SELECT count(*) INTO v_count FROM updated;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete a notification
CREATE OR REPLACE FUNCTION public.delete_notification(p_notification_id uuid)
RETURNS void AS $$
BEGIN
  DELETE FROM public.notifications
  WHERE id = p_notification_id
  AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION public.get_unread_count()
RETURNS integer AS $$
DECLARE
  v_count integer;
BEGIN
  SELECT count(*) INTO v_count
  FROM public.notifications
  WHERE user_id = auth.uid()
  AND is_read = false;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions
GRANT EXECUTE ON FUNCTION public.mark_notification_read(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.mark_all_notifications_read() TO authenticated;
GRANT EXECUTE ON FUNCTION public.delete_notification(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_unread_count() TO authenticated;
