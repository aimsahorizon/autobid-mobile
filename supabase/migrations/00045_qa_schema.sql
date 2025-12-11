-- Q&A schema for auction questions and answers
-- Created on 2025-12-12

BEGIN;

-- Enum-like constraint via CHECK for categories
CREATE TABLE IF NOT EXISTS public.auction_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id uuid NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  category text NOT NULL CHECK (category IN (
    'general','condition','history','features','documents','price'
  )),
  question text NOT NULL CHECK (char_length(question) >= 3),
  created_at timestamptz NOT NULL DEFAULT now(),
  answered_at timestamptz,
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX IF NOT EXISTS auction_questions_auction_idx ON public.auction_questions(auction_id);
CREATE INDEX IF NOT EXISTS auction_questions_created_idx ON public.auction_questions(created_at DESC);

CREATE TABLE IF NOT EXISTS public.auction_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.auction_questions(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE RESTRICT,
  answer text NOT NULL CHECK (char_length(answer) >= 1),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS auction_answers_question_idx ON public.auction_answers(question_id);

-- Likes table (optional but useful)
CREATE TABLE IF NOT EXISTS public.auction_question_likes (
  question_id uuid NOT NULL REFERENCES public.auction_questions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (question_id, user_id)
);

-- Convenience view to serve combined Q&A to the app
CREATE OR REPLACE VIEW public.view_auction_qa AS
SELECT q.id,
       q.auction_id,
       q.user_id,
       q.category,
       q.question,
       q.created_at AS asked_at,
       q.answered_at,
       COALESCE(a.answer, NULL) AS answer,
       a.created_at AS answered_created_at,
       (SELECT count(*) FROM public.auction_question_likes l WHERE l.question_id = q.id) AS likes_count
FROM public.auction_questions q
LEFT JOIN LATERAL (
  SELECT aa.answer, aa.created_at
  FROM public.auction_answers aa
  WHERE aa.question_id = q.id
  ORDER BY aa.created_at DESC
  LIMIT 1
) a ON true
WHERE q.is_deleted = false;

-- RLS policies: enable RLS and basic access controls
ALTER TABLE public.auction_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auction_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auction_question_likes ENABLE ROW LEVEL SECURITY;

-- Assuming auth.uid() matches profiles.id via JWT; adjust as needed.
CREATE POLICY auction_questions_select ON public.auction_questions
  FOR SELECT USING (true);
CREATE POLICY auction_questions_insert ON public.auction_questions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY auction_questions_update ON public.auction_questions
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY auction_answers_select ON public.auction_answers
  FOR SELECT USING (true);
-- Sellers (auction owner) can answer: require that seller_id = auth.uid()
CREATE POLICY auction_answers_insert ON public.auction_answers
  FOR INSERT WITH CHECK (auth.uid() = seller_id);

CREATE POLICY auction_question_likes_select ON public.auction_question_likes
  FOR SELECT USING (true);
CREATE POLICY auction_question_likes_insert ON public.auction_question_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY auction_question_likes_delete ON public.auction_question_likes
  FOR DELETE USING (auth.uid() = user_id);

COMMIT;
