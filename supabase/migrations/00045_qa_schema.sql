-- Q&A schema for auction questions and answers
-- Created on 2025-12-12

BEGIN;

-- Drop existing objects if they exist (to handle re-runs)
DROP VIEW IF EXISTS public.view_auction_qa CASCADE;
DROP TABLE IF EXISTS public.auction_question_likes;
DROP TABLE IF EXISTS public.auction_answers;
DROP TABLE IF EXISTS public.auction_questions;

-- Create auction_questions table
CREATE TABLE public.auction_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  auction_id uuid NOT NULL REFERENCES public.auctions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  category text NOT NULL CHECK (category IN (
    'general','condition','history','features','documents','price'
  )),
  question text NOT NULL CHECK (char_length(question) >= 3),
  created_at timestamptz NOT NULL DEFAULT now(),
  answered_at timestamptz,
  is_deleted boolean NOT NULL DEFAULT false
);

CREATE INDEX auction_questions_auction_idx ON public.auction_questions(auction_id);
CREATE INDEX auction_questions_created_idx ON public.auction_questions(created_at DESC);

-- Create auction_answers table
CREATE TABLE public.auction_answers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id uuid NOT NULL REFERENCES public.auction_questions(id) ON DELETE CASCADE,
  seller_id uuid NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  answer text NOT NULL CHECK (char_length(answer) >= 1),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX auction_answers_question_idx ON public.auction_answers(question_id);

-- Create auction_question_likes table
CREATE TABLE public.auction_question_likes (
  question_id uuid NOT NULL REFERENCES public.auction_questions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (question_id, user_id)
);

-- Create view to serve combined Q&A to the app
CREATE VIEW public.view_auction_qa AS
SELECT q.id,
       q.auction_id,
       q.user_id,
       q.category,
       q.question,
       q.created_at AS asked_at,
       q.answered_at,
       (SELECT answer FROM public.auction_answers WHERE question_id = q.id ORDER BY created_at DESC LIMIT 1) AS answer,
       (SELECT created_at FROM public.auction_answers WHERE question_id = q.id ORDER BY created_at DESC LIMIT 1) AS answered_created_at,
       (SELECT count(*) FROM public.auction_question_likes l WHERE l.question_id = q.id) AS likes_count,
       u.display_name,
       u.full_name
FROM public.auction_questions q
LEFT JOIN public.users u ON q.user_id = u.id
WHERE q.is_deleted = false;

-- Enable RLS
ALTER TABLE public.auction_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auction_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auction_question_likes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for auction_questions
CREATE POLICY auction_questions_select ON public.auction_questions
  FOR SELECT USING (true);
CREATE POLICY auction_questions_insert ON public.auction_questions
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY auction_questions_update ON public.auction_questions
  FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for auction_answers
CREATE POLICY auction_answers_select ON public.auction_answers
  FOR SELECT USING (true);
CREATE POLICY auction_answers_insert ON public.auction_answers
  FOR INSERT WITH CHECK (auth.uid() = seller_id);

-- Create RLS policies for auction_question_likes
CREATE POLICY auction_question_likes_select ON public.auction_question_likes
  FOR SELECT USING (true);
CREATE POLICY auction_question_likes_insert ON public.auction_question_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY auction_question_likes_delete ON public.auction_question_likes
  FOR DELETE USING (auth.uid() = user_id);

COMMIT;
