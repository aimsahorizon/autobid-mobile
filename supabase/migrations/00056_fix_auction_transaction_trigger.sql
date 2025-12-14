-- ============================================================================
-- Fix auction transaction trigger to use bidder_id (bids has bidder_id column)
-- ============================================================================

-- The previous trigger function selected bids.user_id, but the bids table uses
-- bidder_id. This caused runtime errors when moving auctions into the
-- in_transaction status. The corrected function now reads bidder_id and also
-- updates buyer_id/agreed_price on conflict.

CREATE OR REPLACE FUNCTION create_auction_transaction()
RETURNS TRIGGER AS $$
DECLARE
  v_highest_bid RECORD;
  v_in_transaction_status_id UUID;
BEGIN
  -- Cache the in_transaction status id (raises if missing to surface config issues)
  SELECT id INTO v_in_transaction_status_id
  FROM auction_statuses
  WHERE status_name = 'in_transaction';

  IF v_in_transaction_status_id IS NULL THEN
    RAISE EXCEPTION 'auction_statuses missing status_name=in_transaction';
  END IF;

  -- Only act when status moves to in_transaction
  IF NEW.status_id = v_in_transaction_status_id AND OLD.status_id IS DISTINCT FROM NEW.status_id THEN
    -- Pick highest bid (ties break by most recent)
    SELECT bidder_id, bid_amount
    INTO v_highest_bid
    FROM bids
    WHERE auction_id = NEW.id
    ORDER BY bid_amount DESC, created_at DESC
    LIMIT 1;

    -- Create or update transaction when a winning bid exists
    IF v_highest_bid.bidder_id IS NOT NULL THEN
      INSERT INTO auction_transactions (
        auction_id,
        seller_id,
        buyer_id,
        agreed_price,
        status,
        created_at,
        updated_at
      ) VALUES (
        NEW.id,
        NEW.seller_id,
        v_highest_bid.bidder_id,
        v_highest_bid.bid_amount,
        'in_transaction',
        NOW(),
        NOW()
      )
      ON CONFLICT (auction_id) DO UPDATE SET
        buyer_id = EXCLUDED.buyer_id,
        agreed_price = EXCLUDED.agreed_price,
        status = 'in_transaction',
        updated_at = NOW();
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- No trigger recreation needed; existing trigger calls create_auction_transaction().
-- ============================================================================
