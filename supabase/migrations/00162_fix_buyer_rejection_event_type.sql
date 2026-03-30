-- ============================================================================
-- Migration 00162: Fix buyer rejection failing due to CHECK constraint
-- The handle_buyer_acceptance RPC inserts 'deal_failed' as event_type into
-- transaction_timeline, but 'deal_failed' was not in the CHECK constraint.
-- This caused the entire RPC to fail silently on rejection.
-- ============================================================================

-- Update the event_type CHECK constraint to include 'deal_failed'
ALTER TABLE transaction_timeline DROP CONSTRAINT IF EXISTS transaction_timeline_event_type_check;

ALTER TABLE transaction_timeline ADD CONSTRAINT transaction_timeline_event_type_check
  CHECK (event_type IN (
    'created',
    'message_sent',
    'form_submitted',
    'form_reviewed',
    'form_confirmed',
    'admin_review',
    'admin_submitted',
    'admin_approved',
    'delivery_started',
    'deliveryStarted',
    'delivery_completed',
    'deliveryCompleted',
    'completed',
    'cancelled',
    'disputed',
    'deposit_refunded',
    'transaction_started',
    'deal_failed'
  ));
