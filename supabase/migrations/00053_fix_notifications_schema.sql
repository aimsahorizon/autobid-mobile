-- Fix notifications table to use existing schema instead of creating duplicate with wrong columns
-- Since 00051 was already applied, we need to ensure notifications table exists with correct schema

-- Recreate notifications table if it doesn't exist (with correct schema from 00001)
CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type_id UUID NOT NULL REFERENCES public.notification_types(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON public.notifications(is_read);

-- Enable RLS
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies if they don't exist
DROP POLICY IF EXISTS "user read notifications" ON public.notifications;
CREATE POLICY "user read notifications" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "user insert notifications" ON public.notifications;
CREATE POLICY "user insert notifications" ON public.notifications
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "user update own notifications" ON public.notifications;
CREATE POLICY "user update own notifications" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- Add the new notification types if they don't exist
-- First, we need to update the CHECK constraint to allow our new types
ALTER TABLE public.notification_types DROP CONSTRAINT IF EXISTS notification_types_type_name_check;

INSERT INTO public.notification_types (type_name, display_name)
VALUES 
  ('auction_invite', 'Auction Invite'),
  ('auction_invite_accepted', 'Invite Accepted'),
  ('auction_invite_rejected', 'Invite Rejected')
ON CONFLICT (type_name) DO NOTHING;

-- Helper function to create auction invitation notifications using correct schema
CREATE OR REPLACE FUNCTION public.notify_auction_invite(
  p_user_id uuid,
  p_auction_id uuid,
  p_invite_id uuid,
  p_type_name text
) RETURNS void AS $$
DECLARE
  v_type_id uuid;
BEGIN
  SELECT id INTO v_type_id FROM public.notification_types WHERE type_name = p_type_name;
  
  IF v_type_id IS NULL THEN
    RAISE EXCEPTION 'Notification type % not found', p_type_name;
  END IF;
  
  INSERT INTO public.notifications(user_id, type_id, title, message, data, is_read)
  VALUES (
    p_user_id,
    v_type_id,
    CASE 
      WHEN p_type_name = 'auction_invite' THEN 'Auction Invite'
      WHEN p_type_name = 'auction_invite_accepted' THEN 'Invite Accepted'
      WHEN p_type_name = 'auction_invite_rejected' THEN 'Invite Rejected'
      ELSE 'Auction Notification'
    END,
    CASE 
      WHEN p_type_name = 'auction_invite' THEN 'You have been invited to a private auction.'
      WHEN p_type_name = 'auction_invite_accepted' THEN 'Your auction invitation was accepted.'
      WHEN p_type_name = 'auction_invite_rejected' THEN 'Your auction invitation was rejected.'
      ELSE 'You have a new auction notification.'
    END,
    jsonb_build_object('auction_id', p_auction_id, 'invite_id', p_invite_id),
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update RPCs to use the helper function
CREATE OR REPLACE FUNCTION public.invite_user_to_auction(
  p_auction_id uuid,
  p_invitee_identifier text,
  p_identifier_type text -- 'username' or 'email'
) RETURNS uuid AS $$
DECLARE
  v_invitee_user_id uuid;
  v_invite_id uuid;
BEGIN
  -- Check seller owns the auction
  IF NOT EXISTS (
    SELECT 1 FROM public.auctions a
    WHERE a.id = p_auction_id AND a.seller_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to invite for this auction';
  END IF;

  -- Resolve invitee user id by identifier
  IF p_identifier_type = 'username' THEN
    SELECT id INTO v_invitee_user_id FROM auth.users WHERE raw_user_meta_data->>'username' = p_invitee_identifier;
  ELSIF p_identifier_type = 'email' THEN
    SELECT id INTO v_invitee_user_id FROM auth.users WHERE email = p_invitee_identifier;
  ELSE
    RAISE EXCEPTION 'Invalid identifier type';
  END IF;

  -- Insert invite
  INSERT INTO public.auction_invites(auction_id, inviter_id, invitee_user_id, invitee_username, invitee_email, status)
  VALUES (
    p_auction_id,
    auth.uid(),
    v_invitee_user_id,
    CASE WHEN p_identifier_type = 'username' THEN p_invitee_identifier ELSE NULL END,
    CASE WHEN p_identifier_type = 'email' THEN p_invitee_identifier ELSE NULL END,
    'pending'
  ) RETURNING id INTO v_invite_id;

  -- Notify invitee using helper function
  IF v_invitee_user_id IS NOT NULL THEN
    PERFORM public.notify_auction_invite(v_invitee_user_id, p_auction_id, v_invite_id, 'auction_invite');
  END IF;

  RETURN v_invite_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update respond RPC
CREATE OR REPLACE FUNCTION public.respond_to_auction_invite(
  p_invite_id uuid,
  p_decision text -- 'accepted' or 'rejected'
) RETURNS void AS $$
DECLARE
  v_ai RECORD;
BEGIN
  SELECT * INTO v_ai FROM public.auction_invites WHERE id = p_invite_id;
  IF v_ai.invitee_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to respond to this invite';
  END IF;

  UPDATE public.auction_invites
    SET status = p_decision,
        responded_at = now()
    WHERE id = p_invite_id;

  -- Notify inviter about decision using helper function
  PERFORM public.notify_auction_invite(
    v_ai.inviter_id,
    v_ai.auction_id,
    p_invite_id,
    CASE WHEN p_decision = 'accepted' THEN 'auction_invite_accepted' ELSE 'auction_invite_rejected' END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
