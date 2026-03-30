-- ============================================================================
-- Migration 00153: Fix notify_auction_invite function ambiguity
-- ============================================================================
-- PROBLEM: Two overloads of notify_auction_invite exist:
--   1) (uuid, uuid, uuid, text)          — from migration 00053
--   2) (uuid, uuid, uuid, text, text)    — from migration 00121 (5th param DEFAULT NULL)
-- When called with 4 args, PostgreSQL error 42725: "function is not unique"
-- because both signatures match.
--
-- FIX: Drop the old 4-param version. The 5-param version with DEFAULT NULL
-- handles all call sites.
-- ============================================================================

-- Drop the old 4-param overload (exact signature match required for DROP)
DROP FUNCTION IF EXISTS public.notify_auction_invite(uuid, uuid, uuid, text);

-- Re-create ONLY the 5-param version (idempotent)
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
      'invite_id', p_invite_id
    ),
    FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
