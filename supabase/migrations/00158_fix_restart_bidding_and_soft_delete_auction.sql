-- Migration: Fix restart bidding (wrong table name) + soft delete auction
-- ============================================================================

-- ============================================================================
-- 1. Fix restart_auction_bidding — referenced non-existent table 'transaction_chat'
--    Correct table name is 'transaction_chat_messages'
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

  -- Delete the old transaction (cascades to chat_messages, timeline, forms, agreement_fields)
  DELETE FROM public.auction_transactions WHERE id = v_txn_id;
END;
$$;

-- ============================================================================
-- 2. Add 'deleted' auction status + deleted_at column for soft delete
-- ============================================================================

-- Update CHECK constraint to include 'deleted'
ALTER TABLE auction_statuses
  DROP CONSTRAINT IF EXISTS auction_statuses_status_name_check;

ALTER TABLE auction_statuses
  ADD CONSTRAINT auction_statuses_status_name_check
  CHECK (status_name IN (
    'draft',
    'pending_approval',
    'approved',
    'rejected',
    'scheduled',
    'live',
    'ended',
    'cancelled',
    'in_transaction',
    'sold',
    'deal_failed',
    'deleted'
  ));

INSERT INTO auction_statuses (status_name, display_name)
VALUES ('deleted', 'Deleted')
ON CONFLICT (status_name) DO NOTHING;

-- Add deleted_at timestamp for audit trail
ALTER TABLE public.auctions ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ============================================================================
-- 3. RPC: Soft-delete auction after a failed deal
--    Sets auction status to 'deleted', sets deleted_at, removes transaction
-- ============================================================================
CREATE OR REPLACE FUNCTION public.soft_delete_auction(
  p_transaction_id UUID
)
RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id      UUID;
  v_txn_id          UUID;
  v_deleted_status  UUID;
  v_seller_id       UUID;
  v_current_user    UUID;
BEGIN
  v_current_user := auth.uid();

  -- Get transaction details
  SELECT at.id, at.auction_id, at.seller_id
    INTO v_txn_id, v_auction_id, v_seller_id
    FROM public.auction_transactions at
   WHERE at.id = p_transaction_id;

  IF v_auction_id IS NULL THEN
    RAISE EXCEPTION 'Transaction not found';
  END IF;

  -- Only the seller can delete their auction
  IF v_current_user != v_seller_id THEN
    RAISE EXCEPTION 'Only the seller can delete this auction';
  END IF;

  -- Get 'deleted' status
  SELECT id INTO v_deleted_status
    FROM public.auction_statuses
   WHERE status_name = 'deleted'
   LIMIT 1;

  -- Soft-delete the auction
  UPDATE public.auctions
     SET status_id = COALESCE(v_deleted_status, status_id),
         deleted_at = now(),
         updated_at = now()
   WHERE id = v_auction_id;

  -- Delete the transaction row (cascades to chat, timeline, forms, etc.)
  DELETE FROM public.auction_transactions WHERE id = v_txn_id;
END;
$$;
