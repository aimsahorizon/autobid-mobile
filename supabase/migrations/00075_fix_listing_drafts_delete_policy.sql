-- ============================================================================
-- AutoBid Mobile - Migration 00075: Fix Listing Drafts Update Policy
-- Fixes conflict between update policy and soft-delete operation
-- ============================================================================

-- The existing "listing_drafts_update_own" policy has an implicit WITH CHECK clause
-- that mirrors its USING clause (deleted_at IS NULL). This prevents soft-deletion
-- updates where deleted_at becomes NOT NULL.

-- We need to separate the VISIBILITY (USING) from the VALIDITY (WITH CHECK).

DROP POLICY IF EXISTS listing_drafts_update_own ON listing_drafts;

CREATE POLICY listing_drafts_update_own
  ON listing_drafts
  FOR UPDATE
  USING (
    seller_id = auth.uid()
    AND deleted_at IS NULL
  )
  WITH CHECK (
    seller_id = auth.uid()
    -- We allow deleted_at to be changed (soft delete) or remain NULL
    -- So we don't enforce deleted_at IS NULL here
  );
