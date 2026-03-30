-- Migration: Fix subscription plan change logic
-- Fixes: downgrade token exploit, upgrade token cap, downgrade cooldown,
--        yearly upgrade time extension, yearly->monthly downgrade scheduling

-- =============================================================================
-- change_subscription(): Atomic plan change with business rules
-- =============================================================================
CREATE OR REPLACE FUNCTION change_subscription(
  p_user_id UUID,
  p_new_plan TEXT
)
RETURNS JSONB AS $$
DECLARE
  v_current RECORD;
  v_current_plan TEXT;
  v_current_tier INT;
  v_new_tier INT;
  v_is_upgrade BOOLEAN;
  v_is_downgrade BOOLEAN;
  v_is_same_tier BOOLEAN;
  v_current_is_yearly BOOLEAN;
  v_new_is_yearly BOOLEAN;
  v_token_bidding INT := 0;
  v_token_listing INT := 0;
  v_new_end_date TIMESTAMPTZ;
  v_new_start_date TIMESTAMPTZ := NOW();
  v_new_sub RECORD;
BEGIN
  -- Validate plan value
  IF p_new_plan NOT IN ('free', 'silver_monthly', 'silver_yearly', 'gold_monthly', 'gold_yearly') THEN
    RETURN jsonb_build_object('success', false, 'error', 'invalid_plan');
  END IF;

  -- Get current active subscription
  SELECT * INTO v_current
  FROM user_subscriptions
  WHERE user_id = p_user_id AND is_active = true
  LIMIT 1;

  v_current_plan := COALESCE(v_current.plan, 'free');

  -- No-op if same plan
  IF v_current_plan = p_new_plan THEN
    RETURN jsonb_build_object('success', false, 'error', 'already_on_plan');
  END IF;

  -- Determine tier levels: free=0, silver=1, gold=2
  v_current_tier := CASE
    WHEN v_current_plan IN ('silver_monthly', 'silver_yearly') THEN 1
    WHEN v_current_plan IN ('gold_monthly', 'gold_yearly') THEN 2
    ELSE 0
  END;

  v_new_tier := CASE
    WHEN p_new_plan IN ('silver_monthly', 'silver_yearly') THEN 1
    WHEN p_new_plan IN ('gold_monthly', 'gold_yearly') THEN 2
    ELSE 0
  END;

  v_is_upgrade := v_new_tier > v_current_tier;
  v_is_downgrade := v_new_tier < v_current_tier;
  v_is_same_tier := v_new_tier = v_current_tier;

  v_current_is_yearly := v_current_plan LIKE '%_yearly';
  v_new_is_yearly := p_new_plan LIKE '%_yearly';

  -- =========================================================================
  -- DOWNGRADE COOLDOWN: 24h after subscription start
  -- =========================================================================
  IF v_is_downgrade AND v_current.start_date IS NOT NULL THEN
    IF v_current.start_date + INTERVAL '24 hours' > NOW() THEN
      RETURN jsonb_build_object(
        'success', false,
        'error', 'downgrade_cooldown',
        'cooldown_ends_at', to_char(v_current.start_date + INTERVAL '24 hours', 'YYYY-MM-DD"T"HH24:MI:SS"Z"')
      );
    END IF;
  END IF;

  -- =========================================================================
  -- TOKEN ALLOCATION: based on direction
  -- =========================================================================
  IF v_is_upgrade THEN
    -- Upgrade: add only the DIFFERENCE between new plan and old plan tokens (capped)
    v_token_bidding := GREATEST(0,
      (CASE p_new_plan
        WHEN 'silver_monthly' THEN 60 WHEN 'silver_yearly' THEN 60
        WHEN 'gold_monthly' THEN 250 WHEN 'gold_yearly' THEN 250
        ELSE 0
      END)
      -
      (CASE v_current_plan
        WHEN 'silver_monthly' THEN 60 WHEN 'silver_yearly' THEN 60
        WHEN 'gold_monthly' THEN 250 WHEN 'gold_yearly' THEN 250
        ELSE 10
      END)
    );

    v_token_listing := GREATEST(0,
      (CASE p_new_plan
        WHEN 'silver_monthly' THEN 3 WHEN 'silver_yearly' THEN 3
        WHEN 'gold_monthly' THEN 10 WHEN 'gold_yearly' THEN 10
        ELSE 0
      END)
      -
      (CASE v_current_plan
        WHEN 'silver_monthly' THEN 3 WHEN 'silver_yearly' THEN 3
        WHEN 'gold_monthly' THEN 10 WHEN 'gold_yearly' THEN 10
        ELSE 1
      END)
    );
  END IF;
  -- Downgrade (including to free): 0 tokens added
  -- Same-tier billing change: 0 tokens added

  -- =========================================================================
  -- END DATE CALCULATION
  -- =========================================================================

  -- Same tier, monthly -> yearly: extend 1 year from current end_date
  IF v_is_same_tier AND v_new_is_yearly AND NOT v_current_is_yearly THEN
    v_new_start_date := COALESCE(v_current.start_date, NOW());
    v_new_end_date := COALESCE(v_current.end_date, NOW()) + INTERVAL '1 year';

  -- Same tier, yearly -> monthly: monthly starts after yearly expiry
  ELSIF v_is_same_tier AND NOT v_new_is_yearly AND v_current_is_yearly THEN
    v_new_start_date := COALESCE(v_current.end_date, NOW());
    v_new_end_date := v_new_start_date + INTERVAL '30 days';

  -- Cross-tier upgrade/downgrade or fresh: standard calculation
  ELSIF p_new_plan LIKE '%_yearly' THEN
    v_new_end_date := NOW() + INTERVAL '1 year';
  ELSIF p_new_plan LIKE '%_monthly' THEN
    v_new_end_date := NOW() + INTERVAL '30 days';
  ELSE
    -- free plan: no end date
    v_new_end_date := NULL;
  END IF;

  -- =========================================================================
  -- EXECUTE: deactivate old, create new, grant tokens
  -- =========================================================================
  UPDATE user_subscriptions
  SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  INSERT INTO user_subscriptions (user_id, plan, start_date, end_date, is_active)
  VALUES (p_user_id, p_new_plan, v_new_start_date, v_new_end_date, true)
  RETURNING * INTO v_new_sub;

  IF v_token_bidding > 0 THEN
    PERFORM add_tokens(p_user_id, 'bidding', v_token_bidding, 0, 'subscription');
  END IF;

  IF v_token_listing > 0 THEN
    PERFORM add_tokens(p_user_id, 'listing', v_token_listing, 0, 'subscription');
  END IF;

  RETURN jsonb_build_object(
    'success', true,
    'subscription', jsonb_build_object(
      'id', v_new_sub.id,
      'user_id', v_new_sub.user_id,
      'plan', v_new_sub.plan,
      'start_date', v_new_sub.start_date,
      'end_date', v_new_sub.end_date,
      'is_active', v_new_sub.is_active,
      'cancelled_at', v_new_sub.cancelled_at
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION change_subscription TO authenticated;
