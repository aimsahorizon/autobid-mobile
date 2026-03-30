-- ============================================================================
-- AutoBid Mobile - Migration 00106: Comprehensive Notification Triggers
-- ============================================================================
-- Creates database triggers that automatically generate notifications for
-- Buyer, Seller, and Transaction events. Uses SECURITY DEFINER helper
-- function to bypass RLS when inserting notifications from triggers.
-- ============================================================================

-- ============================================================================
-- STEP 1: Add new notification types
-- ============================================================================

-- Drop the CHECK constraint on notification_types.type_name so we can add new types
ALTER TABLE public.notification_types DROP CONSTRAINT IF EXISTS notification_types_type_name_check;

INSERT INTO public.notification_types (type_name, display_name) VALUES
  ('new_question', 'New Question'),
  ('qa_reply', 'Q&A Reply'),
  ('transaction_started', 'Transaction Started'),
  ('auction_live', 'Auction Live'),
  ('auction_ended', 'Auction Ended'),
  ('forms_confirmed', 'Forms Confirmed'),
  ('chat_message', 'Chat Message'),
  ('review_received', 'Review Received'),
  ('activity_log', 'Activity Log')
ON CONFLICT (type_name) DO NOTHING;

-- Re-add CHECK constraint with all types
ALTER TABLE public.notification_types ADD CONSTRAINT notification_types_type_name_check
  CHECK (type_name IN (
    'bid_placed', 'outbid', 'auction_won', 'auction_lost',
    'auction_ending', 'payment_received', 'kyc_approved',
    'kyc_rejected', 'message_received', 'auction_approved',
    'auction_cancelled', 'auction_invite', 'auction_invite_accepted',
    'auction_invite_rejected', 'new_question', 'qa_reply',
    'transaction_started', 'auction_live', 'auction_ended',
    'forms_confirmed', 'chat_message', 'review_received', 'activity_log'
  ));

-- ============================================================================
-- STEP 2: Enable notifications table in realtime publication
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE notifications;
  END IF;
END $$;

-- ============================================================================
-- STEP 3: Core helper function to create notifications
-- ============================================================================

CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_type_name TEXT,
  p_title TEXT,
  p_message TEXT,
  p_related_entity_type TEXT DEFAULT NULL,
  p_related_entity_id UUID DEFAULT NULL,
  p_data JSONB DEFAULT '{}'::JSONB,
  p_priority TEXT DEFAULT 'normal'
) RETURNS UUID AS $$
DECLARE
  v_type_id UUID;
  v_notification_id UUID;
BEGIN
  -- Don't notify the user about their own actions (caller should handle this)
  IF p_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Resolve the notification type
  SELECT id INTO v_type_id FROM public.notification_types WHERE type_name = p_type_name;

  IF v_type_id IS NULL THEN
    -- Fallback to 'message_received' type if the specific type doesn't exist
    SELECT id INTO v_type_id FROM public.notification_types WHERE type_name = 'message_received';
    IF v_type_id IS NULL THEN
      RAISE WARNING 'Notification type "%" not found, skipping notification', p_type_name;
      RETURN NULL;
    END IF;
  END IF;

  INSERT INTO public.notifications (
    user_id, type_id, title, message, data, is_read,
    created_at
  ) VALUES (
    p_user_id, v_type_id, p_title, p_message,
    p_data || jsonb_build_object(
      'related_entity_type', p_related_entity_type,
      'related_entity_id', p_related_entity_id,
      'priority', p_priority,
      'notification_type', p_type_name
    ),
    FALSE, NOW()
  ) RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION public.create_notification(UUID, TEXT, TEXT, TEXT, TEXT, UUID, JSONB, TEXT) TO authenticated;

-- ============================================================================
-- STEP 4: BUYER NOTIFICATIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 4A. OUTBID: When a new bid is placed, notify the previous highest bidder
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_outbid()
RETURNS TRIGGER AS $$
DECLARE
  v_previous_bidder_id UUID;
  v_auction_title TEXT;
  v_new_amount NUMERIC;
BEGIN
  -- Get auction title
  SELECT a.title INTO v_auction_title
  FROM public.auctions a
  WHERE a.id = NEW.auction_id;

  v_new_amount := NEW.bid_amount;

  -- Find the previous highest bidder (not the new bidder)
  SELECT b.bidder_id INTO v_previous_bidder_id
  FROM public.bids b
  WHERE b.auction_id = NEW.auction_id
    AND b.bidder_id <> NEW.bidder_id
    AND b.id <> NEW.id
  ORDER BY b.bid_amount DESC
  LIMIT 1;

  -- Notify previous highest bidder they've been outbid
  IF v_previous_bidder_id IS NOT NULL THEN
    PERFORM public.create_notification(
      v_previous_bidder_id,
      'outbid',
      'You''ve been outbid!',
      format('Someone placed a higher bid of ₱%s on "%s"', 
        to_char(v_new_amount, 'FM999,999,999.00'), v_auction_title),
      'auction',
      NEW.auction_id,
      jsonb_build_object(
        'bid_id', NEW.id,
        'bid_amount', v_new_amount,
        'auction_id', NEW.auction_id
      ),
      'high'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_outbid ON public.bids;
CREATE TRIGGER trg_notify_outbid
  AFTER INSERT ON public.bids
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_outbid();

-- ---------------------------------------------------------------------------
-- 4B. SELLER: New Bid - Notify seller when a bid is placed on their auction
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_seller_new_bid()
RETURNS TRIGGER AS $$
DECLARE
  v_seller_id UUID;
  v_auction_title TEXT;
  v_bidder_name TEXT;
BEGIN
  -- Get auction seller and title
  SELECT a.seller_id, a.title INTO v_seller_id, v_auction_title
  FROM public.auctions a
  WHERE a.id = NEW.auction_id;

  -- Don't notify seller if they're bidding on their own auction (shouldn't happen, but safety)
  IF v_seller_id = NEW.bidder_id THEN
    RETURN NEW;
  END IF;

  -- Get bidder display name
  SELECT COALESCE(u.display_name, u.full_name, 'A buyer') INTO v_bidder_name
  FROM public.users u
  WHERE u.id = NEW.bidder_id;

  PERFORM public.create_notification(
    v_seller_id,
    'bid_placed',
    'New bid received!',
    format('%s placed a bid of ₱%s on "%s"',
      v_bidder_name, to_char(NEW.bid_amount, 'FM999,999,999.00'), v_auction_title),
    'auction',
    NEW.auction_id,
    jsonb_build_object(
      'bid_id', NEW.id,
      'bid_amount', NEW.bid_amount,
      'bidder_id', NEW.bidder_id,
      'auction_id', NEW.auction_id
    ),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_seller_new_bid ON public.bids;
CREATE TRIGGER trg_notify_seller_new_bid
  AFTER INSERT ON public.bids
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_seller_new_bid();

-- ============================================================================
-- STEP 5: AUCTION STATUS CHANGE NOTIFICATIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 5A. Auction status transitions: approved, live, ended, won/lost
-- ---------------------------------------------------------------------------

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

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_auction_status_change ON public.auctions;
CREATE TRIGGER trg_notify_auction_status_change
  AFTER UPDATE ON public.auctions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_auction_status_change();

-- ============================================================================
-- STEP 6: Q&A NOTIFICATIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 6A. New Question: Notify seller when someone asks a question
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_new_question()
RETURNS TRIGGER AS $$
DECLARE
  v_seller_id UUID;
  v_auction_title TEXT;
  v_asker_name TEXT;
BEGIN
  -- Get auction seller and title
  SELECT a.seller_id, a.title INTO v_seller_id, v_auction_title
  FROM public.auctions a
  WHERE a.id = NEW.auction_id;

  -- Don't notify seller if they asked their own question
  IF v_seller_id = NEW.user_id THEN
    RETURN NEW;
  END IF;

  -- Get asker's display name
  SELECT COALESCE(u.display_name, u.full_name, 'A buyer') INTO v_asker_name
  FROM public.users u
  WHERE u.id = NEW.user_id;

  PERFORM public.create_notification(
    v_seller_id,
    'new_question',
    'New question on your listing',
    format('%s asked a question on "%s": "%s"',
      v_asker_name, v_auction_title,
      LEFT(NEW.question, 80) || CASE WHEN LENGTH(NEW.question) > 80 THEN '...' ELSE '' END),
    'auction',
    NEW.auction_id,
    jsonb_build_object(
      'question_id', NEW.id,
      'auction_id', NEW.auction_id,
      'category', NEW.category
    ),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_new_question ON public.auction_questions;
CREATE TRIGGER trg_notify_new_question
  AFTER INSERT ON public.auction_questions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_new_question();

-- ---------------------------------------------------------------------------
-- 6B. Q&A Reply: Notify question asker when seller answers
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_qa_reply()
RETURNS TRIGGER AS $$
DECLARE
  v_question_user_id UUID;
  v_auction_id UUID;
  v_auction_title TEXT;
  v_seller_name TEXT;
BEGIN
  -- Get the question details
  SELECT q.user_id, q.auction_id INTO v_question_user_id, v_auction_id
  FROM public.auction_questions q
  WHERE q.id = NEW.question_id;

  -- Get auction title
  SELECT a.title INTO v_auction_title
  FROM public.auctions a
  WHERE a.id = v_auction_id;

  -- Don't notify the seller if they're answering their own question
  IF v_question_user_id = NEW.seller_id THEN
    RETURN NEW;
  END IF;

  -- Get seller's display name
  SELECT COALESCE(u.display_name, u.full_name, 'The seller') INTO v_seller_name
  FROM public.users u
  WHERE u.id = NEW.seller_id;

  PERFORM public.create_notification(
    v_question_user_id,
    'qa_reply',
    'Your question was answered',
    format('%s replied to your question on "%s": "%s"',
      v_seller_name, v_auction_title,
      LEFT(NEW.answer, 80) || CASE WHEN LENGTH(NEW.answer) > 80 THEN '...' ELSE '' END),
    'auction',
    v_auction_id,
    jsonb_build_object(
      'question_id', NEW.question_id,
      'answer_id', NEW.id,
      'auction_id', v_auction_id
    ),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_qa_reply ON public.auction_answers;
CREATE TRIGGER trg_notify_qa_reply
  AFTER INSERT ON public.auction_answers
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_qa_reply();

-- ============================================================================
-- STEP 7: TRANSACTION NOTIFICATIONS
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 7A. Transaction Started: Notify both buyer and seller
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_transaction_started()
RETURNS TRIGGER AS $$
DECLARE
  v_auction_title TEXT;
  v_buyer_name TEXT;
  v_seller_name TEXT;
BEGIN
  -- Get auction title
  SELECT a.title INTO v_auction_title
  FROM public.auctions a
  WHERE a.id = NEW.auction_id;

  -- Get names
  SELECT COALESCE(u.display_name, u.full_name, 'Buyer') INTO v_buyer_name
  FROM public.users u WHERE u.id = NEW.buyer_id;

  SELECT COALESCE(u.display_name, u.full_name, 'Seller') INTO v_seller_name
  FROM public.users u WHERE u.id = NEW.seller_id;

  -- Notify buyer
  PERFORM public.create_notification(
    NEW.buyer_id,
    'transaction_started',
    'Transaction started!',
    format('A transaction has been created for "%s". Please review and complete the required forms.',
      v_auction_title),
    'transaction',
    NEW.id,
    jsonb_build_object(
      'transaction_id', NEW.id,
      'auction_id', NEW.auction_id,
      'agreed_price', NEW.agreed_price,
      'other_party', v_seller_name
    ),
    'high'
  );

  -- Notify seller
  PERFORM public.create_notification(
    NEW.seller_id,
    'transaction_started',
    'Transaction started!',
    format('A transaction has been created for "%s" with %s. Please complete the required forms.',
      v_auction_title, v_buyer_name),
    'transaction',
    NEW.id,
    jsonb_build_object(
      'transaction_id', NEW.id,
      'auction_id', NEW.auction_id,
      'agreed_price', NEW.agreed_price,
      'other_party', v_buyer_name
    ),
    'high'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_transaction_started ON public.auction_transactions;
CREATE TRIGGER trg_notify_transaction_started
  AFTER INSERT ON public.auction_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_transaction_started();

-- ---------------------------------------------------------------------------
-- 7B. Forms Confirmed: Both parties confirmed → next phase
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_forms_confirmed()
RETURNS TRIGGER AS $$
DECLARE
  v_auction_title TEXT;
BEGIN
  -- Only fire when both parties have confirmed (transition moment)
  IF NEW.seller_confirmed = TRUE AND NEW.buyer_confirmed = TRUE
     AND (OLD.seller_confirmed = FALSE OR OLD.buyer_confirmed = FALSE) THEN

    SELECT a.title INTO v_auction_title
    FROM public.auctions a
    WHERE a.id = NEW.auction_id;

    -- Notify buyer
    PERFORM public.create_notification(
      NEW.buyer_id,
      'forms_confirmed',
      'Forms confirmed - Next phase!',
      format('Both parties have confirmed the transaction forms for "%s". The transaction is moving to the next phase.',
        v_auction_title),
      'transaction',
      NEW.id,
      jsonb_build_object(
        'transaction_id', NEW.id,
        'auction_id', NEW.auction_id
      ),
      'high'
    );

    -- Notify seller
    PERFORM public.create_notification(
      NEW.seller_id,
      'forms_confirmed',
      'Forms confirmed - Next phase!',
      format('Both parties have confirmed the transaction forms for "%s". The transaction is moving to the next phase.',
        v_auction_title),
      'transaction',
      NEW.id,
      jsonb_build_object(
        'transaction_id', NEW.id,
        'auction_id', NEW.auction_id
      ),
      'high'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_forms_confirmed ON public.auction_transactions;
CREATE TRIGGER trg_notify_forms_confirmed
  AFTER UPDATE ON public.auction_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_forms_confirmed();

-- ---------------------------------------------------------------------------
-- 7C. Chat Message: Notify the other party in a transaction
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_chat_message()
RETURNS TRIGGER AS $$
DECLARE
  v_transaction RECORD;
  v_recipient_id UUID;
  v_auction_title TEXT;
BEGIN
  -- Skip system messages
  IF NEW.message_type = 'system' THEN
    RETURN NEW;
  END IF;

  -- Get transaction details
  SELECT t.buyer_id, t.seller_id, t.auction_id
  INTO v_transaction
  FROM public.auction_transactions t
  WHERE t.id = NEW.transaction_id;

  -- Determine the recipient (the other party)
  IF NEW.sender_id = v_transaction.buyer_id THEN
    v_recipient_id := v_transaction.seller_id;
  ELSIF NEW.sender_id = v_transaction.seller_id THEN
    v_recipient_id := v_transaction.buyer_id;
  ELSE
    -- Unknown sender, skip
    RETURN NEW;
  END IF;

  -- Get auction title
  SELECT a.title INTO v_auction_title
  FROM public.auctions a
  WHERE a.id = v_transaction.auction_id;

  PERFORM public.create_notification(
    v_recipient_id,
    'chat_message',
    format('New message from %s', NEW.sender_name),
    format('%s: "%s"',
      NEW.sender_name,
      LEFT(NEW.message, 80) || CASE WHEN LENGTH(NEW.message) > 80 THEN '...' ELSE '' END),
    'transaction',
    NEW.transaction_id,
    jsonb_build_object(
      'transaction_id', NEW.transaction_id,
      'auction_id', v_transaction.auction_id,
      'message_id', NEW.id,
      'sender_id', NEW.sender_id
    ),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_chat_message ON public.transaction_chat_messages;
CREATE TRIGGER trg_notify_chat_message
  AFTER INSERT ON public.transaction_chat_messages
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_chat_message();

-- ---------------------------------------------------------------------------
-- 7D. Review Received: Notify the reviewed user
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_review_received()
RETURNS TRIGGER AS $$
DECLARE
  v_reviewer_name TEXT;
  v_auction_title TEXT;
  v_auction_id UUID;
BEGIN
  -- Get reviewer name
  SELECT COALESCE(u.display_name, u.full_name, 'A user') INTO v_reviewer_name
  FROM public.users u
  WHERE u.id = NEW.reviewer_id;

  -- Get auction title via transaction
  SELECT t.auction_id INTO v_auction_id
  FROM public.auction_transactions t
  WHERE t.id = NEW.transaction_id;

  SELECT a.title INTO v_auction_title
  FROM public.auctions a
  WHERE a.id = v_auction_id;

  PERFORM public.create_notification(
    NEW.reviewee_id,
    'review_received',
    'You received a review!',
    format('%s left you a %s-star review for the transaction on "%s".',
      v_reviewer_name, NEW.rating, COALESCE(v_auction_title, 'an auction')),
    'transaction',
    NEW.transaction_id,
    jsonb_build_object(
      'transaction_id', NEW.transaction_id,
      'review_id', NEW.id,
      'rating', NEW.rating,
      'reviewer_id', NEW.reviewer_id,
      'auction_id', v_auction_id
    ),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_review_received ON public.transaction_reviews;
CREATE TRIGGER trg_notify_review_received
  AFTER INSERT ON public.transaction_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_review_received();

-- ---------------------------------------------------------------------------
-- 7E. Timeline Activity: Notify both parties on critical timeline events
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.trigger_notify_timeline_activity()
RETURNS TRIGGER AS $$
DECLARE
  v_transaction RECORD;
  v_auction_title TEXT;
  v_notify_buyer BOOLEAN := FALSE;
  v_notify_seller BOOLEAN := FALSE;
BEGIN
  -- Only notify on critical event types (not every minor log)
  IF NEW.event_type NOT IN (
    'form_submitted', 'form_confirmed', 'admin_approved',
    'delivery_started', 'deliveryStarted',
    'delivery_completed', 'deliveryCompleted',
    'completed', 'cancelled', 'disputed', 'deposit_refunded'
  ) THEN
    RETURN NEW;
  END IF;

  -- Get transaction details
  SELECT t.buyer_id, t.seller_id, t.auction_id
  INTO v_transaction
  FROM public.auction_transactions t
  WHERE t.id = NEW.transaction_id;

  -- Get auction title
  SELECT a.title INTO v_auction_title
  FROM public.auctions a
  WHERE a.id = v_transaction.auction_id;

  -- Determine who to notify based on event type and actor
  -- Don't notify the actor about their own actions
  IF NEW.actor_id IS NOT NULL THEN
    v_notify_buyer := (NEW.actor_id <> v_transaction.buyer_id);
    v_notify_seller := (NEW.actor_id <> v_transaction.seller_id);
  ELSE
    -- System events notify both
    v_notify_buyer := TRUE;
    v_notify_seller := TRUE;
  END IF;

  IF v_notify_buyer THEN
    PERFORM public.create_notification(
      v_transaction.buyer_id,
      'activity_log',
      COALESCE(NEW.title, 'Transaction update'),
      format('Transaction for "%s": %s',
        v_auction_title,
        COALESCE(NEW.description, NEW.title)),
      'transaction',
      NEW.transaction_id,
      jsonb_build_object(
        'transaction_id', NEW.transaction_id,
        'event_type', NEW.event_type,
        'timeline_id', NEW.id,
        'auction_id', v_transaction.auction_id
      ),
      CASE
        WHEN NEW.event_type IN ('completed', 'cancelled', 'disputed') THEN 'high'
        ELSE 'normal'
      END
    );
  END IF;

  IF v_notify_seller THEN
    PERFORM public.create_notification(
      v_transaction.seller_id,
      'activity_log',
      COALESCE(NEW.title, 'Transaction update'),
      format('Transaction for "%s": %s',
        v_auction_title,
        COALESCE(NEW.description, NEW.title)),
      'transaction',
      NEW.transaction_id,
      jsonb_build_object(
        'transaction_id', NEW.transaction_id,
        'event_type', NEW.event_type,
        'timeline_id', NEW.id,
        'auction_id', v_transaction.auction_id
      ),
      CASE
        WHEN NEW.event_type IN ('completed', 'cancelled', 'disputed') THEN 'high'
        ELSE 'normal'
      END
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_timeline_activity ON public.transaction_timeline;
CREATE TRIGGER trg_notify_timeline_activity
  AFTER INSERT ON public.transaction_timeline
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_timeline_activity();

-- ============================================================================
-- STEP 8: Add delete policy for notifications (missing from original schema)
-- ============================================================================

DROP POLICY IF EXISTS "user delete own notifications" ON public.notifications;
CREATE POLICY "user delete own notifications" ON public.notifications
  FOR DELETE USING (user_id = auth.uid());

-- ============================================================================
-- STEP 9: Add related_entity columns to notifications table for direct access
-- These are also stored in data JSONB but having columns enables SQL filtering
-- ============================================================================

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'related_entity_type'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN related_entity_type TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'related_entity_id'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN related_entity_id UUID;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'priority'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN priority TEXT NOT NULL DEFAULT 'normal'
      CHECK (priority IN ('low', 'normal', 'high', 'urgent'));
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'metadata'
  ) THEN
    ALTER TABLE public.notifications ADD COLUMN metadata JSONB;
  END IF;
END $$;

-- Update create_notification to also populate the direct columns
CREATE OR REPLACE FUNCTION public.create_notification(
  p_user_id UUID,
  p_type_name TEXT,
  p_title TEXT,
  p_message TEXT,
  p_related_entity_type TEXT DEFAULT NULL,
  p_related_entity_id UUID DEFAULT NULL,
  p_data JSONB DEFAULT '{}'::JSONB,
  p_priority TEXT DEFAULT 'normal'
) RETURNS UUID AS $$
DECLARE
  v_type_id UUID;
  v_notification_id UUID;
BEGIN
  IF p_user_id IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT id INTO v_type_id FROM public.notification_types WHERE type_name = p_type_name;

  IF v_type_id IS NULL THEN
    SELECT id INTO v_type_id FROM public.notification_types WHERE type_name = 'message_received';
    IF v_type_id IS NULL THEN
      RAISE WARNING 'Notification type "%" not found, skipping', p_type_name;
      RETURN NULL;
    END IF;
  END IF;

  INSERT INTO public.notifications (
    user_id, type_id, title, message, data, is_read,
    related_entity_type, related_entity_id, priority, metadata,
    created_at
  ) VALUES (
    p_user_id, v_type_id, p_title, p_message,
    p_data || jsonb_build_object(
      'related_entity_type', p_related_entity_type,
      'related_entity_id', p_related_entity_id,
      'priority', p_priority,
      'notification_type', p_type_name
    ),
    FALSE,
    p_related_entity_type, p_related_entity_id, p_priority,
    p_data,
    NOW()
  ) RETURNING id INTO v_notification_id;

  RETURN v_notification_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Index for fast lookups by related entity
CREATE INDEX IF NOT EXISTS idx_notifications_related_entity
  ON public.notifications (related_entity_type, related_entity_id);

CREATE INDEX IF NOT EXISTS idx_notifications_priority
  ON public.notifications (priority);

CREATE INDEX IF NOT EXISTS idx_notifications_created_at
  ON public.notifications (created_at DESC);

-- ============================================================================
-- Done: All triggers are now in place
-- ============================================================================
