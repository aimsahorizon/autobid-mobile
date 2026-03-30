-- Migration: Enable realtime for auction_invites table
-- Purpose: Allow buyers to receive real-time invite updates (new invites, status changes)
-- Gap #6 fix: auction_invites was not in supabase_realtime publication

-- Add auction_invites to supabase_realtime publication
DO $$
BEGIN
  -- Check if the table is already in the publication
  IF NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND tablename = 'auction_invites'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE auction_invites;
    RAISE NOTICE 'auction_invites added to supabase_realtime publication';
  ELSE
    RAISE NOTICE 'auction_invites already in supabase_realtime publication';
  END IF;
END $$;

-- Enable REPLICA IDENTITY FULL for proper UPDATE/DELETE change detection
ALTER TABLE auction_invites REPLICA IDENTITY FULL;
