-- ============================================================================
-- Migration 00155: Notify Invitees on Listing Status Change
-- ============================================================================
-- 1. Adds 'listing_status_update' notification type
-- 2. Updates notify_auction_invite to include listing_status in data
-- 3. Updates trigger_notify_auction_status_change to notify accepted invitees
--    of private auctions when status changes (e.g. pending→approved, approved→live)
-- ============================================================================

-- ============================================================================
-- STEP 1: Add listing_status_update notification type
-- ============================================================================

ALTER TABLE public.notification_types DROP CONSTRAINT IF EXISTS notification_types_type_name_check;

INSERT INTO public.notification_types (type_name, display_name) VALUES
  ('listing_status_update', 'Listing Status Update')
ON CONFLICT (type_name) DO NOTHING;

ALTER TABLE public.notification_types ADD CONSTRAINT notification_types_type_name_check
  CHECK (type_name IN (
    'bid_placed', 'outbid', 'auction_won', 'auction_lost',
    'auction_ending', 'payment_received', 'kyc_approved',
    'kyc_rejected', 'message_received', 'auction_approved',
    'auction_cancelled', 'auction_invite', 'auction_invite_accepted',
    'auction_invite_rejected', 'new_question', 'qa_reply',
    'transaction_started', 'auction_live', 'auction_ended',
    'forms_confirmed', 'chat_message', 'review_received', 'activity_log',
    'listing_status_update'
  ));

-- ============================================================================
-- STEP 2: Update notify_auction_invite to include listing_status in data
-- ============================================================================

DROP FUNCTION IF EXISTS public.notify_auction_invite(uuid, uuid, uuid, text, text);

CREATE OR REPLACE FUNCTION public.notify_auction_invite(
  p_user_id uuid,
  p_auction_id uuid,
  p_invite_id uuid,
  p_type_name text,
  p_inviter_name text DEFAULT NULL
) RETURNS void AS $$
DECLARE
  v_type_id uuid;
  v_listing_status text;
BEGIN
  SELECT id INTO v_type_id FROM public.notification_types WHERE type_name = p_type_name;

  IF v_type_id IS NULL THEN
    RAISE EXCEPTION 'Notification type % not found', p_type_name;
  END IF;

  -- Resolve current listing status
  SELECT s.status_name INTO v_listing_status
  FROM public.auctions a
  JOIN public.auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

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
      'listing_status', COALESCE(v_listing_status, 'unknown')
    ),
    FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- STEP 3: Update auction status change trigger to also notify invitees
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_notify_auction_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_old_status TEXT;
  v_new_status TEXT;
  v_auction_title TEXT;
  v_seller_id UUID;
  v_winning_bidder_id UUID;
  v_winning_amount NUMERIC;
  v_losing_bidder RECORD;
  v_invitee RECORD;
  v_display_status TEXT;
BEGIN
  -- Only fire if status_id actually changed
  IF OLD.status_id = NEW.status_id THEN
    RETURN NEW;
  END IF;

  -- Resolve old and new status names
  SELECT s.status_name INTO v_old_status
  FROM public.auction_statuses s WHERE s.id = OLD.status_id;

  SELECT s.status_name INTO v_new_status
  FROM public.auction_statuses s WHERE s.id = NEW.status_id;

  v_auction_title := NEW.title;
  v_seller_id := NEW.seller_id;

  -- Human-readable status label
  v_display_status := CASE v_new_status
    WHEN 'pending_approval' THEN 'Pending Approval'
    WHEN 'scheduled' THEN 'Approved'
    WHEN 'live' THEN 'Live'
    WHEN 'ended' THEN 'Ended'
    WHEN 'sold' THEN 'Sold'
    WHEN 'unsold' THEN 'Unsold'
    WHEN 'cancelled' THEN 'Cancelled'
    ELSE initcap(replace(v_new_status, '_', ' '))
  END;

  -- ---- LISTING APPROVED (pending_approval → scheduled) ----
  IF v_old_status = 'pending_approval' AND v_new_status = 'scheduled' THEN
    PERFORM public.create_notification(
      v_seller_id,
      'auction_approved',
      'Listing approved!',
      format('Your listing "%s" has been approved and is scheduled to go live.', v_auction_title),
      'auction',
      NEW.id,
      jsonb_build_object('auction_id', NEW.id, 'start_time', NEW.start_time),
      'high'
    );
  END IF;

  -- ---- AUCTION LIVE (scheduled → live or pending_approval → live) ----
  IF v_new_status = 'live' AND v_old_status IN ('scheduled', 'pending_approval') THEN
    PERFORM public.create_notification(
      v_seller_id,
      'auction_live',
      'Your auction is live!',
      format('"%s" is now live. Bidders can start placing bids.', v_auction_title),
      'auction',
      NEW.id,
      jsonb_build_object('auction_id', NEW.id),
      'high'
    );
  END IF;

  -- ---- AUCTION ENDED (live → ended/sold/unsold) ----
  IF v_old_status = 'live' AND v_new_status IN ('ended', 'sold', 'unsold') THEN

    -- Notify seller
    PERFORM public.create_notification(
      v_seller_id,
      'auction_ended',
      'Auction ended',
      format('Your auction "%s" has ended.', v_auction_title),
      'auction',
      NEW.id,
      jsonb_build_object('auction_id', NEW.id, 'final_status', v_new_status),
      'high'
    );

    -- Find winning bidder (highest bid)
    SELECT b.bidder_id, b.bid_amount INTO v_winning_bidder_id, v_winning_amount
    FROM public.bids b
    WHERE b.auction_id = NEW.id
    ORDER BY b.bid_amount DESC
    LIMIT 1;

    IF v_new_status = 'sold' AND v_winning_bidder_id IS NOT NULL THEN
      -- Notify winner
      PERFORM public.create_notification(
        v_winning_bidder_id,
        'auction_won',
        'Congratulations! You won!',
        format('You won the auction "%s" with a bid of ₱%s!',
          v_auction_title, to_char(v_winning_amount, 'FM999,999,999.00')),
        'auction',
        NEW.id,
        jsonb_build_object(
          'auction_id', NEW.id,
          'winning_amount', v_winning_amount
        ),
        'urgent'
      );

      -- Notify all losing bidders
      FOR v_losing_bidder IN
        SELECT DISTINCT b.bidder_id, MAX(b.bid_amount) as max_bid
        FROM public.bids b
        WHERE b.auction_id = NEW.id
          AND b.bidder_id <> v_winning_bidder_id
        GROUP BY b.bidder_id
      LOOP
        PERFORM public.create_notification(
          v_losing_bidder.bidder_id,
          'auction_lost',
          'Auction ended',
          format('The auction "%s" has ended. Unfortunately, you did not win.', v_auction_title),
          'auction',
          NEW.id,
          jsonb_build_object(
            'auction_id', NEW.id,
            'your_max_bid', v_losing_bidder.max_bid,
            'winning_amount', v_winning_amount
          ),
          'normal'
        );
      END LOOP;

    ELSIF v_new_status IN ('ended', 'unsold') THEN
      -- Notify all bidders the auction ended without a sale
      FOR v_losing_bidder IN
        SELECT DISTINCT b.bidder_id
        FROM public.bids b
        WHERE b.auction_id = NEW.id
      LOOP
        PERFORM public.create_notification(
          v_losing_bidder.bidder_id,
          'auction_lost',
          'Auction ended without a winner',
          format('The auction "%s" has ended without meeting the reserve price.', v_auction_title),
          'auction',
          NEW.id,
          jsonb_build_object('auction_id', NEW.id, 'final_status', v_new_status),
          'normal'
        );
      END LOOP;
    END IF;
  END IF;

  -- ---- AUCTION CANCELLED ----
  IF v_new_status = 'cancelled' THEN
    -- Notify seller
    PERFORM public.create_notification(
      v_seller_id,
      'auction_cancelled',
      'Auction cancelled',
      format('Your auction "%s" has been cancelled.', v_auction_title),
      'auction',
      NEW.id,
      jsonb_build_object('auction_id', NEW.id),
      'high'
    );

    -- Notify all bidders
    FOR v_losing_bidder IN
      SELECT DISTINCT b.bidder_id
      FROM public.bids b
      WHERE b.auction_id = NEW.id
    LOOP
      PERFORM public.create_notification(
        v_losing_bidder.bidder_id,
        'auction_cancelled',
        'Auction cancelled',
        format('The auction "%s" you were bidding on has been cancelled.', v_auction_title),
        'auction',
        NEW.id,
        jsonb_build_object('auction_id', NEW.id),
        'high'
      );
    END LOOP;
  END IF;

  -- ====================================================================
  -- NOTIFY ACCEPTED INVITEES of private/exclusive auctions on status change
  -- ====================================================================
  IF NEW.visibility IN ('private', 'exclusive') THEN
    FOR v_invitee IN
      SELECT ai.invitee_user_id
      FROM public.auction_invites ai
      WHERE ai.auction_id = NEW.id
        AND ai.status = 'accepted'
        AND ai.invitee_user_id IS NOT NULL
    LOOP
      PERFORM public.create_notification(
        v_invitee.invitee_user_id,
        'listing_status_update',
        'Auction Status Update',
        format('The auction "%s" you were invited to is now %s.', v_auction_title, v_display_status),
        'auction',
        NEW.id,
        jsonb_build_object(
          'auction_id', NEW.id,
          'listing_status', v_new_status,
          'old_status', v_old_status
        ),
        CASE
          WHEN v_new_status = 'live' THEN 'high'
          ELSE 'normal'
        END
      );
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_auction_status_change ON public.auctions;
CREATE TRIGGER trg_notify_auction_status_change
  AFTER UPDATE ON public.auctions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_auction_status_change();
