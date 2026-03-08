-- ============================================================================
-- Migration 00123: Transaction Sub-Tab Notifications + Report System
-- ============================================================================
-- 1. Add notification types for agreement, installment, delivery updates
-- 2. Create triggers for those events
-- 3. Create transaction_reports table
-- ============================================================================

-- ============================================================================
-- STEP 1: Add new notification types
-- ============================================================================

ALTER TABLE public.notification_types DROP CONSTRAINT IF EXISTS notification_types_type_name_check;

INSERT INTO public.notification_types (type_name, display_name) VALUES
  ('agreement_update', 'Agreement Update'),
  ('installment_update', 'Installment Update'),
  ('delivery_update', 'Delivery Update'),
  ('payment_method_update', 'Payment Method Update')
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
    'agreement_update', 'installment_update', 'delivery_update',
    'payment_method_update'
  ));

-- ============================================================================
-- STEP 2: Agreement field change trigger
-- Notifies the OTHER party when a field is added, updated, or deleted
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_notify_agreement_field_change()
RETURNS TRIGGER AS $$
DECLARE
  v_transaction RECORD;
  v_auction_title TEXT;
  v_actor_id UUID;
  v_recipient_id UUID;
  v_action TEXT;
  v_field_label TEXT;
BEGIN
  -- Determine the relevant record and action
  IF TG_OP = 'DELETE' THEN
    v_actor_id := OLD.added_by;
    v_field_label := OLD.label;
    v_action := 'removed';
    SELECT t.buyer_id, t.seller_id, t.auction_id
    INTO v_transaction
    FROM public.auction_transactions t
    WHERE t.id = OLD.transaction_id;
  ELSIF TG_OP = 'INSERT' THEN
    v_actor_id := NEW.added_by;
    v_field_label := NEW.label;
    v_action := 'added';
    SELECT t.buyer_id, t.seller_id, t.auction_id
    INTO v_transaction
    FROM public.auction_transactions t
    WHERE t.id = NEW.transaction_id;
  ELSE
    v_actor_id := COALESCE(NEW.last_edited_by, NEW.added_by);
    v_field_label := NEW.label;
    v_action := 'updated';
    SELECT t.buyer_id, t.seller_id, t.auction_id
    INTO v_transaction
    FROM public.auction_transactions t
    WHERE t.id = NEW.transaction_id;
  END IF;

  IF v_transaction IS NULL OR v_actor_id IS NULL THEN
    RETURN COALESCE(NEW, OLD);
  END IF;

  -- Determine recipient (the other party)
  IF v_actor_id = v_transaction.buyer_id THEN
    v_recipient_id := v_transaction.seller_id;
  ELSIF v_actor_id = v_transaction.seller_id THEN
    v_recipient_id := v_transaction.buyer_id;
  ELSE
    RETURN COALESCE(NEW, OLD);
  END IF;

  SELECT a.title INTO v_auction_title
  FROM public.auctions a WHERE a.id = v_transaction.auction_id;

  PERFORM public.create_notification(
    v_recipient_id,
    'agreement_update',
    'Agreement updated',
    format('A field "%s" was %s in the agreement for "%s".',
      v_field_label, v_action, COALESCE(v_auction_title, 'a transaction')),
    'transaction',
    COALESCE(NEW.transaction_id, OLD.transaction_id),
    jsonb_build_object(
      'transaction_id', COALESCE(NEW.transaction_id, OLD.transaction_id),
      'auction_id', v_transaction.auction_id,
      'field_label', v_field_label,
      'action', v_action,
      'tab', 'agreement'
    ),
    'normal'
  );

  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_agreement_field_change ON public.transaction_agreement_fields;
CREATE TRIGGER trg_notify_agreement_field_change
  AFTER INSERT OR UPDATE OR DELETE ON public.transaction_agreement_fields
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_agreement_field_change();

-- ============================================================================
-- STEP 3: Agreement lock/unlock/confirm trigger
-- Fires when seller/buyer lock, unlock, or confirm the agreement
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_notify_agreement_status_change()
RETURNS TRIGGER AS $$
DECLARE
  v_auction_title TEXT;
  v_actor_label TEXT;
  v_recipient_id UUID;
  v_msg TEXT;
  v_title TEXT;
BEGIN
  SELECT a.title INTO v_auction_title
  FROM public.auctions a WHERE a.id = NEW.auction_id;

  -- Seller locked
  IF NEW.seller_form_submitted = TRUE AND OLD.seller_form_submitted = FALSE THEN
    PERFORM public.create_notification(
      NEW.buyer_id, 'agreement_update', 'Seller locked agreement',
      format('The seller has locked their agreement for "%s".', COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'normal'
    );
  END IF;

  -- Buyer locked
  IF NEW.buyer_form_submitted = TRUE AND OLD.buyer_form_submitted = FALSE THEN
    PERFORM public.create_notification(
      NEW.seller_id, 'agreement_update', 'Buyer locked agreement',
      format('The buyer has locked their agreement for "%s".', COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'normal'
    );
  END IF;

  -- Seller unlocked
  IF NEW.seller_form_submitted = FALSE AND OLD.seller_form_submitted = TRUE THEN
    PERFORM public.create_notification(
      NEW.buyer_id, 'agreement_update', 'Seller unlocked agreement',
      format('The seller has unlocked the agreement for "%s" for further editing.', COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'normal'
    );
  END IF;

  -- Buyer unlocked
  IF NEW.buyer_form_submitted = FALSE AND OLD.buyer_form_submitted = TRUE THEN
    PERFORM public.create_notification(
      NEW.seller_id, 'agreement_update', 'Buyer unlocked agreement',
      format('The buyer has unlocked the agreement for "%s" for further editing.', COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'normal'
    );
  END IF;

  -- Seller confirmed
  IF NEW.seller_confirmed = TRUE AND OLD.seller_confirmed = FALSE THEN
    PERFORM public.create_notification(
      NEW.buyer_id, 'agreement_update', 'Seller confirmed agreement',
      format('The seller has confirmed the agreement for "%s".', COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'high'
    );
  END IF;

  -- Buyer confirmed
  IF NEW.buyer_confirmed = TRUE AND OLD.buyer_confirmed = FALSE THEN
    PERFORM public.create_notification(
      NEW.seller_id, 'agreement_update', 'Buyer confirmed agreement',
      format('The buyer has confirmed the agreement for "%s".', COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'high'
    );
  END IF;

  -- Payment method changed
  IF NEW.payment_method IS DISTINCT FROM OLD.payment_method THEN
    -- Notify both parties
    PERFORM public.create_notification(
      NEW.buyer_id, 'payment_method_update', 'Payment method changed',
      format('Payment method changed to %s for "%s".',
        COALESCE(NEW.payment_method, 'full payment'), COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'normal'
    );
    PERFORM public.create_notification(
      NEW.seller_id, 'payment_method_update', 'Payment method changed',
      format('Payment method changed to %s for "%s".',
        COALESCE(NEW.payment_method, 'full payment'), COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'agreement'),
      'normal'
    );
  END IF;

  -- Delivery status changed
  IF NEW.delivery_status IS DISTINCT FROM OLD.delivery_status AND NEW.delivery_status IS NOT NULL THEN
    -- Notify buyer about delivery updates
    PERFORM public.create_notification(
      NEW.buyer_id, 'delivery_update', 'Delivery status updated',
      format('Delivery status changed to "%s" for "%s".',
        NEW.delivery_status, COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'progress'),
      'high'
    );
    PERFORM public.create_notification(
      NEW.seller_id, 'delivery_update', 'Delivery status updated',
      format('Delivery status changed to "%s" for "%s".',
        NEW.delivery_status, COALESCE(v_auction_title, 'a transaction')),
      'transaction', NEW.id,
      jsonb_build_object('transaction_id', NEW.id, 'auction_id', NEW.auction_id, 'tab', 'progress'),
      'high'
    );
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_agreement_status_change ON public.auction_transactions;
CREATE TRIGGER trg_notify_agreement_status_change
  AFTER UPDATE ON public.auction_transactions
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_agreement_status_change();

-- ============================================================================
-- STEP 4: Installment plan change trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_notify_installment_change()
RETURNS TRIGGER AS $$
DECLARE
  v_transaction RECORD;
  v_auction_title TEXT;
  v_action TEXT;
BEGIN
  SELECT t.buyer_id, t.seller_id, t.auction_id
  INTO v_transaction
  FROM public.auction_transactions t
  WHERE t.id = NEW.transaction_id;

  IF v_transaction IS NULL THEN RETURN NEW; END IF;

  SELECT a.title INTO v_auction_title
  FROM public.auctions a WHERE a.id = v_transaction.auction_id;

  IF TG_OP = 'INSERT' THEN
    v_action := 'proposed';
  ELSE
    v_action := 'updated';
  END IF;

  -- Notify buyer
  PERFORM public.create_notification(
    v_transaction.buyer_id, 'installment_update',
    format('Installment plan %s', v_action),
    format('An installment plan has been %s for "%s". %s installments of ₱%s.',
      v_action, COALESCE(v_auction_title, 'a transaction'),
      NEW.num_installments,
      ROUND((NEW.total_amount - COALESCE(NEW.down_payment, 0)) / NULLIF(NEW.num_installments, 0))::TEXT),
    'transaction', NEW.transaction_id,
    jsonb_build_object('transaction_id', NEW.transaction_id, 'auction_id', v_transaction.auction_id, 'tab', 'gives'),
    'normal'
  );

  -- Notify seller
  PERFORM public.create_notification(
    v_transaction.seller_id, 'installment_update',
    format('Installment plan %s', v_action),
    format('An installment plan has been %s for "%s". %s installments of ₱%s.',
      v_action, COALESCE(v_auction_title, 'a transaction'),
      NEW.num_installments,
      ROUND((NEW.total_amount - COALESCE(NEW.down_payment, 0)) / NULLIF(NEW.num_installments, 0))::TEXT),
    'transaction', NEW.transaction_id,
    jsonb_build_object('transaction_id', NEW.transaction_id, 'auction_id', v_transaction.auction_id, 'tab', 'gives'),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_installment_change ON public.installment_plans;
CREATE TRIGGER trg_notify_installment_change
  AFTER INSERT OR UPDATE ON public.installment_plans
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_installment_change();

-- ============================================================================
-- STEP 5: Installment payment trigger
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trigger_notify_installment_payment()
RETURNS TRIGGER AS $$
DECLARE
  v_plan RECORD;
  v_transaction RECORD;
  v_auction_title TEXT;
BEGIN
  SELECT p.transaction_id INTO v_plan
  FROM public.installment_plans p WHERE p.id = NEW.plan_id;

  IF v_plan IS NULL THEN RETURN NEW; END IF;

  SELECT t.buyer_id, t.seller_id, t.auction_id
  INTO v_transaction
  FROM public.auction_transactions t
  WHERE t.id = v_plan.transaction_id;

  IF v_transaction IS NULL THEN RETURN NEW; END IF;

  SELECT a.title INTO v_auction_title
  FROM public.auctions a WHERE a.id = v_transaction.auction_id;

  -- Notify both about payment logged
  PERFORM public.create_notification(
    v_transaction.buyer_id, 'installment_update', 'Payment logged',
    format('A payment of ₱%s has been logged for "%s".',
      ROUND(NEW.amount)::TEXT, COALESCE(v_auction_title, 'a transaction')),
    'transaction', v_plan.transaction_id,
    jsonb_build_object('transaction_id', v_plan.transaction_id, 'auction_id', v_transaction.auction_id, 'tab', 'gives'),
    'normal'
  );

  PERFORM public.create_notification(
    v_transaction.seller_id, 'installment_update', 'Payment logged',
    format('A payment of ₱%s has been logged for "%s".',
      ROUND(NEW.amount)::TEXT, COALESCE(v_auction_title, 'a transaction')),
    'transaction', v_plan.transaction_id,
    jsonb_build_object('transaction_id', v_plan.transaction_id, 'auction_id', v_transaction.auction_id, 'tab', 'gives'),
    'normal'
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_notify_installment_payment ON public.installment_payments;
CREATE TRIGGER trg_notify_installment_payment
  AFTER INSERT ON public.installment_payments
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_notify_installment_payment();

-- ============================================================================
-- STEP 6: Transaction Reports table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.transaction_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES public.auction_transactions(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES auth.users(id),
  reported_user_id UUID NOT NULL REFERENCES auth.users(id),
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'reviewing', 'resolved', 'dismissed')),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

ALTER TABLE public.transaction_reports ENABLE ROW LEVEL SECURITY;

-- Users can view their own reports
CREATE POLICY "Users view own reports" ON public.transaction_reports
  FOR SELECT USING (reporter_id = auth.uid());

-- Users can insert reports
CREATE POLICY "Users create reports" ON public.transaction_reports
  FOR INSERT WITH CHECK (reporter_id = auth.uid());

-- Index for admin queries
CREATE INDEX IF NOT EXISTS idx_transaction_reports_status ON public.transaction_reports(status);
CREATE INDEX IF NOT EXISTS idx_transaction_reports_transaction ON public.transaction_reports(transaction_id);
