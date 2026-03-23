-- Automatic Reselection / Restart / Cancel with Penalty
-- Provides server-side functions for:
--   1. Auto-reselecting the next highest bidder when a deal fails
--   2. Restarting auction bidding from scratch
--   3. Cancelling an auction with a penalty deducted from the cancelling party's wallet

-- ============================================================================
-- Penalty ledger for cancellations
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.cancellation_penalties (
  id              UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  transaction_id  UUID NOT NULL REFERENCES public.auction_transactions(id) ON DELETE CASCADE,
  auction_id      UUID NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES auth.users(id),
  role            TEXT NOT NULL CHECK (role IN ('buyer', 'seller')),
  penalty_amount  NUMERIC NOT NULL DEFAULT 0,
  reason          TEXT,
  created_at      TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE public.cancellation_penalties ENABLE ROW LEVEL SECURITY;

CREATE POLICY cancellation_penalties_select ON public.cancellation_penalties
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY cancellation_penalties_admin_select ON public.cancellation_penalties
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.admin_users au WHERE au.user_id = auth.uid())
  );

-- ============================================================================
-- Cancel auction with penalty
-- ============================================================================
CREATE OR REPLACE FUNCTION public.cancel_auction_with_penalty(
  p_transaction_id UUID,
  p_reason         TEXT DEFAULT ''
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_buyer_id        UUID;
  v_seller_id       UUID;
  v_agreed_price    NUMERIC;
  v_penalty_amount  NUMERIC;
  v_current_user    UUID;
  v_role            TEXT;
  v_cancelled_id    UUID;
BEGIN
  v_current_user := auth.uid();

  SELECT at.auction_id, at.buyer_id, at.seller_id, at.agreed_price
    INTO v_auction_id, v_buyer_id, v_seller_id, v_agreed_price
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Determine who is cancelling
  IF v_current_user = v_buyer_id THEN
    v_role := 'buyer';
  ELSIF v_current_user = v_seller_id THEN
    v_role := 'seller';
  ELSE
    RAISE EXCEPTION 'Only buyer or seller can cancel';
  END IF;

  -- Calculate penalty: 5% of agreed price (configurable)
  v_penalty_amount := ROUND(v_agreed_price * 0.05, 2);

  -- Record penalty
  INSERT INTO public.cancellation_penalties (
    transaction_id, auction_id, user_id, role, penalty_amount, reason
  ) VALUES (
    p_transaction_id, v_auction_id, v_current_user, v_role, v_penalty_amount, p_reason
  );

  -- Update transaction to deal_failed
  UPDATE public.auction_transactions
     SET status = 'deal_failed',
         updated_at = now()
   WHERE id = p_transaction_id;

  -- Set rejection reason
  IF v_role = 'buyer' THEN
    UPDATE public.auction_transactions
       SET buyer_rejection_reason = p_reason,
           buyer_acceptance_status = 'rejected'
     WHERE id = p_transaction_id;
  ELSE
    UPDATE public.auction_transactions
       SET seller_rejection_reason = p_reason
     WHERE id = p_transaction_id;
  END IF;

  -- Update auction status to cancelled
  SELECT id INTO v_cancelled_id
    FROM public.auction_statuses
   WHERE status_name = 'cancelled'
   LIMIT 1;

  IF v_cancelled_id IS NOT NULL THEN
    UPDATE public.auctions
       SET status_id = v_cancelled_id,
           updated_at = now()
     WHERE id = v_auction_id;
  END IF;

  -- Add timeline event
  INSERT INTO public.transaction_timeline (
    transaction_id, event_type, title, description, actor_id
  ) VALUES (
    p_transaction_id,
    'cancelled',
    'Auction Cancelled with Penalty',
    format('%s cancelled the deal. Penalty: ₱%s. Reason: %s',
           initcap(v_role), v_penalty_amount::text, COALESCE(NULLIF(p_reason, ''), 'No reason provided')),
    v_current_user
  );
END;
$$;

-- ============================================================================
-- Auto-reselect next winner
-- Atomically picks the next eligible bidder and reassigns the transaction
-- ============================================================================
CREATE OR REPLACE FUNCTION public.auto_reselect_next_winner(
  p_transaction_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_current_buyer   UUID;
  v_txn_id          UUID;
  v_next_bidder     UUID;
  v_next_amount     NUMERIC;
  v_next_name       TEXT;
  v_in_txn_status   UUID;
  v_notif_type      UUID;
  v_auction_title   TEXT;
BEGIN
  -- Get transaction details
  SELECT at.id, at.auction_id, at.buyer_id
    INTO v_txn_id, v_auction_id, v_current_buyer
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RETURN FALSE;
  END IF;

  -- Find next eligible winner (excluding current buyer, lost, refunded)
  SELECT b.bidder_id, b.bid_amount, COALESCE(u.full_name, u.display_name, 'Unknown')
    INTO v_next_bidder, v_next_amount, v_next_name
    FROM public.bids b
    LEFT JOIN public.bid_statuses bs ON b.status_id = bs.id
    LEFT JOIN public.users u ON b.bidder_id = u.id
   WHERE b.auction_id = v_auction_id
     AND b.bidder_id != v_current_buyer
     AND (bs.status_name IS NULL OR bs.status_name NOT IN ('lost', 'refunded'))
   ORDER BY b.bid_amount DESC
   LIMIT 1;

  IF v_next_bidder IS NULL THEN
    RETURN FALSE; -- no eligible next winner
  END IF;

  -- Mark previous buyer's bids as lost
  UPDATE public.bids
     SET status_id = (SELECT id FROM public.bid_statuses WHERE status_name = 'lost' LIMIT 1),
         updated_at = now()
   WHERE auction_id = v_auction_id
     AND bidder_id = v_current_buyer;

  -- Reset and reassign the transaction to the new buyer
  UPDATE public.auction_transactions
     SET buyer_id = v_next_bidder,
         agreed_price = v_next_amount,
         status = 'in_transaction',
         seller_form_submitted = false,
         buyer_form_submitted = false,
         seller_confirmed = false,
         buyer_confirmed = false,
         admin_approved = false,
         admin_approved_at = NULL,
         both_confirmed_at = NULL,
         delivery_status = 'pending',
         delivery_started_at = NULL,
         delivery_completed_at = NULL,
         buyer_acceptance_status = 'pending',
         buyer_accepted_at = NULL,
         buyer_rejection_reason = NULL,
         seller_rejection_reason = NULL,
         completed_at = NULL,
         updated_at = now()
   WHERE id = v_txn_id;

  -- Clear old chat, timeline, forms, agreement fields
  DELETE FROM public.transaction_chat WHERE transaction_id = v_txn_id;
  DELETE FROM public.transaction_timeline WHERE transaction_id = v_txn_id;
  DELETE FROM public.transaction_forms WHERE transaction_id = v_txn_id;
  DELETE FROM public.transaction_agreement_fields WHERE transaction_id = v_txn_id;

  -- Update auction price and status back to in_transaction
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

  -- Add timeline event
  INSERT INTO public.transaction_timeline (
    transaction_id, event_type, title, description, actor_id
  ) VALUES (
    v_txn_id,
    'created',
    'Transaction Started',
    format('Auto-reselected next highest bidder: %s at ₱%s', v_next_name, v_next_amount::text),
    auth.uid()
  );

  -- Notify new buyer
  SELECT title INTO v_auction_title FROM public.auctions WHERE id = v_auction_id;
  SELECT id INTO v_notif_type FROM public.notification_types WHERE type_name = 'outbid' LIMIT 1;

  INSERT INTO public.notifications (user_id, type_id, title, message, data, is_read)
  VALUES (
    v_next_bidder,
    v_notif_type,
    'You Won! 🎉',
    format('You are the new winner for "%s" at ₱%s. Open the transaction to begin.', v_auction_title, v_next_amount::text),
    jsonb_build_object('auction_id', v_auction_id, 'transaction_id', v_txn_id, 'action', 'open_transaction'),
    false
  );

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- Restart auction bidding (fresh round)
-- ============================================================================
CREATE OR REPLACE FUNCTION public.restart_auction_bidding(
  p_transaction_id UUID
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_txn_id          UUID;
  v_pending_status  UUID;
BEGIN
  SELECT at.id, at.auction_id
    INTO v_txn_id, v_auction_id
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Get pending_approval status
  SELECT id INTO v_pending_status
    FROM public.auction_statuses
   WHERE status_name = 'pending_approval'
   LIMIT 1;

  IF v_pending_status IS NULL THEN
    RAISE EXCEPTION 'Pending status not found';
  END IF;

  -- Reset auction to pending_approval, clear price and bids
  UPDATE public.auctions
     SET status_id = v_pending_status,
         current_price = 0,
         total_bids = 0,
         updated_at = now()
   WHERE id = v_auction_id;

  -- Clear all bids and auto-bid data
  DELETE FROM public.bids WHERE auction_id = v_auction_id;
  DELETE FROM public.auto_bid_settings WHERE auction_id = v_auction_id;
  DELETE FROM public.auto_bid_queue WHERE auction_id = v_auction_id;

  -- Clear transaction data
  DELETE FROM public.transaction_chat WHERE transaction_id = v_txn_id;
  DELETE FROM public.transaction_timeline WHERE transaction_id = v_txn_id;
  DELETE FROM public.transaction_forms WHERE transaction_id = v_txn_id;
  DELETE FROM public.transaction_agreement_fields WHERE transaction_id = v_txn_id;

  -- Delete the old transaction so a new one can be created
  DELETE FROM public.auction_transactions WHERE id = v_txn_id;
END;
$$;
