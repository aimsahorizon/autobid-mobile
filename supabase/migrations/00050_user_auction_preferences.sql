-- Create table to persist per-auction user preferences (bid increment)
CREATE TABLE IF NOT EXISTS public.user_auction_preferences (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  auction_id uuid NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  bid_increment numeric NOT NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, auction_id)
);

-- Basic RLS: users can manage their own preferences
ALTER TABLE public.user_auction_preferences ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow select own prefs" ON public.user_auction_preferences
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "allow upsert own prefs" ON public.user_auction_preferences
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "allow update own prefs" ON public.user_auction_preferences
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
