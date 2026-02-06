-- Enable Supabase Realtime on tables needed for live updates
-- Without this, postgres_changes events are not broadcast and 
-- .stream() / onPostgresChanges won't receive any updates.

-- Auctions table: used by browse page and auction detail for live price/status updates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'auctions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE auctions;
  END IF;
END $$;

-- Bids table: used by auction detail for live bid history updates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'bids'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE bids;
  END IF;
END $$;

-- Auction transactions table: used by transaction status pages for live updates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'auction_transactions'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE auction_transactions;
  END IF;
END $$;

-- Listing drafts table: used by lists module for live draft updates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'listing_drafts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE listing_drafts;
  END IF;
END $$;

-- Transaction forms table: used by transaction detail for live form status updates  
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'transaction_forms'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE transaction_forms;
  END IF;
END $$;
