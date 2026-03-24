-- ============================================================================
-- Migration 00159: Fix auto_reselect_next_winner + Standby Queue System
-- ============================================================================
-- 1. Fix auto_reselect: create NEW transaction (delete old), fix table refs,
--    exclude ALL previously penalized buyers
-- 2. Standby queue: auction_standby table, opt-in RPC, select-from-standby RPC
-- 3. Notifications for standby lifecycle
-- ============================================================================

-- ============================================================================
-- PART 1: Fix auto_reselect_next_winner
-- ============================================================================

-- Must drop first: return type changed from BOOLEAN to UUID
DROP FUNCTION IF EXISTS public.auto_reselect_next_winner(UUID);

CREATE OR REPLACE FUNCTION public.auto_reselect_next_winner(
  p_transaction_id UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_seller_id       UUID;
  v_current_buyer   UUID;
  v_next_bidder     UUID;
  v_next_amount     NUMERIC;
  v_next_name       TEXT;
  v_in_txn_status   UUID;
  v_notif_type      UUID;
  v_auction_title   TEXT;
  v_new_txn_id      UUID;
BEGIN
  -- Get transaction details
  SELECT at.auction_id, at.seller_id, at.buyer_id
    INTO v_auction_id, v_seller_id, v_current_buyer
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Find next eligible winner:
  -- Exclude ALL users who have been penalized for this auction (not just current buyer)
  -- Also exclude lost/refunded bid statuses
  -- Group by bidder to get unique users, pick highest bid per user
  SELECT sub.bidder_id, sub.bid_amount, sub.bidder_name
    INTO v_next_bidder, v_next_amount, v_next_name
    FROM (
      SELECT b.bidder_id,
             MAX(b.bid_amount) AS bid_amount,
             MAX(COALESCE(u.full_name, u.display_name, 'Unknown')) AS bidder_name
        FROM public.bids b
        LEFT JOIN public.bid_statuses bs ON b.status_id = bs.id
        LEFT JOIN public.users u ON b.bidder_id = u.id
       WHERE b.auction_id = v_auction_id
         AND b.bidder_id NOT IN (
           SELECT cp.user_id FROM public.cancellation_penalties cp
            WHERE cp.auction_id = v_auction_id
         )
         AND (bs.status_name IS NULL OR bs.status_name NOT IN ('lost', 'refunded'))
       GROUP BY b.bidder_id
    ) sub
   ORDER BY sub.bid_amount DESC
   LIMIT 1;

  IF v_next_bidder IS NULL THEN
    RETURN NULL;
  END IF;

  -- Mark previous buyer's bids as lost
  UPDATE public.bids
     SET status_id = (SELECT id FROM public.bid_statuses WHERE status_name = 'lost' LIMIT 1),
         updated_at = now()
   WHERE auction_id = v_auction_id
     AND bidder_id = v_current_buyer;

  -- Delete old transaction (CASCADE removes chat_messages, timeline, forms, agreement_fields)
  DELETE FROM public.auction_transactions WHERE id = p_transaction_id;

  -- Create NEW transaction
  v_new_txn_id := gen_random_uuid();
  INSERT INTO public.auction_transactions (
    id, auction_id, seller_id, buyer_id, agreed_price, status, created_at, updated_at
  ) VALUES (
    v_new_txn_id, v_auction_id, v_seller_id, v_next_bidder, v_next_amount,
    'in_transaction', now(), now()
  );

  -- Update auction price and status to in_transaction
  SELECT id INTO v_in_txn_status
    FROM public.auction_statuses
   WHERE status_name = 'in_transaction'
   LIMIT 1;

  IF v_in_txn_status IS NOT NULL THEN
    UPDATE public.auctions
       SET current_price = v_next_amount,
           status_id = v_in_txn_status,
           updated_at = now()
     WHERE id = v_auction_id;
  END IF;

  -- Add timeline event on new transaction
  INSERT INTO public.transaction_timeline (
    transaction_id, event_type, title, description, actor_id
  ) VALUES (
    v_new_txn_id,
    'created',
    'Transaction Started',
    format('Auto-reselected next highest bidder: %s at ₱%s', v_next_name, v_next_amount::text),
    auth.uid()
  );

  -- Notify new buyer
  SELECT title INTO v_auction_title FROM public.auctions WHERE id = v_auction_id;
  SELECT id INTO v_notif_type FROM public.notification_types WHERE type_name = 'auction_won' LIMIT 1;

  INSERT INTO public.notifications (user_id, type_id, title, message, data, is_read)
  VALUES (
    v_next_bidder,
    v_notif_type,
    'You Won! 🎉',
    format('You are the new winner for "%s" at ₱%s. Open the transaction to begin.', v_auction_title, v_next_amount::text),
    jsonb_build_object('auction_id', v_auction_id, 'transaction_id', v_new_txn_id, 'action', 'open_transaction'),
    false
  );

  RETURN v_new_txn_id;
END;
$$;

-- ============================================================================
-- PART 2: Standby Queue Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.auction_standby (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auction_id  UUID NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id),
  bid_amount  NUMERIC NOT NULL,
  status      TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'selected', 'released')),
  note        TEXT,
  created_at  TIMESTAMPTZ DEFAULT now(),
  updated_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(auction_id, user_id)
);

ALTER TABLE public.auction_standby ENABLE ROW LEVEL SECURITY;

CREATE POLICY standby_select_own ON public.auction_standby
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY standby_select_seller ON public.auction_standby
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.auctions a WHERE a.id = auction_id AND a.seller_id = auth.uid())
  );

CREATE POLICY standby_insert_own ON public.auction_standby
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY standby_admin_select ON public.auction_standby
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

CREATE INDEX idx_auction_standby_auction ON public.auction_standby(auction_id);
CREATE INDEX idx_auction_standby_user ON public.auction_standby(user_id);

-- ============================================================================
-- PART 3: Opt-in to standby queue
-- ============================================================================

CREATE OR REPLACE FUNCTION public.join_standby_queue(
  p_auction_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_user_id    UUID;
  v_bid_amount NUMERIC;
  v_auction_ended BOOLEAN;
BEGIN
  v_user_id := auth.uid();

  -- Verify auction has ended
  SELECT EXISTS(
    SELECT 1 FROM public.auctions a
    JOIN public.auction_statuses sts ON a.status_id = sts.id
    WHERE a.id = p_auction_id
      AND sts.status_name IN ('ended', 'in_transaction', 'cancelled', 'deal_failed')
  ) INTO v_auction_ended;

  IF NOT v_auction_ended THEN
    RETURN FALSE;
  END IF;

  -- Get user's highest bid for this auction
  SELECT MAX(b.bid_amount) INTO v_bid_amount
    FROM public.bids b
   WHERE b.auction_id = p_auction_id
     AND b.bidder_id = v_user_id;

  IF v_bid_amount IS NULL THEN
    RETURN FALSE; -- user never bid on this auction
  END IF;

  -- Insert into standby (ignore if already there)
  INSERT INTO public.auction_standby (auction_id, user_id, bid_amount, status)
  VALUES (p_auction_id, v_user_id, v_bid_amount, 'waiting')
  ON CONFLICT (auction_id, user_id) DO NOTHING;

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- PART 4: Select from standby queue (seller picks next winner from standby)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.select_from_standby(
  p_transaction_id UUID,
  p_standby_user_id UUID
)
RETURNS UUID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id    UUID;
  v_seller_id     UUID;
  v_current_buyer UUID;
  v_bid_amount    NUMERIC;
  v_user_name     TEXT;
  v_in_txn_status UUID;
  v_notif_type    UUID;
  v_auction_title TEXT;
  v_new_txn_id    UUID;
BEGIN
  -- Get transaction details
  SELECT at.auction_id, at.seller_id, at.buyer_id
    INTO v_auction_id, v_seller_id, v_current_buyer
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RETURN NULL;
  END IF;

  -- Verify caller is the seller
  IF auth.uid() != v_seller_id THEN
    RAISE EXCEPTION 'Only the seller can select from standby';
  END IF;

  -- Verify standby user is in waiting status
  SELECT asb.bid_amount INTO v_bid_amount
    FROM public.auction_standby asb
   WHERE asb.auction_id = v_auction_id
     AND asb.user_id = p_standby_user_id
     AND asb.status = 'waiting';

  IF v_bid_amount IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT COALESCE(u.full_name, u.display_name, 'Unknown') INTO v_user_name
    FROM public.users u WHERE u.id = p_standby_user_id;

  -- Mark previous buyer's bids as lost
  UPDATE public.bids
     SET status_id = (SELECT id FROM public.bid_statuses WHERE status_name = 'lost' LIMIT 1),
         updated_at = now()
   WHERE auction_id = v_auction_id
     AND bidder_id = v_current_buyer;

  -- Mark standby user as selected
  UPDATE public.auction_standby
     SET status = 'selected', updated_at = now()
   WHERE auction_id = v_auction_id AND user_id = p_standby_user_id;

  -- Delete old transaction
  DELETE FROM public.auction_transactions WHERE id = p_transaction_id;

  -- Create NEW transaction
  v_new_txn_id := gen_random_uuid();
  INSERT INTO public.auction_transactions (
    id, auction_id, seller_id, buyer_id, agreed_price, status, created_at, updated_at
  ) VALUES (
    v_new_txn_id, v_auction_id, v_seller_id, p_standby_user_id, v_bid_amount,
    'in_transaction', now(), now()
  );

  -- Update auction
  SELECT id INTO v_in_txn_status
    FROM public.auction_statuses WHERE status_name = 'in_transaction' LIMIT 1;

  IF v_in_txn_status IS NOT NULL THEN
    UPDATE public.auctions
       SET current_price = v_bid_amount,
           status_id = v_in_txn_status,
           updated_at = now()
     WHERE id = v_auction_id;
  END IF;

  -- Timeline
  INSERT INTO public.transaction_timeline (
    transaction_id, event_type, title, description, actor_id
  ) VALUES (
    v_new_txn_id, 'created', 'Transaction Started',
    format('Selected from standby queue: %s at ₱%s', v_user_name, v_bid_amount::text),
    auth.uid()
  );

  -- Notify selected standby user
  SELECT title INTO v_auction_title FROM public.auctions WHERE id = v_auction_id;
  SELECT id INTO v_notif_type FROM public.notification_types WHERE type_name = 'auction_won' LIMIT 1;

  INSERT INTO public.notifications (user_id, type_id, title, message, data, is_read)
  VALUES (
    p_standby_user_id, v_notif_type,
    'You Won from Standby! 🎉',
    format('The seller selected you for "%s" at ₱%s. Open the transaction to begin.', v_auction_title, v_bid_amount::text),
    jsonb_build_object('auction_id', v_auction_id, 'transaction_id', v_new_txn_id, 'action', 'open_transaction'),
    false
  );

  RETURN v_new_txn_id;
END;
$$;

-- ============================================================================
-- PART 5: Release standby users when transaction succeeds or auction deleted
-- Called after transaction completes (sold) or auction is removed
-- ============================================================================

CREATE OR REPLACE FUNCTION public.release_standby_on_sold()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_notif_type UUID;
  v_auction_title TEXT;
  r RECORD;
BEGIN
  -- Only fire when status changes to 'sold'
  IF NEW.status = 'sold' AND OLD.status != 'sold' THEN
    SELECT title INTO v_auction_title FROM public.auctions WHERE id = NEW.auction_id;
    SELECT id INTO v_notif_type FROM public.notification_types WHERE type_name = 'auction_lost' LIMIT 1;

    -- Notify all waiting standby users and release them
    FOR r IN
      SELECT user_id FROM public.auction_standby
       WHERE auction_id = NEW.auction_id AND status = 'waiting'
    LOOP
      INSERT INTO public.notifications (user_id, type_id, title, message, data, is_read)
      VALUES (
        r.user_id, v_notif_type,
        'Auction Completed',
        format('The auction "%s" has been completed successfully. Thank you for your interest!', v_auction_title),
        jsonb_build_object('auction_id', NEW.auction_id),
        false
      );
    END LOOP;

    UPDATE public.auction_standby
       SET status = 'released', note = 'Transaction completed successfully', updated_at = now()
     WHERE auction_id = NEW.auction_id AND status = 'waiting';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_release_standby_on_sold ON public.auction_transactions;
CREATE TRIGGER trg_release_standby_on_sold
  AFTER UPDATE ON public.auction_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.release_standby_on_sold();
