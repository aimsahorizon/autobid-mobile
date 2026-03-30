-- Auction Aliases: Random per-auction identity for all participants
-- Both sellers and buyers get a unique alias per auction to hide real display names.

CREATE TABLE IF NOT EXISTS public.auction_aliases (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  auction_id  UUID NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  alias       TEXT NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT now(),
  UNIQUE(auction_id, user_id)
);

ALTER TABLE public.auction_aliases ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can read aliases (they are anonymized by design)
CREATE POLICY auction_aliases_select ON public.auction_aliases
  FOR SELECT USING (true);

-- Only the system function can insert (SECURITY DEFINER)
CREATE POLICY auction_aliases_insert ON public.auction_aliases
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Function: deterministically assign an alias for a user in an auction
CREATE OR REPLACE FUNCTION public.assign_auction_alias(
  p_auction_id UUID,
  p_user_id    UUID
) RETURNS TEXT
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_alias TEXT;
  v_adjectives TEXT[] := ARRAY[
    'Swift','Bold','Clever','Brave','Noble','Lucky','Keen','Calm','Wise','Bright',
    'Rapid','Steady','Sharp','Fierce','Quick','Silent','Mystic','Phantom','Shadow','Crimson',
    'Golden','Silver','Iron','Crystal','Storm','Thunder','Frost','Blaze','Dusk','Dawn'
  ];
  v_animals TEXT[] := ARRAY[
    'Eagle','Tiger','Falcon','Wolf','Bear','Hawk','Fox','Lion','Panther','Viper',
    'Stallion','Cobra','Raven','Phoenix','Dragon','Shark','Bison','Lynx','Jaguar','Condor',
    'Mustang','Puma','Osprey','Raptor','Gorilla','Rhino','Cheetah','Orca','Mantis','Griffin'
  ];
  v_hash  INT;
  v_hash2 INT;
  v_adj   TEXT;
  v_animal TEXT;
  v_candidate TEXT;
BEGIN
  -- Return existing alias if already assigned
  SELECT alias INTO v_alias
    FROM public.auction_aliases
   WHERE auction_id = p_auction_id AND user_id = p_user_id;
  IF v_alias IS NOT NULL THEN
    RETURN v_alias;
  END IF;

  -- Deterministic hash from concatenation of IDs
  v_hash  := abs(hashtext(p_auction_id::text || ':' || p_user_id::text));
  v_hash2 := abs(hashtext(p_user_id::text || ':' || p_auction_id::text));

  v_adj    := v_adjectives[1 + (v_hash  % array_length(v_adjectives, 1))];
  v_animal := v_animals   [1 + (v_hash2 % array_length(v_animals, 1))];
  v_candidate := v_adj || ' ' || v_animal;

  -- Handle rare collision within same auction
  IF EXISTS (
    SELECT 1 FROM public.auction_aliases
     WHERE auction_id = p_auction_id AND alias = v_candidate
  ) THEN
    v_candidate := v_candidate || ' ' ||
      (SELECT count(*)::text FROM public.auction_aliases WHERE auction_id = p_auction_id);
  END IF;

  INSERT INTO public.auction_aliases (auction_id, user_id, alias)
  VALUES (p_auction_id, p_user_id, v_candidate)
  ON CONFLICT (auction_id, user_id) DO NOTHING;

  -- Re-read to handle race conditions
  SELECT alias INTO v_alias
    FROM public.auction_aliases
   WHERE auction_id = p_auction_id AND user_id = p_user_id;

  RETURN v_alias;
END;
$$;

-- Batch fetch: return all aliases for an auction
CREATE OR REPLACE FUNCTION public.get_auction_aliases(p_auction_id UUID)
RETURNS TABLE(user_id UUID, alias TEXT)
LANGUAGE sql STABLE SECURITY DEFINER AS $$
  SELECT aa.user_id, aa.alias
    FROM public.auction_aliases aa
   WHERE aa.auction_id = p_auction_id;
$$;

-- Auto-assign alias when a bid is placed
CREATE OR REPLACE FUNCTION public.trg_assign_alias_on_bid()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM public.assign_auction_alias(NEW.auction_id, NEW.bidder_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS assign_alias_on_bid ON public.bids;
CREATE TRIGGER assign_alias_on_bid
  AFTER INSERT ON public.bids
  FOR EACH ROW EXECUTE FUNCTION public.trg_assign_alias_on_bid();

-- Auto-assign alias when a question is asked
CREATE OR REPLACE FUNCTION public.trg_assign_alias_on_question()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  PERFORM public.assign_auction_alias(NEW.auction_id, NEW.user_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS assign_alias_on_question ON public.auction_questions;
CREATE TRIGGER assign_alias_on_question
  AFTER INSERT ON public.auction_questions
  FOR EACH ROW EXECUTE FUNCTION public.trg_assign_alias_on_question();

-- Auto-assign alias when an answer is posted (seller)
CREATE OR REPLACE FUNCTION public.trg_assign_alias_on_answer()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE
  v_auction_id UUID;
BEGIN
  SELECT auction_id INTO v_auction_id
    FROM public.auction_questions
   WHERE id = NEW.question_id;
  IF v_auction_id IS NOT NULL THEN
    PERFORM public.assign_auction_alias(v_auction_id, NEW.seller_id);
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS assign_alias_on_answer ON public.auction_answers;
CREATE TRIGGER assign_alias_on_answer
  AFTER INSERT ON public.auction_answers
  FOR EACH ROW EXECUTE FUNCTION public.trg_assign_alias_on_answer();
