-- ============================================================================
-- AutoBid Mobile - Migration 00029: Restructure Auction Statuses
-- Remove 'unsold' status and add 'in_transaction' and 'deal_failed' statuses
-- Support new transaction flow: ended → in_transaction/cancelled → sold/deal_failed
-- ============================================================================

-- ============================================================================
-- STEP 1: Remove 'unsold' status
-- ============================================================================

-- Remove any auctions currently in 'unsold' status (move to 'cancelled')
UPDATE auctions
SET status_id = (SELECT id FROM auction_statuses WHERE status_name = 'cancelled')
WHERE status_id = (SELECT id FROM auction_statuses WHERE status_name = 'unsold');

-- Delete the unsold status
DELETE FROM auction_statuses WHERE status_name = 'unsold';

-- ============================================================================
-- STEP 2: Update CHECK constraint to include new statuses
-- ============================================================================

ALTER TABLE auction_statuses DROP CONSTRAINT IF EXISTS auction_statuses_status_name_check;

ALTER TABLE auction_statuses ADD CONSTRAINT auction_statuses_status_name_check
  CHECK (status_name IN (
    'draft',
    'pending_approval',
    'scheduled',
    'live',
    'ended',
    'cancelled',
    'in_transaction',
    'sold',
    'deal_failed'
  ));

-- ============================================================================
-- STEP 3: Add new statuses
-- ============================================================================

-- Add 'in_transaction' status (replaces ended for active negotiations)
INSERT INTO auction_statuses (status_name, display_name) VALUES
('in_transaction', 'In Transaction')
ON CONFLICT (status_name) DO NOTHING;

-- Add 'deal_failed' status (for post-auction cancellations)
INSERT INTO auction_statuses (status_name, display_name) VALUES
('deal_failed', 'Deal Failed')
ON CONFLICT (status_name) DO NOTHING;

-- ============================================================================
-- EXPLANATION:
-- ============================================================================
-- OLD FLOW:
--   live → ended (with winner) OR unsold (no winner/reserve not met)
--
-- NEW FLOW:
--   live → ended (awaiting seller decision)
--          ↓
--   in_transaction (seller proceeds) OR cancelled (seller cancels)
--          ↓
--   sold (deal completed) OR deal_failed (deal cancelled during transaction)
--
-- CHANGES:
--   - Removed: 'unsold' (use 'cancelled' instead)
--   - Added: 'in_transaction' (active negotiation phase)
--   - Added: 'deal_failed' (cancelled during transaction)
--
-- BENEFITS:
--   - Clearer status flow
--   - Seller has decision point after auction ends
--   - Separation of pre-auction cancels vs post-auction failures
--   - Transactions module can track in_transaction/sold/deal_failed separately
-- ============================================================================

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
