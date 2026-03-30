-- Migration 00147: Mystery Bidding System
-- Implements sealed-bid auction logic for mystery bidding type:
-- - Each bidder can only place ONE bid (sealed)
-- - Bids are hidden from all buyers during auction; seller can view
-- - On auction end, all bids are revealed sorted highest-first
-- - Tiebreaker: coin flip (2-way) or lottery (3+), results stored for replay
-- - Inactive users see the same tiebreaker UI as "replay"

-- ========================================================================
-- 1. Create mystery_tiebreakers table (stores tiebreaker results for replay)
-- ========================================================================

CREATE TABLE IF NOT EXISTS public.mystery_tiebreakers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id UUID NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  tied_amount NUMERIC(12, 2) NOT NULL,
  tied_bidder_ids UUID[] NOT NULL,
  winner_id UUID NOT NULL REFERENCES public.users(id),
  tiebreaker_type TEXT NOT NULL CHECK (tiebreaker_type IN ('coin_flip', 'lottery')),
  -- For coin_flip: 'heads'/'tails'; for lottery: index of winner in shuffled array
  result_seed TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_mystery_tiebreakers_auction ON public.mystery_tiebreakers(auction_id);

-- RLS: Anyone can read tiebreaker results (they're only created after auction ends)
ALTER TABLE public.mystery_tiebreakers ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view mystery tiebreakers" ON public.mystery_tiebreakers;
CREATE POLICY "Anyone can view mystery tiebreakers"
  ON public.mystery_tiebreakers FOR SELECT USING (true);

GRANT SELECT ON public.mystery_tiebreakers TO authenticated;

-- ========================================================================
-- 2. RPC: place_mystery_bid — sealed bid, one per user per auction
-- ========================================================================

CREATE OR REPLACE FUNCTION place_mystery_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_amount NUMERIC
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_existing_bid RECORD;
  v_min_bid NUMERIC;
BEGIN
  -- Validate auction exists, is live, and is mystery type
  SELECT a.*, s.status_name
  INTO v_auction
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

  IF v_auction IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction not found');
  END IF;

  IF v_auction.status_name != 'live' THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction is not active');
  END IF;

  IF v_auction.bidding_type != 'mystery' THEN
    RETURN json_build_object('success', FALSE, 'error', 'This is not a mystery auction');
  END IF;

  IF v_auction.end_time <= NOW() THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction has ended');
  END IF;

  -- Seller cannot bid on their own auction
  IF v_auction.seller_id = p_bidder_id THEN
    RETURN json_build_object('success', FALSE, 'error', 'Seller cannot bid on their own auction');
  END IF;

  -- Check if user has already placed a sealed bid
  SELECT * INTO v_existing_bid
  FROM bids
  WHERE auction_id = p_auction_id AND bidder_id = p_bidder_id;

  IF v_existing_bid IS NOT NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'You have already placed a sealed bid on this mystery auction. Only one bid is allowed.');
  END IF;

  -- Validate bid amount >= starting_price
  v_min_bid := v_auction.starting_price;
  IF p_amount < v_min_bid THEN
    RETURN json_build_object('success', FALSE, 'error',
      'Bid must be at least ₱' || v_min_bid::TEXT);
  END IF;

  -- Insert the sealed bid
  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, created_at)
  VALUES (p_auction_id, p_bidder_id, p_amount, FALSE, NOW());

  -- Update auction stats (total_bids count, but NOT current_price — sealed!)
  UPDATE auctions
  SET total_bids = total_bids + 1,
      updated_at = NOW()
  WHERE id = p_auction_id;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Your sealed bid has been placed successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION place_mystery_bid(UUID, UUID, NUMERIC) TO authenticated;

-- ========================================================================
-- 3. RPC: get_mystery_bid_status — returns user's bid + auction state
-- ========================================================================

CREATE OR REPLACE FUNCTION get_mystery_bid_status(
  p_auction_id UUID,
  p_user_id UUID
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_user_bid RECORD;
  v_all_bids JSON;
  v_tiebreaker JSON;
  v_is_seller BOOLEAN;
  v_seller_bids JSON;
  v_bid_count INT;
BEGIN
  -- Get auction info
  SELECT a.*, s.status_name
  INTO v_auction
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

  IF v_auction IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction not found');
  END IF;

  v_is_seller := (v_auction.seller_id = p_user_id);

  -- Get user's own bid (if any)
  SELECT * INTO v_user_bid
  FROM bids
  WHERE auction_id = p_auction_id AND bidder_id = p_user_id;

  -- Get total bid count
  SELECT COUNT(*) INTO v_bid_count FROM bids WHERE auction_id = p_auction_id;

  -- If seller: always show all bids (amounts only, no names for fairness during auction)
  IF v_is_seller THEN
    SELECT json_agg(row_to_json(t) ORDER BY t.bid_amount DESC)
    INTO v_seller_bids
    FROM (
      SELECT b.id, b.bid_amount, b.created_at, b.bidder_id
      FROM bids b
      WHERE b.auction_id = p_auction_id
      ORDER BY b.bid_amount DESC, b.created_at ASC
    ) t;
  END IF;

  -- Check if auction has ended
  IF v_auction.status_name IN ('sold', 'unsold', 'ended') OR v_auction.end_time <= NOW() THEN
    -- Auction ended: reveal all bids (with bidder_ids for alias generation, no real names)
    SELECT json_agg(row_to_json(t) ORDER BY t.bid_amount DESC)
    INTO v_all_bids
    FROM (
      SELECT b.id, b.bidder_id, b.bid_amount, b.created_at,
             bs.status_name AS bid_status
      FROM bids b
      LEFT JOIN bid_statuses bs ON b.status_id = bs.id
      WHERE b.auction_id = p_auction_id
      ORDER BY b.bid_amount DESC, b.created_at ASC
    ) t;

    -- Get tiebreaker result (if any)
    SELECT row_to_json(mt) INTO v_tiebreaker
    FROM mystery_tiebreakers mt
    WHERE mt.auction_id = p_auction_id;

    RETURN json_build_object(
      'success', TRUE,
      'auction_ended', TRUE,
      'has_bid', (v_user_bid IS NOT NULL),
      'user_bid_amount', CASE WHEN v_user_bid IS NOT NULL THEN v_user_bid.bid_amount ELSE NULL END,
      'bid_count', v_bid_count,
      'all_bids', COALESCE(v_all_bids, '[]'::JSON),
      'tiebreaker', v_tiebreaker,
      'is_seller', v_is_seller,
      'winner_id', CASE
        WHEN v_tiebreaker IS NOT NULL THEN (v_tiebreaker->>'winner_id')::UUID
        ELSE (SELECT bidder_id FROM bids WHERE auction_id = p_auction_id ORDER BY bid_amount DESC, created_at ASC LIMIT 1)
      END
    );
  ELSE
    -- Auction still live: return limited info
    RETURN json_build_object(
      'success', TRUE,
      'auction_ended', FALSE,
      'has_bid', (v_user_bid IS NOT NULL),
      'user_bid_amount', CASE WHEN v_user_bid IS NOT NULL THEN v_user_bid.bid_amount ELSE NULL END,
      'bid_count', v_bid_count,
      'is_seller', v_is_seller,
      'seller_bids', CASE WHEN v_is_seller THEN COALESCE(v_seller_bids, '[]'::JSON) ELSE NULL END
    );
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION get_mystery_bid_status(UUID, UUID) TO authenticated;

-- ========================================================================
-- 4. Update end_auction to handle mystery tiebreakers
-- ========================================================================

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

  -- Check if this is a mystery auction
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

      -- Mark winner
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
  ELSE
    -- Non-mystery: standard logic (highest bid, earliest timestamp)
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

-- ========================================================================
-- 5. Block place_bid and raise_hand for mystery auctions
-- ========================================================================

-- Update place_bid to reject mystery auctions
-- We wrap the existing function by adding a guard at the top
-- Since we can't easily modify the existing function body,
-- we add a trigger-based guard on the bids table instead.

CREATE OR REPLACE FUNCTION prevent_non_mystery_bid_on_mystery()
RETURNS TRIGGER AS $$
DECLARE
  v_bidding_type TEXT;
  v_bid_count INT;
BEGIN
  SELECT bidding_type INTO v_bidding_type FROM auctions WHERE id = NEW.auction_id;

  IF v_bidding_type = 'mystery' THEN
    -- Check if this insert came from place_mystery_bid (which is allowed)
    -- We identify it by checking if current_setting returns our flag
    IF current_setting('app.mystery_bid_allowed', TRUE) != 'true' THEN
      RAISE EXCEPTION 'Mystery auctions require using the sealed bid system. Use place_mystery_bid instead.';
    END IF;

    -- Enforce one-bid-per-user for mystery
    SELECT COUNT(*) INTO v_bid_count
    FROM bids
    WHERE auction_id = NEW.auction_id AND bidder_id = NEW.bidder_id;

    IF v_bid_count > 0 THEN
      RAISE EXCEPTION 'Only one sealed bid per mystery auction is allowed.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_prevent_non_mystery_bid ON bids;
CREATE TRIGGER trg_prevent_non_mystery_bid
  BEFORE INSERT ON bids
  FOR EACH ROW
  EXECUTE FUNCTION prevent_non_mystery_bid_on_mystery();

-- Update place_mystery_bid to set the flag before inserting
CREATE OR REPLACE FUNCTION place_mystery_bid(
  p_auction_id UUID,
  p_bidder_id UUID,
  p_amount NUMERIC
)
RETURNS JSON AS $$
DECLARE
  v_auction RECORD;
  v_existing_bid RECORD;
  v_min_bid NUMERIC;
BEGIN
  -- Validate auction exists, is live, and is mystery type
  SELECT a.*, s.status_name
  INTO v_auction
  FROM auctions a
  JOIN auction_statuses s ON a.status_id = s.id
  WHERE a.id = p_auction_id;

  IF v_auction IS NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction not found');
  END IF;

  IF v_auction.status_name != 'live' THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction is not active');
  END IF;

  IF v_auction.bidding_type != 'mystery' THEN
    RETURN json_build_object('success', FALSE, 'error', 'This is not a mystery auction');
  END IF;

  IF v_auction.end_time <= NOW() THEN
    RETURN json_build_object('success', FALSE, 'error', 'Auction has ended');
  END IF;

  IF v_auction.seller_id = p_bidder_id THEN
    RETURN json_build_object('success', FALSE, 'error', 'Seller cannot bid on their own auction');
  END IF;

  -- Check if user has already placed a sealed bid
  SELECT * INTO v_existing_bid
  FROM bids
  WHERE auction_id = p_auction_id AND bidder_id = p_bidder_id;

  IF v_existing_bid IS NOT NULL THEN
    RETURN json_build_object('success', FALSE, 'error', 'You have already placed a sealed bid on this mystery auction. Only one bid is allowed.');
  END IF;

  -- Validate bid amount >= starting_price
  v_min_bid := v_auction.starting_price;
  IF p_amount < v_min_bid THEN
    RETURN json_build_object('success', FALSE, 'error',
      'Bid must be at least ₱' || v_min_bid::TEXT);
  END IF;

  -- Set flag so the trigger allows this insert
  PERFORM set_config('app.mystery_bid_allowed', 'true', TRUE);

  -- Insert the sealed bid
  INSERT INTO bids (auction_id, bidder_id, bid_amount, is_auto_bid, created_at)
  VALUES (p_auction_id, p_bidder_id, p_amount, FALSE, NOW());

  -- Reset the flag
  PERFORM set_config('app.mystery_bid_allowed', 'false', TRUE);

  -- Update auction stats
  UPDATE auctions
  SET total_bids = total_bids + 1,
      updated_at = NOW()
  WHERE id = p_auction_id;

  RETURN json_build_object(
    'success', TRUE,
    'message', 'Your sealed bid has been placed successfully'
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', FALSE, 'error', SQLERRM);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================================================
-- 6. RLS for bids on mystery auctions
-- ========================================================================
-- During live mystery auctions, bidders can only see their own bids.
-- Seller can see all bids via the RPC (get_mystery_bid_status).
-- After auction ends, all bids are visible via the RPC.
-- The existing bids RLS is fine since we're using SECURITY DEFINER RPCs
-- to control access. No changes needed to existing policies.
