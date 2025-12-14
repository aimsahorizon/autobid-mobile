-- Add auction visibility (public/private) and invitations schema

-- 1) Add bidding_type/visibility to auctions
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'auction_visibility'
  ) THEN
    CREATE TYPE auction_visibility AS ENUM ('public', 'private');
  END IF;
END $$;

ALTER TABLE public.auctions
  ADD COLUMN IF NOT EXISTS visibility auction_visibility NOT NULL DEFAULT 'public';

-- 2) Invitations table
CREATE TABLE IF NOT EXISTS public.auction_invites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id uuid NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  inviter_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  -- invitee can be matched by username or email; we'll store both when provided
  invitee_username text,
  invitee_email text,
  -- resolved user if matched
  invitee_user_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
  status text NOT NULL DEFAULT 'pending', -- pending|accepted|rejected
  created_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz
);

CREATE INDEX IF NOT EXISTS idx_auction_invites_auction ON public.auction_invites(auction_id);
CREATE INDEX IF NOT EXISTS idx_auction_invites_invitee_user ON public.auction_invites(invitee_user_id);

ALTER TABLE public.auction_invites ENABLE ROW LEVEL SECURITY;

-- RLS: inviter can manage invites for their auctions; invitee can read/respond to their own
CREATE POLICY "inviter manage invites"
  ON public.auction_invites
  FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.auctions a
      WHERE a.id = auction_id AND a.seller_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.auctions a
      WHERE a.id = auction_id AND a.seller_id = auth.uid()
    )
  );

CREATE POLICY "invitee read/respond"
  ON public.auction_invites
  FOR SELECT USING (
    invitee_user_id = auth.uid()
  );

CREATE POLICY "invitee update status"
  ON public.auction_invites
  FOR UPDATE USING (
    invitee_user_id = auth.uid()
  ) WITH CHECK (
    invitee_user_id = auth.uid()
  );

-- 3) Add auction notification types and helper for inserting notifications
CREATE TABLE IF NOT EXISTS public.notifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  type text NOT NULL, -- auction_invite|auction_invite_accepted|auction_invite_rejected
  title text,
  body text,
  data jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  is_read boolean NOT NULL DEFAULT false
);

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user read notifications" ON public.notifications
  FOR SELECT USING (user_id = auth.uid());
CREATE POLICY "user insert notifications" ON public.notifications
  FOR INSERT WITH CHECK (user_id = auth.uid());
CREATE POLICY "user update own notifications" ON public.notifications
  FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 4) Helper views/RPCs
-- View update: filter auction_browse_listings to show private auctions only to accepted invitees
-- We create a helper view for authorized visible auctions
CREATE OR REPLACE VIEW public.authorized_auctions AS
SELECT a.*
FROM public.auctions a
WHERE a.visibility = 'public'
   OR EXISTS (
     SELECT 1 FROM public.auction_invites ai
     WHERE ai.auction_id = a.id
       AND ai.status = 'accepted'
       AND ai.invitee_user_id = auth.uid()
   );

-- RPC: invite user by username/email
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

  -- Notify invitee
  IF v_invitee_user_id IS NOT NULL THEN
    INSERT INTO public.notifications(user_id, type, title, body, data)
    VALUES (
      v_invitee_user_id,
      'auction_invite',
      'Auction Invite',
      'You have been invited to a private auction.',
      jsonb_build_object('auction_id', p_auction_id, 'invite_id', v_invite_id)
    );
  END IF;

  RETURN v_invite_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: respond to invite
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

  -- Notify inviter about decision
  INSERT INTO public.notifications(user_id, type, title, body, data)
  VALUES (
    v_ai.inviter_id,
    CASE WHEN p_decision = 'accepted' THEN 'auction_invite_accepted' ELSE 'auction_invite_rejected' END,
    'Invite Response',
    CASE WHEN p_decision = 'accepted' THEN 'Your invite was accepted.' ELSE 'Your invite was rejected.' END,
    jsonb_build_object('auction_id', v_ai.auction_id, 'invite_id', p_invite_id)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC: list invites for current user
CREATE OR REPLACE FUNCTION public.list_my_auction_invites() RETURNS SETOF public.auction_invites AS $$
BEGIN
  RETURN QUERY SELECT * FROM public.auction_invites WHERE invitee_user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
