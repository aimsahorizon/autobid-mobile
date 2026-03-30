-- Add 'rejected' status to auction_statuses table
-- Used when an admin rejects a listing during review (instead of cancelling)

-- 1. Update CHECK constraint to include 'rejected'
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
    'deal_failed'
  ));

-- 2. Insert the new status row
INSERT INTO auction_statuses (status_name, display_name)
VALUES ('rejected', 'Rejected')
ON CONFLICT (status_name) DO NOTHING;
