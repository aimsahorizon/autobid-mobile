-- ============================================================================
-- AutoBid Mobile - Allow sellers to update non-draft auction statuses
-- Purpose: Enable sellers to change status of approved, live, scheduled, ended auctions
-- ============================================================================

-- Add policy allowing sellers to update their own non-draft auctions
CREATE POLICY "Sellers can update their own auction statuses (non-draft)"
  ON auctions FOR UPDATE
  USING (
    seller_id = auth.uid() AND
    status_id NOT IN (SELECT id FROM auction_statuses WHERE status_name = 'draft')
  )
  WITH CHECK (
    seller_id = auth.uid() AND
    status_id NOT IN (SELECT id FROM auction_statuses WHERE status_name = 'draft')
  );

-- Note: This policy allows sellers to update any non-draft auction fields.
-- In practice, the application controls which transitions are allowed:
-- - approved -> live (Go Live button)
-- - approved -> scheduled (Schedule button)
-- - live -> ended (End Auction button)
-- - ended -> pending_approval (Reauction button)
-- - ended -> cancelled (Cancel button)
--
-- The database enforces that:
-- 1. Only the seller can update their own auctions
-- 2. The auction must not be in 'draft' status
-- 3. updated_at timestamp is automatically set by the application
