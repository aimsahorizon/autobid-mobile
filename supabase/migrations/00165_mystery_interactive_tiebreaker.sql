-- ============================================================================
-- Migration 00165: Interactive Mystery Tiebreaker (RPS + Wheel of Names)
-- ============================================================================
-- Replaces auto coin_flip/lottery with player-driven tiebreakers:
--   2-player tie → Rock-Paper-Scissors (simultaneous, endless rounds)
--   3+ player tie → Wheel of Names (animated, seed-based replay)
-- Ready deadline: 1hr (RPS) / 12hr (wheel). Failure = DQ + deposit refund.
-- Cascades through bid tiers if all DQ'd at a given price level.
-- ============================================================================

-- ============================================================================
-- 0. Ensure 'standby' bid status exists (expand CHECK constraint first)
-- ============================================================================
ALTER TABLE public.bid_statuses
  DROP CONSTRAINT IF EXISTS bid_statuses_status_name_check;
ALTER TABLE public.bid_statuses
  ADD CONSTRAINT bid_statuses_status_name_check
  CHECK (status_name IN ('active', 'outbid', 'winning', 'won', 'lost', 'refunded', 'standby'));

INSERT INTO public.bid_statuses (status_name, display_name)
VALUES ('standby', 'Standby')
ON CONFLICT (status_name) DO NOTHING;

-- ============================================================================
-- 1. Create mystery_tiebreaker_sessions table
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.mystery_tiebreaker_sessions (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id           UUID NOT NULL,
  tiebreaker_type      TEXT NOT NULL CHECK (tiebreaker_type IN ('rps', 'wheel')),
  status               TEXT NOT NULL DEFAULT 'waiting_ready'
    CHECK (status IN ('waiting_ready', 'rps_in_progress', 'wheel_in_progress', 'completed', 'dq_all')),
  tied_amount          NUMERIC(12,2) NOT NULL,
  initial_tied_bidders UUID[] NOT NULL,
  ready_bidders        UUID[] NOT NULL DEFAULT '{}',
  ready_deadline       TIMESTAMPTZ NOT NULL,
  -- RPS state
  rps_current_round    INT NOT NULL DEFAULT 0,
  rps_choices          JSONB NOT NULL DEFAULT '{}'::JSONB, -- {uid: 'rock'|'paper'|'scissors'|null}
  rps_rounds           JSONB NOT NULL DEFAULT '[]'::JSONB, -- history array
  -- Wheel state
  wheel_seed           TEXT,
  wheel_winner_index   INT,
  -- Result
  winner_id            UUID,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add FK constraints separately, guarded so they only apply if referenced tables exist
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'auctions') THEN
    IF NOT EXISTS (
      SELECT 1 FROM information_schema.table_constraints
      WHERE constraint_name = 'mystery_tiebreaker_sessions_auction_id_fkey'
        AND table_name = 'mystery_tiebreaker_sessions'
    ) THEN
      ALTER TABLE public.mystery_tiebreaker_sessions
        ADD CONSTRAINT mystery_tiebreaker_sessions_auction_id_fkey
        FOREIGN KEY (auction_id) REFERENCES public.auctions(id) ON DELETE CASCADE;
    END IF;
  END IF;
END;
$$;

CREATE INDEX IF NOT EXISTS idx_mts_auction_status
  ON public.mystery_tiebreaker_sessions(auction_id, status);

ALTER TABLE public.mystery_tiebreaker_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "mts_authenticated_read" ON public.mystery_tiebreaker_sessions;
CREATE POLICY "mts_authenticated_read" ON public.mystery_tiebreaker_sessions
  FOR SELECT USING (auth.uid() IS NOT NULL);

GRANT SELECT ON public.mystery_tiebreaker_sessions TO authenticated;

-- ============================================================================
-- 2. Internal: create a tiebreaker session for a set of tied bidders
-- ============================================================================
CREATE OR REPLACE FUNCTION public._mts_create(
  p_auction_id   UUID,
  p_tied_amount  NUMERIC,
  p_tied_bidders UUID[]
) RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_count      INT;
  v_type       TEXT;
  v_deadline   TIMESTAMPTZ;
  v_choices    JSONB;
  v_session_id UUID;
  v_standby_id UUID;
  v_i          INT;
BEGIN
  v_count    := array_length(p_tied_bidders, 1);
  v_type     := CASE WHEN v_count = 2 THEN 'rps' ELSE 'wheel' END;
  v_deadline := CASE WHEN v_count = 2
                     THEN NOW() + INTERVAL '1 hour'
                     ELSE NOW() + INTERVAL '12 hours' END;

  -- Build initial rps_choices with null values (not chosen yet)
  v_choices := '{}'::JSONB;
  FOR v_i IN 1..v_count LOOP
    v_choices := v_choices || jsonb_build_object(p_tied_bidders[v_i]::TEXT, NULL);
  END LOOP;

  INSERT INTO public.mystery_tiebreaker_sessions (
    auction_id, tiebreaker_type, tied_amount,
    initial_tied_bidders, ready_deadline, rps_choices
  ) VALUES (
    p_auction_id, v_type, p_tied_amount,
    p_tied_bidders, v_deadline, v_choices
  ) RETURNING id INTO v_session_id;

  -- Mark tied bids as standby
  SELECT id INTO v_standby_id FROM public.bid_statuses WHERE status_name = 'standby';
  IF v_standby_id IS NOT NULL THEN
    UPDATE public.bids
    SET status_id = v_standby_id, updated_at = NOW()
    WHERE auction_id = p_auction_id
      AND bidder_id = ANY(p_tied_bidders)
      AND bid_amount = p_tied_amount;
  END IF;

  RETURN v_session_id;
END;
$$;

-- ============================================================================
-- 3. Internal: complete session — set winner, update bids + auction
-- ============================================================================
CREATE OR REPLACE FUNCTION public._mts_complete(
  p_session_id UUID,
  p_winner_id  UUID
) RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_session  RECORD;
  v_sold_id  UUID;
  v_won_id   UUID;
  v_lost_id  UUID;
BEGIN
  SELECT * INTO v_session FROM public.mystery_tiebreaker_sessions WHERE id = p_session_id;
  SELECT id INTO v_sold_id FROM public.auction_statuses WHERE status_name = 'sold';
  SELECT id INTO v_won_id  FROM public.bid_statuses     WHERE status_name = 'won';
  SELECT id INTO v_lost_id FROM public.bid_statuses     WHERE status_name = 'lost';

  UPDATE public.mystery_tiebreaker_sessions
  SET status = 'completed', winner_id = p_winner_id, updated_at = NOW()
  WHERE id = p_session_id;

  -- Winner bid
  UPDATE public.bids SET status_id = v_won_id
  WHERE auction_id = v_session.auction_id
    AND bidder_id = p_winner_id
    AND bid_amount = v_session.tied_amount;

  -- All other tied bids → lost
  UPDATE public.bids SET status_id = v_lost_id
  WHERE auction_id = v_session.auction_id
    AND bid_amount = v_session.tied_amount
    AND bidder_id != p_winner_id;

  -- Auction sold
  UPDATE public.auctions
  SET status_id = v_sold_id, current_price = v_session.tied_amount, updated_at = NOW()
  WHERE id = v_session.auction_id;

  -- Persist in mystery_tiebreakers for replay widget
  INSERT INTO public.mystery_tiebreakers (
    auction_id, tied_amount, tied_bidder_ids,
    winner_id, tiebreaker_type, result_seed
  ) VALUES (
    v_session.auction_id,
    v_session.tied_amount,
    v_session.initial_tied_bidders,
    p_winner_id,
    v_session.tiebreaker_type,
    COALESCE(v_session.wheel_seed, p_session_id::TEXT)
  )
  ON CONFLICT ON CONSTRAINT mystery_tiebreakers_auction_id_key
  DO UPDATE SET
    winner_id       = EXCLUDED.winner_id,
    tiebreaker_type = EXCLUDED.tiebreaker_type,
    result_seed     = EXCLUDED.result_seed;
END;
$$;

-- ============================================================================
-- 4. Internal: cascade to next bid tier after all DQ
-- ============================================================================
CREATE OR REPLACE FUNCTION public._mts_cascade(p_auction_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_next_amount  NUMERIC;
  v_next_bidders UUID[];
  v_next_count   INT;
  v_sold_id      UUID;
  v_won_id       UUID;
  v_lost_id      UUID;
  v_unsold_id    UUID;
BEGIN
  SELECT id INTO v_won_id    FROM public.bid_statuses     WHERE status_name = 'won';
  SELECT id INTO v_lost_id   FROM public.bid_statuses     WHERE status_name = 'lost';
  SELECT id INTO v_unsold_id FROM public.auction_statuses WHERE status_name = 'unsold';
  SELECT id INTO v_sold_id   FROM public.auction_statuses WHERE status_name = 'sold';

  -- Next tier: highest amount among bids NOT yet won/lost
  SELECT MAX(bid_amount) INTO v_next_amount
  FROM public.bids
  WHERE auction_id = p_auction_id
    AND status_id != v_won_id
    AND status_id != v_lost_id;

  IF v_next_amount IS NULL THEN
    UPDATE public.auctions SET status_id = v_unsold_id, updated_at = NOW()
    WHERE id = p_auction_id;
    RETURN json_build_object('result', 'unsold');
  END IF;

  SELECT array_agg(DISTINCT bidder_id), COUNT(DISTINCT bidder_id)
  INTO v_next_bidders, v_next_count
  FROM public.bids
  WHERE auction_id = p_auction_id
    AND bid_amount = v_next_amount
    AND status_id NOT IN (v_won_id, v_lost_id);

  IF v_next_count = 1 THEN
    -- Single winner at this tier
    UPDATE public.bids SET status_id = v_won_id
    WHERE auction_id = p_auction_id
      AND bidder_id = v_next_bidders[1]
      AND bid_amount = v_next_amount;
    UPDATE public.bids SET status_id = v_lost_id
    WHERE auction_id = p_auction_id
      AND bidder_id != v_next_bidders[1]
      AND status_id NOT IN (v_won_id, v_lost_id);
    UPDATE public.auctions
    SET status_id = v_sold_id, current_price = v_next_amount, updated_at = NOW()
    WHERE id = p_auction_id;
    RETURN json_build_object('result', 'winner', 'winner_id', v_next_bidders[1]);
  ELSE
    -- Another tie: new session
    PERFORM public._mts_create(p_auction_id, v_next_amount, v_next_bidders);
    RETURN json_build_object('result', 'new_session', 'tier', v_next_amount, 'count', v_next_count);
  END IF;
END;
$$;

-- ============================================================================
-- 5. Public: get_mystery_participants
--    Returns bidder_id + submitted_at for bid history tab (active mystery)
--    Amounts intentionally excluded to preserve sealed-bid secrecy
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_mystery_participants(p_auction_id UUID)
RETURNS TABLE(bidder_id UUID, submitted_at TIMESTAMPTZ)
LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
BEGIN
  RETURN QUERY
    SELECT b.bidder_id, b.created_at AS submitted_at
    FROM public.bids b
    WHERE b.auction_id = p_auction_id
    ORDER BY b.created_at ASC;
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_mystery_participants(UUID) TO authenticated;

-- ============================================================================
-- 6. Public: get_mystery_tiebreaker_session
--    Returns full session state, hiding opponent's RPS choice until both submit
-- ============================================================================
CREATE OR REPLACE FUNCTION public.get_mystery_tiebreaker_session(p_auction_id UUID)
RETURNS JSON LANGUAGE plpgsql STABLE SECURITY DEFINER AS $$
DECLARE
  v_uid        UUID := auth.uid();
  v_session    RECORD;
  v_choices    JSONB;
  v_my_choice  TEXT;
  v_opp_sub    BOOLEAN := FALSE;
  v_both_sub   BOOLEAN := TRUE;
  v_r          RECORD;
  v_ready_info JSONB := '[]'::JSONB;
  v_rb         UUID;
BEGIN
  SELECT * INTO v_session
  FROM public.mystery_tiebreaker_sessions
  WHERE auction_id = p_auction_id
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object('found', FALSE);
  END IF;

  v_choices   := v_session.rps_choices;
  v_my_choice := v_choices->>(v_uid::TEXT);

  -- Check both_submitted and opponent_submitted
  FOR v_r IN SELECT key, value FROM jsonb_each_text(v_choices) LOOP
    IF v_r.value IS NULL THEN
      v_both_sub := FALSE;
    END IF;
    IF v_r.key != v_uid::TEXT AND v_r.value IS NOT NULL THEN
      v_opp_sub := TRUE;
    END IF;
  END LOOP;

  -- Build ready aliases array
  IF v_session.ready_bidders IS NOT NULL THEN
    FOREACH v_rb IN ARRAY v_session.ready_bidders LOOP
      v_ready_info := v_ready_info || jsonb_build_array(jsonb_build_object(
        'user_id', v_rb,
        'alias', COALESCE(
          (SELECT alias FROM public.auction_aliases WHERE auction_id = p_auction_id AND user_id = v_rb),
          'Unknown'
        )
      ));
    END LOOP;
  END IF;

  RETURN json_build_object(
    'found',                TRUE,
    'id',                   v_session.id,
    'auction_id',           v_session.auction_id,
    'tiebreaker_type',      v_session.tiebreaker_type,
    'status',               v_session.status,
    'tied_amount',          v_session.tied_amount,
    'initial_tied_count',   array_length(v_session.initial_tied_bidders, 1),
    'ready_count',          COALESCE(array_length(v_session.ready_bidders, 1), 0),
    'ready_aliases',        v_ready_info,
    'ready_deadline',       v_session.ready_deadline,
    'is_ready',             (v_uid = ANY(v_session.ready_bidders)),
    'is_participant',       (v_uid = ANY(v_session.initial_tied_bidders)),
    'rps_current_round',    v_session.rps_current_round,
    'my_rps_choice',        v_my_choice,
    'opponent_submitted',   v_opp_sub,
    'both_submitted',       v_both_sub,
    -- Only reveal choices after both submitted (round already resolved by then)
    'rps_choices_revealed', CASE WHEN v_both_sub THEN v_choices ELSE NULL END,
    'rps_rounds',           v_session.rps_rounds,
    'wheel_seed',           CASE WHEN v_session.status IN ('wheel_in_progress', 'completed')
                                 THEN v_session.wheel_seed ELSE NULL END,
    'wheel_winner_index',   CASE WHEN v_session.status IN ('wheel_in_progress', 'completed')
                                 THEN v_session.wheel_winner_index ELSE NULL END,
    'winner_id',            v_session.winner_id,
    'my_alias',             COALESCE(
                              (SELECT alias FROM public.auction_aliases WHERE auction_id = p_auction_id AND user_id = v_uid),
                              'Unknown'
                            ),
    'created_at',           v_session.created_at,
    'updated_at',           v_session.updated_at
  );
END;
$$;
GRANT EXECUTE ON FUNCTION public.get_mystery_tiebreaker_session(UUID) TO authenticated;

-- ============================================================================
-- 7. Public: set_mystery_ready
--    Mark current user ready. If all ready → start game immediately.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.set_mystery_ready(p_auction_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid          UUID := auth.uid();
  v_session      RECORD;
  v_ready_now    UUID[];
  v_ready_count  INT;
  v_total        INT;
  v_seed         TEXT;
  v_winner_idx   INT;
  v_winner_id    UUID;
  v_choices      JSONB;
  v_rb           UUID;
BEGIN
  SELECT * INTO v_session
  FROM public.mystery_tiebreaker_sessions
  WHERE auction_id = p_auction_id AND status = 'waiting_ready'
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'error', 'No active tiebreaker waiting for ready');
  END IF;
  IF NOT (v_uid = ANY(v_session.initial_tied_bidders)) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Not a participant');
  END IF;
  IF v_uid = ANY(v_session.ready_bidders) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Already ready');
  END IF;

  UPDATE public.mystery_tiebreaker_sessions
  SET ready_bidders = array_append(ready_bidders, v_uid), updated_at = NOW()
  WHERE id = v_session.id
  RETURNING ready_bidders INTO v_ready_now;

  v_ready_count := COALESCE(array_length(v_ready_now, 1), 0);
  v_total       := array_length(v_session.initial_tied_bidders, 1);

  -- All ready → start immediately
  IF v_ready_count = v_total THEN
    IF v_session.tiebreaker_type = 'rps' THEN
      UPDATE public.mystery_tiebreaker_sessions
      SET status = 'rps_in_progress', updated_at = NOW()
      WHERE id = v_session.id;
      RETURN json_build_object('success', TRUE, 'action', 'rps_started', 'all_ready', TRUE);
    ELSE
      -- Spin wheel immediately with all participants
      v_seed       := md5(random()::TEXT || NOW()::TEXT);
      v_winner_idx := floor(random() * v_ready_count)::INT + 1;
      v_winner_id  := v_ready_now[v_winner_idx];
      UPDATE public.mystery_tiebreaker_sessions
      SET status = 'wheel_in_progress', wheel_seed = v_seed,
          wheel_winner_index = v_winner_idx, winner_id = v_winner_id,
          updated_at = NOW()
      WHERE id = v_session.id;
      PERFORM public._mts_complete(v_session.id, v_winner_id);
      RETURN json_build_object('success', TRUE, 'action', 'wheel_spun',
        'winner_id', v_winner_id, 'seed', v_seed, 'winner_index', v_winner_idx);
    END IF;
  END IF;

  RETURN json_build_object('success', TRUE, 'action', 'ready_set',
    'ready_count', v_ready_count, 'total', v_total);
END;
$$;
GRANT EXECUTE ON FUNCTION public.set_mystery_ready(UUID) TO authenticated;

-- ============================================================================
-- 8. Public: submit_rps_choice
--    Simultaneous sealed-choice submit. Resolves round when both submitted.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.submit_rps_choice(p_auction_id UUID, p_choice TEXT)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_uid        UUID := auth.uid();
  v_session    RECORD;
  v_new_ch     JSONB;
  v_p1         UUID;
  v_p2         UUID;
  v_c1         TEXT;
  v_c2         TEXT;
  v_winner_id  UUID;
  v_round_rec  JSONB;
BEGIN
  IF p_choice NOT IN ('rock', 'paper', 'scissors') THEN
    RETURN json_build_object('success', FALSE, 'error', 'Invalid choice');
  END IF;

  SELECT * INTO v_session
  FROM public.mystery_tiebreaker_sessions
  WHERE auction_id = p_auction_id AND status = 'rps_in_progress'
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'error', 'No RPS session in progress');
  END IF;
  IF NOT (v_uid = ANY(v_session.ready_bidders)) THEN
    RETURN json_build_object('success', FALSE, 'error', 'Not a participant');
  END IF;
  IF (v_session.rps_choices->>(v_uid::TEXT)) IS NOT NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Already submitted choice this round');
  END IF;

  v_new_ch := v_session.rps_choices || jsonb_build_object(v_uid::TEXT, p_choice);
  UPDATE public.mystery_tiebreaker_sessions
  SET rps_choices = v_new_ch, updated_at = NOW()
  WHERE id = v_session.id;

  v_p1 := v_session.ready_bidders[1];
  v_p2 := v_session.ready_bidders[2];
  v_c1 := v_new_ch->>(v_p1::TEXT);
  v_c2 := v_new_ch->>(v_p2::TEXT);

  IF v_c1 IS NOT NULL AND v_c2 IS NOT NULL THEN
    IF v_c1 = v_c2 THEN
      -- Tie: record round, start next
      v_round_rec := jsonb_build_object(
        'round', v_session.rps_current_round,
        'p1_id', v_p1, 'p1_choice', v_c1,
        'p2_id', v_p2, 'p2_choice', v_c2,
        'result', 'tie'
      );
      UPDATE public.mystery_tiebreaker_sessions
      SET rps_current_round = rps_current_round + 1,
          rps_rounds        = rps_rounds || v_round_rec,
          rps_choices       = jsonb_build_object(v_p1::TEXT, NULL, v_p2::TEXT, NULL),
          updated_at        = NOW()
      WHERE id = v_session.id;
      RETURN json_build_object('success', TRUE, 'result', 'tie',
        'p1_choice', v_c1, 'p2_choice', v_c2,
        'next_round', v_session.rps_current_round + 1);
    ELSE
      -- Determine winner
      IF (v_c1='rock' AND v_c2='scissors') OR
         (v_c1='scissors' AND v_c2='paper') OR
         (v_c1='paper' AND v_c2='rock') THEN
        v_winner_id := v_p1;
      ELSE
        v_winner_id := v_p2;
      END IF;
      v_round_rec := jsonb_build_object(
        'round', v_session.rps_current_round,
        'p1_id', v_p1, 'p1_choice', v_c1,
        'p2_id', v_p2, 'p2_choice', v_c2,
        'result', 'winner', 'winner_id', v_winner_id
      );
      UPDATE public.mystery_tiebreaker_sessions
      SET rps_rounds = rps_rounds || v_round_rec,
          status     = 'completed',
          winner_id  = v_winner_id,
          updated_at = NOW()
      WHERE id = v_session.id;
      PERFORM public._mts_complete(v_session.id, v_winner_id);
      RETURN json_build_object('success', TRUE, 'result', 'winner',
        'winner_id', v_winner_id, 'p1_choice', v_c1, 'p2_choice', v_c2);
    END IF;
  END IF;

  RETURN json_build_object('success', TRUE, 'result', 'waiting', 'my_choice', p_choice);
END;
$$;
GRANT EXECUTE ON FUNCTION public.submit_rps_choice(UUID, TEXT) TO authenticated;

-- ============================================================================
-- 9. Public: process_ready_timeout
--    Call when ready_deadline passes. DQs non-ready, starts game or cascades.
-- ============================================================================
CREATE OR REPLACE FUNCTION public.process_ready_timeout(p_auction_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_session       RECORD;
  v_ready         UUID[];
  v_ready_count   INT;
  v_dq_list       UUID[];
  v_dq_bidder     UUID;
  v_winner_id     UUID;
  v_winner_idx    INT;
  v_seed          TEXT;
  v_lost_id       UUID;
  v_choices       JSONB;
  v_rb            UUID;
BEGIN
  SELECT * INTO v_session
  FROM public.mystery_tiebreaker_sessions
  WHERE auction_id = p_auction_id
    AND status = 'waiting_ready'
    AND ready_deadline <= NOW()
  ORDER BY created_at DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RETURN json_build_object('success', FALSE, 'error', 'No expired session found');
  END IF;

  SELECT id INTO v_lost_id FROM public.bid_statuses WHERE status_name = 'lost';
  v_ready       := v_session.ready_bidders;
  v_ready_count := COALESCE(array_length(v_ready, 1), 0);

  -- DQ non-ready: refund deposits + mark bids lost
  SELECT array_agg(b) INTO v_dq_list
  FROM unnest(v_session.initial_tied_bidders) b
  WHERE (v_ready_count = 0) OR NOT (b = ANY(v_ready));

  IF v_dq_list IS NOT NULL THEN
    FOREACH v_dq_bidder IN ARRAY v_dq_list LOOP
      PERFORM public.refund_deposit(v_session.auction_id, v_dq_bidder);
      UPDATE public.bids SET status_id = v_lost_id
      WHERE auction_id = v_session.auction_id
        AND bidder_id = v_dq_bidder
        AND bid_amount = v_session.tied_amount;
    END LOOP;
  END IF;

  IF v_ready_count = 0 THEN
    UPDATE public.mystery_tiebreaker_sessions
    SET status = 'dq_all', updated_at = NOW()
    WHERE id = v_session.id;
    RETURN public._mts_cascade(p_auction_id);

  ELSIF v_ready_count = 1 THEN
    v_winner_id := v_ready[1];
    PERFORM public._mts_complete(v_session.id, v_winner_id);
    RETURN json_build_object('success', TRUE, 'result', 'auto_win', 'winner_id', v_winner_id);

  ELSE
    IF v_session.tiebreaker_type = 'rps' THEN
      -- Rebuild choices for only ready players
      v_choices := '{}'::JSONB;
      FOREACH v_rb IN ARRAY v_ready LOOP
        v_choices := v_choices || jsonb_build_object(v_rb::TEXT, NULL);
      END LOOP;
      UPDATE public.mystery_tiebreaker_sessions
      SET status = 'rps_in_progress', rps_choices = v_choices, updated_at = NOW()
      WHERE id = v_session.id;
      RETURN json_build_object('success', TRUE, 'result', 'rps_started');
    ELSE
      v_seed       := md5(random()::TEXT || NOW()::TEXT);
      v_winner_idx := floor(random() * v_ready_count)::INT + 1;
      v_winner_id  := v_ready[v_winner_idx];
      UPDATE public.mystery_tiebreaker_sessions
      SET status = 'wheel_in_progress', wheel_seed = v_seed,
          wheel_winner_index = v_winner_idx, winner_id = v_winner_id,
          updated_at = NOW()
      WHERE id = v_session.id;
      PERFORM public._mts_complete(v_session.id, v_winner_id);
      RETURN json_build_object('success', TRUE, 'result', 'wheel_spun',
        'winner_id', v_winner_id, 'seed', v_seed, 'winner_index', v_winner_idx);
    END IF;
  END IF;
END;
$$;
GRANT EXECUTE ON FUNCTION public.process_ready_timeout(UUID) TO authenticated;

-- ============================================================================
-- 10. Re-apply end_auction with interactive tiebreaker for mystery auctions
--     (Keeps normal auction logic and virtual wallet deposit returns)
-- ============================================================================
DROP FUNCTION IF EXISTS public.end_auction(UUID);

CREATE OR REPLACE FUNCTION public.end_auction(p_auction_id UUID)
RETURNS JSON LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_ended_id       UUID;
  v_sold_id        UUID;
  v_unsold_id      UUID;
  v_won_id         UUID;
  v_lost_id        UUID;
  v_auction        RECORD;
  v_highest_amount NUMERIC;
  v_tied_count     INT;
  v_tied_bidders   UUID[];
  v_winner_id      UUID;
  v_winning_bid    RECORD;
  result           JSON;
BEGIN
  SELECT id INTO v_ended_id  FROM public.auction_statuses WHERE status_name = 'ended';
  SELECT id INTO v_sold_id   FROM public.auction_statuses WHERE status_name = 'sold';
  SELECT id INTO v_unsold_id FROM public.auction_statuses WHERE status_name = 'unsold';
  SELECT id INTO v_won_id    FROM public.bid_statuses     WHERE status_name = 'won';
  SELECT id INTO v_lost_id   FROM public.bid_statuses     WHERE status_name = 'lost';

  SELECT * INTO v_auction FROM public.auctions WHERE id = p_auction_id;

  -- ================================================================
  -- MYSTERY AUCTION: interactive tiebreaker
  -- ================================================================
  IF v_auction.bidding_type = 'mystery' THEN
    -- Mark auction ended (will become 'sold' when tiebreaker resolves)
    UPDATE public.auctions SET status_id = v_ended_id WHERE id = p_auction_id;

    SELECT MAX(bid_amount) INTO v_highest_amount
    FROM public.bids WHERE auction_id = p_auction_id;

    IF v_highest_amount IS NOT NULL THEN
      SELECT COUNT(DISTINCT bidder_id), array_agg(DISTINCT bidder_id)
      INTO v_tied_count, v_tied_bidders
      FROM public.bids
      WHERE auction_id = p_auction_id AND bid_amount = v_highest_amount;

      -- Mark all non-top bids as lost immediately
      UPDATE public.bids SET status_id = v_lost_id
      WHERE auction_id = p_auction_id AND bid_amount < v_highest_amount;

      IF v_tied_count = 1 THEN
        -- Single winner: resolve immediately
        v_winner_id := v_tied_bidders[1];
        UPDATE public.auctions
        SET status_id = v_sold_id, current_price = v_highest_amount, updated_at = NOW()
        WHERE id = p_auction_id;
        UPDATE public.bids SET status_id = v_won_id
        WHERE auction_id = p_auction_id AND bidder_id = v_winner_id;
        result := json_build_object('success', TRUE, 'winner_id', v_winner_id,
          'winning_amount', v_highest_amount, 'tiebreaker', FALSE);
      ELSE
        -- Tie: create interactive session; auction stays 'ended' until resolved
        PERFORM public._mts_create(p_auction_id, v_highest_amount, v_tied_bidders);
        result := json_build_object('success', TRUE, 'winner_id', NULL,
          'tiebreaker', TRUE,
          'type', CASE WHEN v_tied_count = 2 THEN 'rps' ELSE 'wheel' END,
          'tied_count', v_tied_count);
      END IF;
    ELSE
      -- No bids
      UPDATE public.auctions SET status_id = v_unsold_id, updated_at = NOW()
      WHERE id = p_auction_id;
      result := json_build_object('success', TRUE, 'winner_id', NULL, 'tiebreaker', FALSE);
    END IF;

    -- Return deposits (non-winners get refunds after tiebreaker resolves;
    -- initial return_auction_deposits still runs to release platform holds)
    PERFORM public.return_auction_deposits(p_auction_id);
    RETURN result;
  END IF;

  -- ================================================================
  -- NORMAL AUCTION (open / exclusive): highest bid, earliest timestamp
  -- ================================================================
  SELECT * INTO v_winning_bid
  FROM public.bids
  WHERE auction_id = p_auction_id
  ORDER BY bid_amount DESC, created_at ASC
  LIMIT 1;

  IF v_winning_bid IS NOT NULL THEN
    UPDATE public.auctions SET status_id = v_sold_id WHERE id = p_auction_id;
    UPDATE public.bids SET status_id = v_won_id WHERE id = v_winning_bid.id;
    UPDATE public.bids SET status_id = v_lost_id
    WHERE auction_id = p_auction_id AND id != v_winning_bid.id;
    result := json_build_object('success', TRUE,
      'winner_id', v_winning_bid.bidder_id, 'winning_amount', v_winning_bid.bid_amount);
  ELSE
    UPDATE public.auctions SET status_id = v_unsold_id WHERE id = p_auction_id;
    result := json_build_object('success', TRUE, 'winner_id', NULL, 'winning_amount', NULL);
  END IF;

  PERFORM public.return_auction_deposits(p_auction_id);
  RETURN result;
END;
$$;
GRANT EXECUTE ON FUNCTION public.end_auction(UUID) TO authenticated;
