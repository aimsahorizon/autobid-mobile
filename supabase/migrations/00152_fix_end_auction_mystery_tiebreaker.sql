    -- ============================================================================
    -- Migration 00152: Re-apply mystery-aware end_auction
    -- ============================================================================
    -- PROBLEM: end_auction may have been overwritten by re-running migration 00130
    -- (virtual wallet) after 00147 (mystery bidding), losing the mystery tiebreaker
    -- logic (coin flip for 2-way ties, lottery for 3+ way ties).
    --
    -- This migration re-applies the correct end_auction that handles:
    --   - Mystery auctions: tiebreaker logic with mystery_tiebreakers table
    --   - Normal auctions: standard highest-bid-first logic
    --   - Virtual wallet: deposit returns via return_auction_deposits()
    -- ============================================================================

    -- 1. Ensure mystery_tiebreakers table exists
    CREATE TABLE IF NOT EXISTS mystery_tiebreakers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
    tied_amount NUMERIC(12,2) NOT NULL,
    tied_bidder_ids UUID[] NOT NULL,
    winner_id UUID NOT NULL REFERENCES users(id),
    tiebreaker_type TEXT NOT NULL CHECK (tiebreaker_type IN ('coin_flip', 'lottery')),
    result_seed TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- Ensure unique constraint (one tiebreaker per auction)
    DO $$
    BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE indexname = 'mystery_tiebreakers_auction_id_key'
    ) THEN
        CREATE UNIQUE INDEX mystery_tiebreakers_auction_id_key ON mystery_tiebreakers(auction_id);
    END IF;
    END $$;

    -- 2. Re-apply the correct end_auction with mystery tiebreaker logic
    CREATE OR REPLACE FUNCTION end_auction(p_auction_id UUID)
    RETURNS JSON AS $$
    DECLARE
    v_ended_status_id UUID;
    v_sold_status_id UUID;
    v_unsold_status_id UUID;
    v_won_status_id UUID;
    v_lost_status_id UUID;
    v_winning_bid RECORD;
    v_auction RECORD;
    v_tied_count INT;
    v_tied_bidders UUID[];
    v_highest_amount NUMERIC;
    v_winner_id UUID;
    v_tiebreaker_type TEXT;
    v_random_index INT;
    v_seed TEXT;
    result JSON;
    BEGIN
    SELECT id INTO v_ended_status_id FROM auction_statuses WHERE status_name = 'ended';
    SELECT id INTO v_sold_status_id FROM auction_statuses WHERE status_name = 'sold';
    SELECT id INTO v_unsold_status_id FROM auction_statuses WHERE status_name = 'unsold';
    SELECT id INTO v_won_status_id FROM bid_statuses WHERE status_name = 'won';
    SELECT id INTO v_lost_status_id FROM bid_statuses WHERE status_name = 'lost';

    -- Get auction info
    SELECT * INTO v_auction FROM auctions WHERE id = p_auction_id;

    -- ================================================================
    -- MYSTERY AUCTION: sealed-bid tiebreaker logic
    -- ================================================================
    IF v_auction.bidding_type = 'mystery' THEN
        -- Get highest bid amount
        SELECT MAX(bid_amount) INTO v_highest_amount
        FROM bids WHERE auction_id = p_auction_id;

        IF v_highest_amount IS NOT NULL THEN
        -- Count how many bids at the highest amount
        SELECT COUNT(*), array_agg(bidder_id)
        INTO v_tied_count, v_tied_bidders
        FROM bids
        WHERE auction_id = p_auction_id AND bid_amount = v_highest_amount;

        IF v_tied_count = 1 THEN
            -- No tie: single winner
            v_winner_id := v_tied_bidders[1];
        ELSIF v_tied_count = 2 THEN
            -- Coin flip for 2-way tie
            v_tiebreaker_type := 'coin_flip';
            v_random_index := floor(random() * 2)::INT + 1; -- 1 or 2
            v_winner_id := v_tied_bidders[v_random_index];
            v_seed := v_random_index::TEXT;

            INSERT INTO mystery_tiebreakers (auction_id, tied_amount, tied_bidder_ids, winner_id, tiebreaker_type, result_seed)
            VALUES (p_auction_id, v_highest_amount, v_tied_bidders, v_winner_id, v_tiebreaker_type, v_seed);
        ELSE
            -- Lottery for 3+ way tie
            v_tiebreaker_type := 'lottery';
            v_random_index := floor(random() * v_tied_count)::INT + 1;
            v_winner_id := v_tied_bidders[v_random_index];
            v_seed := v_random_index::TEXT;

            INSERT INTO mystery_tiebreakers (auction_id, tied_amount, tied_bidder_ids, winner_id, tiebreaker_type, result_seed)
            VALUES (p_auction_id, v_highest_amount, v_tied_bidders, v_winner_id, v_tiebreaker_type, v_seed);
        END IF;

        -- Mark winner and update auction
        UPDATE auctions SET status_id = v_sold_status_id, current_price = v_highest_amount WHERE id = p_auction_id;
        UPDATE bids SET status_id = v_won_status_id
        WHERE auction_id = p_auction_id AND bidder_id = v_winner_id AND bid_amount = v_highest_amount;
        UPDATE bids SET status_id = v_lost_status_id
        WHERE auction_id = p_auction_id AND NOT (bidder_id = v_winner_id AND bid_amount = v_highest_amount);

        result := json_build_object(
            'success', TRUE,
            'winner_id', v_winner_id,
            'winning_amount', v_highest_amount,
            'tiebreaker', CASE WHEN v_tiebreaker_type IS NOT NULL
            THEN json_build_object('type', v_tiebreaker_type, 'tied_count', v_tied_count)
            ELSE NULL END
        );
        ELSE
        -- No bids: unsold
        UPDATE auctions SET status_id = v_unsold_status_id WHERE id = p_auction_id;
        result := json_build_object('success', TRUE, 'winner_id', NULL, 'winning_amount', NULL);
        END IF;

    -- ================================================================
    -- NORMAL AUCTION (open / exclusive): highest bid, earliest timestamp
    -- ================================================================
    ELSE
        SELECT * INTO v_winning_bid
        FROM bids
        WHERE auction_id = p_auction_id
        ORDER BY bid_amount DESC, created_at ASC
        LIMIT 1;

        IF v_winning_bid IS NOT NULL THEN
        UPDATE auctions SET status_id = v_sold_status_id WHERE id = p_auction_id;
        UPDATE bids SET status_id = v_won_status_id WHERE id = v_winning_bid.id;
        UPDATE bids SET status_id = v_lost_status_id
        WHERE auction_id = p_auction_id AND id != v_winning_bid.id;

        result := json_build_object('success', TRUE, 'winner_id', v_winning_bid.bidder_id, 'winning_amount', v_winning_bid.bid_amount);
        ELSE
        UPDATE auctions SET status_id = v_unsold_status_id WHERE id = p_auction_id;
        result := json_build_object('success', TRUE, 'winner_id', NULL, 'winning_amount', NULL);
        END IF;
    END IF;

    -- Return all deposits to bidders' virtual wallets
    PERFORM return_auction_deposits(p_auction_id);

    RETURN result;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- 3. Ensure process_expired_auctions is present and calls end_auction
    CREATE OR REPLACE FUNCTION process_expired_auctions()
    RETURNS INTEGER AS $$
    DECLARE
    v_auction_record RECORD;
    v_processed_count INTEGER := 0;
    v_live_status_id UUID;
    BEGIN
    SELECT id INTO v_live_status_id FROM auction_statuses WHERE status_name = 'live';

    FOR v_auction_record IN
        SELECT id
        FROM auctions
        WHERE status_id = v_live_status_id
        AND end_time <= NOW()
    LOOP
        PERFORM end_auction(v_auction_record.id);
        v_processed_count := v_processed_count + 1;
    END LOOP;

    RETURN v_processed_count;
    END;
    $$ LANGUAGE plpgsql SECURITY DEFINER;

    -- 4. Ensure pg_cron schedule exists
    DO $$
    BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Remove existing schedule if any, then re-add
        PERFORM cron.unschedule('process_expired_auctions');
        PERFORM cron.schedule(
        'process_expired_auctions',
        '* * * * *',
        'SELECT process_expired_auctions()'
        );
    END IF;
    EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron not available. Please enable it in Supabase Dashboard > Database > Extensions, then manually schedule: SELECT cron.schedule(''process_expired_auctions'', ''* * * * *'', ''SELECT process_expired_auctions()'');';
    END $$;

    -- 5. Enable RLS on mystery_tiebreakers (read-only for authenticated users)
    ALTER TABLE mystery_tiebreakers ENABLE ROW LEVEL SECURITY;

    DROP POLICY IF EXISTS "Users can view tiebreakers for their auctions" ON mystery_tiebreakers;
    CREATE POLICY "Users can view tiebreakers for their auctions"
    ON mystery_tiebreakers FOR SELECT
    TO authenticated
    USING (TRUE);
