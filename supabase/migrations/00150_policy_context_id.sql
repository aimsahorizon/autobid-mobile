-- ============================================================================
-- Migration 00150: Add context_id to policy_acceptances
-- Policy acceptance is now per-context:
--   bidding_rules  → context_id = auction_id (once per auction)
--   listing_rules  → context_id = NULL (always show, every submission)
--   transaction_rules → context_id = transaction_id (once per transaction)
-- ============================================================================

-- 1. Add context_id column
ALTER TABLE policy_acceptances
  ADD COLUMN IF NOT EXISTS context_id TEXT;

-- 2. Drop old unique constraint and create new one including context_id
ALTER TABLE policy_acceptances
  DROP CONSTRAINT IF EXISTS policy_acceptances_user_id_policy_type_policy_version_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_policy_acceptances_unique_ctx
  ON policy_acceptances(user_id, policy_type, policy_version, context_id)
  WHERE context_id IS NOT NULL;

-- 3. Replace has_accepted_policy to support context_id
CREATE OR REPLACE FUNCTION has_accepted_policy(
  p_user_id UUID,
  p_policy_type TEXT,
  p_policy_version INT DEFAULT 1,
  p_context_id TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  -- If no context_id specified, always return false (always show dialog)
  IF p_context_id IS NULL THEN
    RETURN FALSE;
  END IF;

  RETURN EXISTS (
    SELECT 1 FROM policy_acceptances
    WHERE user_id = p_user_id
      AND policy_type = p_policy_type
      AND policy_version = p_policy_version
      AND context_id = p_context_id
  );
END;
$$;

-- 4. Replace accept_policy to support context_id
CREATE OR REPLACE FUNCTION accept_policy(
  p_user_id UUID,
  p_policy_type TEXT,
  p_policy_version INT DEFAULT 1,
  p_context_id TEXT DEFAULT NULL
) RETURNS BOOLEAN
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  INSERT INTO policy_acceptances (user_id, policy_type, policy_version, context_id)
  VALUES (p_user_id, p_policy_type, p_policy_version, p_context_id)
  ON CONFLICT DO NOTHING;
  RETURN TRUE;
END;
$$;

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
