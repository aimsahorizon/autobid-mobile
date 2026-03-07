-- ============================================================================
-- AutoBid Mobile - Migration 00121: Add inviter name to invite notifications
-- ============================================================================
-- Updates notify_auction_invite to accept and display inviter name in message.
-- Updates invite_user_to_auction to pass the inviter's name.
-- ============================================================================

-- 1. Update helper function to accept inviter_name parameter
CREATE OR REPLACE FUNCTION public.notify_auction_invite(
  p_user_id uuid,
  p_auction_id uuid,
  p_invite_id uuid,
  p_type_name text,
  p_inviter_name text DEFAULT NULL
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
      WHEN p_type_name = 'auction_invite' AND p_inviter_name IS NOT NULL
        THEN p_inviter_name || ' has invited you to a private auction.'
      WHEN p_type_name = 'auction_invite'
        THEN 'You have been invited to a private auction.'
      WHEN p_type_name = 'auction_invite_accepted' AND p_inviter_name IS NOT NULL
        THEN p_inviter_name || ' has accepted your auction invitation.'
      WHEN p_type_name = 'auction_invite_accepted'
        THEN 'Your auction invitation was accepted.'
      WHEN p_type_name = 'auction_invite_rejected' AND p_inviter_name IS NOT NULL
        THEN p_inviter_name || ' has declined your auction invitation.'
      WHEN p_type_name = 'auction_invite_rejected'
        THEN 'Your auction invitation was rejected.'
      ELSE 'You have a new auction notification.'
    END,
    jsonb_build_object(
      'auction_id', p_auction_id,
      'invite_id', p_invite_id,
      'inviter_name', COALESCE(p_inviter_name, '')
    ),
    false
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update invite_user_to_auction to resolve and pass inviter name
CREATE OR REPLACE FUNCTION public.invite_user_to_auction(
  p_auction_id uuid,
  p_invitee_identifier text,
  p_identifier_type text -- 'username' or 'email'
) RETURNS uuid AS $$
DECLARE
  v_invitee_user_id uuid;
  v_invite_id uuid;
  v_inviter_name text;
BEGIN
  -- Check seller owns the auction
  IF NOT EXISTS (
    SELECT 1 FROM public.auctions a
    WHERE a.id = p_auction_id AND a.seller_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to invite for this auction';
  END IF;

  -- Resolve inviter name
  SELECT COALESCE(
    raw_user_meta_data->>'full_name',
    raw_user_meta_data->>'display_name',
    raw_user_meta_data->>'username',
    email
  ) INTO v_inviter_name
  FROM auth.users
  WHERE id = auth.uid();

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

  -- Notify invitee with inviter name
  IF v_invitee_user_id IS NOT NULL THEN
    PERFORM public.notify_auction_invite(v_invitee_user_id, p_auction_id, v_invite_id, 'auction_invite', v_inviter_name);
  END IF;

  RETURN v_invite_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Update respond_to_auction_invite to also pass responder name to inviter
CREATE OR REPLACE FUNCTION public.respond_to_auction_invite(
  p_invite_id uuid,
  p_decision text -- 'accepted' or 'rejected'
) RETURNS void AS $$
DECLARE
  v_ai RECORD;
  v_responder_name text;
BEGIN
  -- 1. Get invite details and verify ownership
  SELECT * INTO v_ai FROM public.auction_invites WHERE id = p_invite_id;
  
  IF v_ai IS NULL THEN
    RAISE EXCEPTION 'Invite not found';
  END IF;

  IF v_ai.invitee_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to respond to this invite';
  END IF;

  -- 2. Get responder name
  SELECT COALESCE(
    raw_user_meta_data->>'full_name',
    raw_user_meta_data->>'display_name',
    raw_user_meta_data->>'username',
    email
  ) INTO v_responder_name
  FROM auth.users
  WHERE id = auth.uid();

  -- 3. Update invite status
  UPDATE public.auction_invites
    SET status = p_decision,
        responded_at = now()
    WHERE id = p_invite_id;

  -- 4. Update the original notification for the invitee
  UPDATE public.notifications
    SET data = data || jsonb_build_object('invite_status', p_decision),
        is_read = true,
        read_at = now()
    WHERE user_id = auth.uid()
      AND (data->>'invite_id')::uuid = p_invite_id;

  -- 5. Notify inviter about decision with responder name
  PERFORM public.notify_auction_invite(
    v_ai.inviter_id,
    v_ai.auction_id,
    p_invite_id,
    CASE WHEN p_decision = 'accepted' THEN 'auction_invite_accepted' ELSE 'auction_invite_rejected' END,
    v_responder_name
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
