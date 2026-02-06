-- ============================================================================
-- AutoBid Mobile - Migration 00089: Update Respond to Invite RPC
-- ============================================================================
-- Updates the respond_to_auction_invite function to also update the 
-- invitee's notification status so the UI can reflect the decision.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.respond_to_auction_invite(
  p_invite_id uuid,
  p_decision text -- 'accepted' or 'rejected'
) RETURNS void AS $$
DECLARE
  v_ai RECORD;
BEGIN
  -- 1. Get invite details and verify ownership
  SELECT * INTO v_ai FROM public.auction_invites WHERE id = p_invite_id;
  
  IF v_ai IS NULL THEN
    RAISE EXCEPTION 'Invite not found';
  END IF;

  IF v_ai.invitee_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'Not authorized to respond to this invite';
  END IF;

  -- 2. Update invite status
  UPDATE public.auction_invites
    SET status = p_decision,
        responded_at = now()
    WHERE id = p_invite_id;

  -- 3. Update the original notification for the invitee
  -- We use the invite_id in the jsonb data to find the right notification
  UPDATE public.notifications
    SET data = data || jsonb_build_object('invite_status', p_decision),
        is_read = true,
        read_at = now()
    WHERE user_id = auth.uid()
      AND (data->>'invite_id')::uuid = p_invite_id;

  -- 4. Notify inviter about decision using helper function
  PERFORM public.notify_auction_invite(
    v_ai.inviter_id,
    v_ai.auction_id,
    p_invite_id,
    CASE WHEN p_decision = 'accepted' THEN 'auction_invite_accepted' ELSE 'auction_invite_rejected' END
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
