-- ============================================
-- KYC Appeal System Migration
-- ============================================

-- 1. Update kyc_statuses CHECK constraint to include 'appeal_pending' and 'suspended'
ALTER TABLE kyc_statuses DROP CONSTRAINT IF EXISTS kyc_statuses_status_name_check;
ALTER TABLE kyc_statuses ADD CONSTRAINT kyc_statuses_status_name_check
  CHECK (status_name IN ('pending', 'under_review', 'approved', 'rejected', 'expired', 'suspended', 'appeal_pending'));

-- 2. Insert appeal_pending status (skip if exists)
INSERT INTO kyc_statuses (status_name, display_name)
VALUES ('appeal_pending', 'Appeal Submitted')
ON CONFLICT (status_name) DO NOTHING;

-- Also ensure 'suspended' exists
INSERT INTO kyc_statuses (status_name, display_name)
VALUES ('suspended', 'Suspended')
ON CONFLICT (status_name) DO NOTHING;

-- 3. Create kyc_appeals table
CREATE TABLE IF NOT EXISTS kyc_appeals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  kyc_document_id UUID REFERENCES kyc_documents(id) ON DELETE SET NULL,
  appeal_reason TEXT NOT NULL CHECK (char_length(appeal_reason) >= 20 AND char_length(appeal_reason) <= 500),
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Enable RLS on kyc_appeals
ALTER TABLE kyc_appeals ENABLE ROW LEVEL SECURITY;

-- Users can view their own appeals
CREATE POLICY "Users can view own appeals"
  ON kyc_appeals FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own appeals
CREATE POLICY "Users can insert own appeals"
  ON kyc_appeals FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Admins can view all appeals
CREATE POLICY "Admins can view all appeals"
  ON kyc_appeals FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Admins can update appeals
CREATE POLICY "Admins can update appeals"
  ON kyc_appeals FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- 5. Create submit_kyc_appeal RPC function
CREATE OR REPLACE FUNCTION submit_kyc_appeal(
  p_user_id UUID,
  p_appeal_reason TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_kyc_doc_id UUID;
  v_current_status TEXT;
  v_appeal_pending_status_id UUID;
  v_appeal_id UUID;
BEGIN
  -- Verify the user exists and their KYC is rejected
  SELECT kd.id, ks.status_name
  INTO v_kyc_doc_id, v_current_status
  FROM kyc_documents kd
  JOIN kyc_statuses ks ON kd.status_id = ks.id
  WHERE kd.user_id = p_user_id
  ORDER BY kd.created_at DESC
  LIMIT 1;

  IF v_kyc_doc_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'No KYC submission found');
  END IF;

  IF v_current_status != 'rejected' THEN
    RETURN json_build_object('success', false, 'error', 'Appeals are only allowed for rejected applications');
  END IF;

  -- Check for existing pending appeal
  IF EXISTS (
    SELECT 1 FROM kyc_appeals
    WHERE user_id = p_user_id AND status = 'pending'
  ) THEN
    RETURN json_build_object('success', false, 'error', 'You already have a pending appeal');
  END IF;

  -- Get the appeal_pending status ID
  SELECT id INTO v_appeal_pending_status_id
  FROM kyc_statuses
  WHERE status_name = 'appeal_pending';

  IF v_appeal_pending_status_id IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Appeal status not configured');
  END IF;

  -- Insert the appeal
  INSERT INTO kyc_appeals (user_id, kyc_document_id, appeal_reason)
  VALUES (p_user_id, v_kyc_doc_id, p_appeal_reason)
  RETURNING id INTO v_appeal_id;

  -- Update KYC document status to appeal_pending
  UPDATE kyc_documents
  SET status_id = v_appeal_pending_status_id,
      updated_at = NOW()
  WHERE id = v_kyc_doc_id;

  RETURN json_build_object(
    'success', true,
    'appeal_id', v_appeal_id,
    'message', 'Appeal submitted successfully'
  );
END;
$$;

-- 6. Updated_at trigger for kyc_appeals
CREATE OR REPLACE FUNCTION update_kyc_appeals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_kyc_appeals_updated_at
  BEFORE UPDATE ON kyc_appeals
  FOR EACH ROW
  EXECUTE FUNCTION update_kyc_appeals_updated_at();
