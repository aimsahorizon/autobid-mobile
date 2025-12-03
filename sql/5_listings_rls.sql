-- ============================================================================
-- ROW LEVEL SECURITY POLICIES FOR LISTINGS
-- ============================================================================

-- Enable RLS
ALTER TABLE listing_drafts ENABLE ROW LEVEL SECURITY;
ALTER TABLE listing_drafts FORCE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings FORCE ROW LEVEL SECURITY;

-- ============================================================================
-- LISTING DRAFTS POLICIES
-- ============================================================================

-- Policy: Sellers can view their own drafts
CREATE POLICY "drafts_select_own"
ON listing_drafts FOR SELECT
USING (auth.uid() = seller_id AND deleted_at IS NULL);

-- Policy: Sellers can create their own drafts
CREATE POLICY "drafts_insert_own"
ON listing_drafts FOR INSERT
WITH CHECK (auth.uid() = seller_id);

-- Policy: Sellers can update their own drafts
CREATE POLICY "drafts_update_own"
ON listing_drafts FOR UPDATE
USING (auth.uid() = seller_id AND deleted_at IS NULL)
WITH CHECK (auth.uid() = seller_id AND deleted_at IS NULL);

-- Policy: Sellers can delete (soft delete) their own drafts
CREATE POLICY "drafts_delete_own"
ON listing_drafts FOR UPDATE
USING (auth.uid() = seller_id AND deleted_at IS NULL)
WITH CHECK (auth.uid() = seller_id AND deleted_at IS NOT NULL);

-- ============================================================================
-- LISTINGS POLICIES - SELECT (Read)
-- ============================================================================

-- Policy: Sellers can view their own listings (all statuses)
CREATE POLICY "listings_select_own"
ON listings FOR SELECT
USING (auth.uid() = seller_id AND deleted_at IS NULL);

-- Policy: Public can view active listings only
CREATE POLICY "listings_select_active_public"
ON listings FOR SELECT
USING (
  status = 'active'
  AND deleted_at IS NULL
  AND auction_end_time > NOW()
);

-- Policy: Admins can view all listings (service_role bypasses RLS anyway)
-- No explicit policy needed for admins

-- ============================================================================
-- LISTINGS POLICIES - INSERT (Create)
-- ============================================================================

-- Policy: Sellers can create listings (from draft submission)
CREATE POLICY "listings_insert_own"
ON listings FOR INSERT
WITH CHECK (auth.uid() = seller_id);

-- ============================================================================
-- LISTINGS POLICIES - UPDATE (Modify)
-- ============================================================================

-- Policy: Sellers can update their own approved listings (to make them live)
CREATE POLICY "listings_update_own_approved"
ON listings FOR UPDATE
USING (
  auth.uid() = seller_id
  AND admin_status = 'approved'
  AND status IN ('approved', 'active')
  AND deleted_at IS NULL
)
WITH CHECK (
  auth.uid() = seller_id
  AND deleted_at IS NULL
);

-- Policy: Sellers can update ended/sold listings (for transaction completion)
CREATE POLICY "listings_update_own_ended"
ON listings FOR UPDATE
USING (
  auth.uid() = seller_id
  AND status IN ('ended', 'sold')
  AND deleted_at IS NULL
)
WITH CHECK (
  auth.uid() = seller_id
  AND deleted_at IS NULL
);

-- Policy: System can update active listings (for bid updates, views, watchers)
-- This is handled by service_role key in backend

-- ============================================================================
-- LISTINGS POLICIES - DELETE (Soft Delete)
-- ============================================================================

-- Policy: Sellers can cancel their own draft/pending listings
CREATE POLICY "listings_cancel_own_draft"
ON listings FOR UPDATE
USING (
  auth.uid() = seller_id
  AND status IN ('pending', 'approved')
  AND deleted_at IS NULL
)
WITH CHECK (
  auth.uid() = seller_id
  AND status = 'cancelled'
  AND deleted_at IS NULL
);

-- ============================================================================
-- PREVENT PRIVILEGE ESCALATION
-- Sellers cannot change: admin_status, reviewed_by, winner_id
-- ============================================================================

CREATE OR REPLACE FUNCTION prevent_listing_privilege_escalation()
RETURNS TRIGGER AS $$
BEGIN
  -- Allow if using service_role (admins/system)
  IF current_setting('request.jwt.claims', true)::json->>'role' = 'service_role' THEN
    RETURN NEW;
  END IF;

  -- Prevent sellers from changing admin review fields
  IF NEW.admin_status IS DISTINCT FROM OLD.admin_status THEN
    RAISE EXCEPTION 'Cannot change admin status';
  END IF;

  IF NEW.reviewed_by IS DISTINCT FROM OLD.reviewed_by THEN
    RAISE EXCEPTION 'Cannot change reviewer';
  END IF;

  IF NEW.reviewed_at IS DISTINCT FROM OLD.reviewed_at THEN
    RAISE EXCEPTION 'Cannot change review timestamp';
  END IF;

  IF NEW.rejection_reason IS DISTINCT FROM OLD.rejection_reason THEN
    RAISE EXCEPTION 'Cannot change rejection reason';
  END IF;

  -- Prevent sellers from changing winner info
  IF NEW.winner_id IS DISTINCT FROM OLD.winner_id THEN
    RAISE EXCEPTION 'Cannot change winner';
  END IF;

  -- Prevent sellers from directly changing bid/engagement metrics
  IF NEW.total_bids IS DISTINCT FROM OLD.total_bids THEN
    RAISE EXCEPTION 'Cannot change bid count';
  END IF;

  IF NEW.current_bid IS DISTINCT FROM OLD.current_bid THEN
    RAISE EXCEPTION 'Cannot change current bid';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER prevent_listing_escalation
BEFORE UPDATE ON listings
FOR EACH ROW
EXECUTE FUNCTION prevent_listing_privilege_escalation();

-- ============================================================================
-- LISTINGS RLS COMPLETE
-- Next: Run 6_listings_storage.sql for photo upload policies
-- ============================================================================
