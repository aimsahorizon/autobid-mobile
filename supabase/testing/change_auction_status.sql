-- ============================================================================
-- TESTING SCRIPT: Change Auction Statuses
-- ============================================================================
-- This script helps you manually change auction statuses for testing
-- Run these queries in Supabase SQL Editor
-- ============================================================================

-- ============================================================================
-- 1. VIEW CURRENT STATUSES
-- ============================================================================

-- See all available status IDs and names
SELECT id, status_name, display_name
FROM auction_statuses
ORDER BY status_name;

-- See your auctions with their current status
SELECT
  a.id,
  a.title,
  ast.status_name as current_status,
  a.seller_id,
  a.created_at
FROM auctions a
JOIN auction_statuses ast ON a.status_id = ast.id
ORDER BY a.created_at DESC
LIMIT 20;

-- ============================================================================
-- 2. CHANGE STATUS: PENDING_APPROVAL → SCHEDULED (APPROVED)
-- ============================================================================

-- Change a specific auction from pending_approval to scheduled (approved)
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'scheduled'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- Change ALL your pending auctions to scheduled (use your seller_id)
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'scheduled'),
  updated_at = NOW()
WHERE
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'pending_approval')
  AND seller_id = auth.uid();  -- Only your auctions

-- ============================================================================
-- 3. CHANGE STATUS: SCHEDULED → LIVE (ACTIVE)
-- ============================================================================

-- Change to live status
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- ============================================================================
-- 4. CHANGE STATUS: LIVE → ENDED
-- ============================================================================

-- Change to ended status (auction finished, awaiting seller decision)
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'ended'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- ============================================================================
-- 5. CHANGE STATUS: ENDED → IN_TRANSACTION
-- ============================================================================

-- Use the RPC function (recommended - has validation)
SELECT seller_decide_after_auction(
  'YOUR_AUCTION_ID_HERE'::UUID,
  true  -- true = proceed to transaction, false = cancel
);

-- OR manually (not recommended - bypasses validation)
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'in_transaction'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- ============================================================================
-- 6. CHANGE STATUS: IN_TRANSACTION → SOLD
-- ============================================================================

UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'sold'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- ============================================================================
-- 7. CHANGE STATUS: IN_TRANSACTION → DEAL_FAILED
-- ============================================================================

UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'deal_failed'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- ============================================================================
-- 8. CHANGE STATUS: ANY → CANCELLED
-- ============================================================================

UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'cancelled'),
  updated_at = NOW()
WHERE id = 'YOUR_AUCTION_ID_HERE';

-- ============================================================================
-- 9. QUICK STATUS CHANGE - REPLACE VALUES BELOW
-- ============================================================================

-- Quick template: Fill in the values and run
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'STATUS_NAME_HERE'),
  updated_at = NOW()
WHERE id = 'AUCTION_ID_HERE';

-- Valid status names:
-- - draft
-- - pending_approval
-- - scheduled
-- - live
-- - ended
-- - cancelled
-- - in_transaction
-- - sold
-- - deal_failed

-- ============================================================================
-- 10. BATCH OPERATIONS FOR TESTING
-- ============================================================================

-- Move all your live auctions to ended (for testing ended tab)
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'ended'),
  updated_at = NOW()
WHERE
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'live')
  AND seller_id = auth.uid();

-- Move all your ended auctions to in_transaction (for testing transactions tab)
UPDATE auctions
SET
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'in_transaction'),
  updated_at = NOW()
WHERE
  status_id = (SELECT id FROM auction_statuses WHERE status_name = 'ended')
  AND seller_id = auth.uid();

-- ============================================================================
-- 11. GET YOUR USER ID
-- ============================================================================

-- Find your current user ID (copy this for WHERE clauses)
SELECT auth.uid() as my_user_id;

-- ============================================================================
-- 12. VERIFY CHANGES
-- ============================================================================

-- After making changes, verify with this query
SELECT
  a.id,
  a.title,
  ast.status_name as status,
  ast.display_name,
  a.updated_at as last_updated
FROM auctions a
JOIN auction_statuses ast ON a.status_id = ast.id
WHERE a.seller_id = auth.uid()
ORDER BY a.updated_at DESC;
