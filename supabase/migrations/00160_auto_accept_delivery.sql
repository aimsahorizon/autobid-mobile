-- ============================================================================
-- Migration 00160: Auto-accept delivery after buyer non-response
-- ============================================================================
-- When seller marks delivery as 'delivered', a 7-day deadline starts.
-- If buyer doesn't respond within 7 days, system auto-accepts on their behalf.
-- Demo mode: 3 minutes instead of 7 days.
-- ============================================================================

-- 1. Add deadline column
ALTER TABLE public.auction_transactions
ADD COLUMN IF NOT EXISTS buyer_acceptance_deadline TIMESTAMPTZ;

-- 2. Set deadline when delivery_status changes to 'delivered'
CREATE OR REPLACE FUNCTION set_buyer_acceptance_deadline()
RETURNS TRIGGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.delivery_status = 'delivered'
     AND (OLD.delivery_status IS DISTINCT FROM 'delivered')
     AND NEW.buyer_acceptance_status = 'pending'
  THEN
    NEW.buyer_acceptance_deadline := NOW() + INTERVAL '7 days';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_set_buyer_acceptance_deadline ON public.auction_transactions;
CREATE TRIGGER trg_set_buyer_acceptance_deadline
  BEFORE UPDATE ON public.auction_transactions
  FOR EACH ROW
  EXECUTE FUNCTION set_buyer_acceptance_deadline();

-- 3. Function to auto-accept expired deliveries (called by cron or RPC)
CREATE OR REPLACE FUNCTION auto_accept_expired_deliveries()
RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count INTEGER := 0;
  v_rec RECORD;
BEGIN
  FOR v_rec IN
    SELECT id, buyer_id
      FROM public.auction_transactions
     WHERE delivery_status = 'delivered'
       AND buyer_acceptance_status = 'pending'
       AND buyer_acceptance_deadline IS NOT NULL
       AND buyer_acceptance_deadline <= NOW()
  LOOP
    -- Update transaction to accepted
    UPDATE public.auction_transactions
       SET buyer_acceptance_status = 'accepted',
           buyer_accepted_at = NOW(),
           delivery_status = 'completed',
           delivery_completed_at = NOW(),
           status = 'sold',
           updated_at = NOW()
     WHERE id = v_rec.id;

    -- Refund deposits
    PERFORM refund_transaction_deposits(v_rec.id);

    -- Timeline event
    INSERT INTO public.transaction_timeline (
      transaction_id, title, description, event_type, actor_name
    ) VALUES (
      v_rec.id,
      'Auto-Accepted',
      'Buyer did not respond within the 7-day acceptance window. Vehicle automatically accepted and deposits refunded.',
      'completed',
      'System'
    );

    -- Notify buyer
    BEGIN
      INSERT INTO public.notifications (user_id, type_id, title, message, data, is_read)
      VALUES (
        v_rec.buyer_id,
        (SELECT id FROM public.notification_types WHERE type_name = 'transaction_update' LIMIT 1),
        'Delivery Auto-Accepted',
        'You did not respond within 7 days. The delivery has been automatically accepted and deposits refunded.',
        jsonb_build_object('transaction_id', v_rec.id, 'action', 'open_transaction'),
        false
      );
    EXCEPTION WHEN OTHERS THEN
      NULL;
    END;

    v_count := v_count + 1;
  END LOOP;

  RETURN v_count;
END;
$$;

-- 4. Demo mode: set deadline to 3 minutes
CREATE OR REPLACE FUNCTION auto_accept_demo_mode(p_transaction_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  UPDATE public.auction_transactions
     SET buyer_acceptance_deadline = NOW() + INTERVAL '3 minutes',
         updated_at = NOW()
   WHERE id = p_transaction_id
     AND delivery_status = 'delivered'
     AND buyer_acceptance_status = 'pending';

  IF NOT FOUND THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$;

-- 5. Grant execute
GRANT EXECUTE ON FUNCTION auto_accept_expired_deliveries() TO service_role;
GRANT EXECUTE ON FUNCTION auto_accept_demo_mode(UUID) TO authenticated;
