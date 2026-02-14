-- Enable Supabase Realtime on transaction_chat_messages table
-- Required for live chat updates in transaction detail pages
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND tablename = 'transaction_chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE transaction_chat_messages;
  END IF;
END $$;
