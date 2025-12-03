-- ============================================================================
-- NOTIFICATIONS SCHEMA
-- Comprehensive notification system for user updates
-- ============================================================================

-- Notification types enum
CREATE TYPE notification_type AS ENUM (
    'bid_update',
    'auction_update',
    'listing_update',
    'transaction',
    'system',
    'message'
);

-- Notification priority enum
CREATE TYPE notification_priority AS ENUM (
    'low',
    'normal',
    'high',
    'urgent'
);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    type notification_type NOT NULL,
    priority notification_priority NOT NULL DEFAULT 'normal',
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    related_entity_id UUID,  -- ID of related auction, listing, bid, etc.
    related_entity_type TEXT, -- 'auction', 'listing', 'bid', 'transaction', etc.
    metadata JSONB,          -- Additional data for the notification
    created_at TIMESTAMPTZ DEFAULT NOW(),
    read_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_user_unread ON notifications(user_id, is_read)
    WHERE is_read = FALSE AND deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type) WHERE deleted_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_notifications_related_entity ON notifications(related_entity_id, related_entity_type)
    WHERE deleted_at IS NULL;

-- Row Level Security
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- RLS Policy: Users can only see their own notifications
CREATE POLICY notifications_select_own ON notifications
    FOR SELECT
    USING (user_id = auth.uid() AND deleted_at IS NULL);

-- RLS Policy: Users can update their own notifications (mark as read)
CREATE POLICY notifications_update_own ON notifications
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- RLS Policy: Users can delete their own notifications (soft delete)
CREATE POLICY notifications_delete_own ON notifications
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- RLS Policy: System can insert notifications for any user
CREATE POLICY notifications_insert_system ON notifications
    FOR INSERT
    WITH CHECK (true);

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to create a notification
CREATE OR REPLACE FUNCTION create_notification(
    p_user_id UUID,
    p_type notification_type,
    p_priority notification_priority,
    p_title TEXT,
    p_message TEXT,
    p_related_entity_id UUID DEFAULT NULL,
    p_related_entity_type TEXT DEFAULT NULL,
    p_metadata JSONB DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_notification_id UUID;
BEGIN
    INSERT INTO notifications (
        user_id,
        type,
        priority,
        title,
        message,
        related_entity_id,
        related_entity_type,
        metadata
    ) VALUES (
        p_user_id,
        p_type,
        p_priority,
        p_title,
        p_message,
        p_related_entity_id,
        p_related_entity_type,
        p_metadata
    )
    RETURNING id INTO v_notification_id;

    RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(p_notification_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = NOW()
    WHERE id = p_notification_id
        AND user_id = auth.uid()
        AND is_read = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark all notifications as read for a user
CREATE OR REPLACE FUNCTION mark_all_notifications_read()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE notifications
    SET is_read = TRUE,
        read_at = NOW()
    WHERE user_id = auth.uid()
        AND is_read = FALSE
        AND deleted_at IS NULL;

    GET DIAGNOSTICS v_count = ROW_COUNT;
    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to soft delete a notification
CREATE OR REPLACE FUNCTION delete_notification(p_notification_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE notifications
    SET deleted_at = NOW()
    WHERE id = p_notification_id
        AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_count()
RETURNS INTEGER AS $$
DECLARE
    v_count INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM notifications
    WHERE user_id = auth.uid()
        AND is_read = FALSE
        AND deleted_at IS NULL;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- EXAMPLE TRIGGER: Auto-notify when user wins an auction
-- ============================================================================
-- This is an example - you'll create similar triggers for other events

CREATE OR REPLACE FUNCTION notify_auction_won()
RETURNS TRIGGER AS $$
BEGIN
    -- When an auction ends and there's a winning bidder
    IF NEW.status = 'completed' AND NEW.winner_id IS NOT NULL THEN
        PERFORM create_notification(
            NEW.winner_id,
            'auction_update'::notification_type,
            'high'::notification_priority,
            'Congratulations! You Won!',
            'You won the auction for ' || NEW.title,
            NEW.id,
            'auction',
            jsonb_build_object('auction_id', NEW.id, 'final_price', NEW.current_bid)
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Note: Uncomment when auctions table exists
-- CREATE TRIGGER trigger_notify_auction_won
--     AFTER UPDATE ON auctions
--     FOR EACH ROW
--     WHEN (NEW.status = 'completed' AND OLD.status != 'completed')
--     EXECUTE FUNCTION notify_auction_won();
