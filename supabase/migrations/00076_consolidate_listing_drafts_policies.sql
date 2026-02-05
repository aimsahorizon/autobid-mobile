-- ============================================================================
-- AutoBid Mobile - Migration 00076: Consolidate Listing Drafts Update Policies
-- ============================================================================

-- Issue: Multiple overlapping update policies may be causing conflicts via WITH CHECK.
-- Solution: Drop ALL existing update policies on listing_drafts and replace with a SINGLE,
-- authoritative policy that handles both normal updates and soft-deletion.

-- 1. Drop known previous policies (order matters only for cleanliness)
DROP POLICY IF EXISTS listing_drafts_update_own ON listing_drafts;
DROP POLICY IF EXISTS listing_drafts_soft_delete_own ON listing_drafts;

-- 2. Create the unified UPDATE policy
-- This policy allows users to update their own drafts if they haven't been deleted yet.
-- The WITH CHECK clause permits the update if the user still owns it, REGARDLESS of 
-- whether they are setting deleted_at or not.
CREATE POLICY listing_drafts_update_own_unified
  ON listing_drafts
  FOR UPDATE
  USING (
    seller_id = auth.uid()
    AND deleted_at IS NULL
  )
  WITH CHECK (
    seller_id = auth.uid()
    -- Intentionally permissive: allows setting deleted_at (soft delete)
    -- and allows updating other fields.
  );

-- 3. Ensure SELECT/read access is consistent (optional but good practice)
DROP POLICY IF EXISTS listing_drafts_select_own ON listing_drafts;
CREATE POLICY listing_drafts_select_own
  ON listing_drafts
  FOR SELECT
  USING (
    seller_id = auth.uid()
    AND deleted_at IS NULL
  );

-- 4. Ensure HARD DELETE is allowed if needed (backup mechanism)
DROP POLICY IF EXISTS listing_drafts_hard_delete_own ON listing_drafts;
CREATE POLICY listing_drafts_hard_delete_own
  ON listing_drafts
  FOR DELETE
  USING (
    seller_id = auth.uid()
  );
