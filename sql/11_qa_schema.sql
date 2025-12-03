-- ============================================================================
-- Q&A (Questions & Answers) SCHEMA FOR LISTINGS
-- Allows buyers to ask questions about auction listings
-- ============================================================================

-- Drop existing table if exists
DROP TABLE IF EXISTS listing_questions CASCADE;

-- Create listing_questions table
CREATE TABLE listing_questions (
  -- Primary identifier
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- References
  listing_id UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
  asker_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Question content
  question TEXT NOT NULL CHECK (length(question) > 0),
  category TEXT NOT NULL DEFAULT 'general' CHECK (category IN ('general', 'condition', 'history', 'features', 'documents', 'price')),

  -- Answer content (NULL until answered)
  answer TEXT,
  answered_at TIMESTAMPTZ,

  -- Interaction tracking
  likes_count INTEGER NOT NULL DEFAULT 0 CHECK (likes_count >= 0),

  -- Visibility
  is_public BOOLEAN NOT NULL DEFAULT TRUE,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create table for tracking question likes
CREATE TABLE listing_question_likes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question_id UUID NOT NULL REFERENCES listing_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Prevent duplicate likes
  UNIQUE(question_id, user_id)
);

-- ============================================================================
-- INDEXES for performance
-- ============================================================================

CREATE INDEX idx_listing_questions_listing ON listing_questions(listing_id);
CREATE INDEX idx_listing_questions_asker ON listing_questions(asker_id);
CREATE INDEX idx_listing_questions_created ON listing_questions(created_at DESC);
CREATE INDEX idx_listing_questions_public ON listing_questions(listing_id, is_public) WHERE is_public = true;

CREATE INDEX idx_question_likes_question ON listing_question_likes(question_id);
CREATE INDEX idx_question_likes_user ON listing_question_likes(user_id);

-- ============================================================================
-- AUTO-UPDATE updated_at timestamp
-- ============================================================================

CREATE TRIGGER set_listing_questions_updated_at
BEFORE UPDATE ON listing_questions
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

-- ============================================================================
-- FUNCTION: Update likes count when like is added/removed
-- ============================================================================

CREATE OR REPLACE FUNCTION update_question_likes_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE listing_questions
    SET likes_count = likes_count + 1
    WHERE id = NEW.question_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE listing_questions
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.question_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update likes count
CREATE TRIGGER after_question_like_change
AFTER INSERT OR DELETE ON listing_question_likes
FOR EACH ROW
EXECUTE FUNCTION update_question_likes_count();

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE listing_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE listing_question_likes ENABLE ROW LEVEL SECURITY;

-- Anyone can view public questions
CREATE POLICY "Anyone can view public questions"
ON listing_questions FOR SELECT
USING (is_public = true);

-- Authenticated users can ask questions
CREATE POLICY "Authenticated users can ask questions"
ON listing_questions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = asker_id);

-- Askers can view their own questions (even private)
CREATE POLICY "Askers can view own questions"
ON listing_questions FOR SELECT
TO authenticated
USING (auth.uid() = asker_id);

-- Sellers can view all questions on their listings
CREATE POLICY "Sellers can view questions on their listings"
ON listing_questions FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM listings l
    WHERE l.id = listing_questions.listing_id
    AND l.seller_id = auth.uid()
  )
);

-- Sellers can answer questions on their listings
CREATE POLICY "Sellers can answer their listing questions"
ON listing_questions FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM listings l
    WHERE l.id = listing_questions.listing_id
    AND l.seller_id = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM listings l
    WHERE l.id = listing_questions.listing_id
    AND l.seller_id = auth.uid()
  )
);

-- Authenticated users can like questions
CREATE POLICY "Authenticated users can like questions"
ON listing_question_likes FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- Users can remove their own likes
CREATE POLICY "Users can remove own likes"
ON listing_question_likes FOR DELETE
TO authenticated
USING (auth.uid() = user_id);

-- Users can view all likes (to check if they liked)
CREATE POLICY "Users can view likes"
ON listing_question_likes FOR SELECT
TO authenticated
USING (true);

-- ============================================================================
-- HELPER FUNCTION: Get questions with user like status
-- ============================================================================

CREATE OR REPLACE FUNCTION get_listing_questions_with_likes(
  p_listing_id UUID,
  p_user_id UUID DEFAULT NULL
)
RETURNS TABLE (
  id UUID,
  listing_id UUID,
  asker_id UUID,
  question TEXT,
  category TEXT,
  answer TEXT,
  answered_at TIMESTAMPTZ,
  likes_count INTEGER,
  is_public BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  user_has_liked BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    lq.id,
    lq.listing_id,
    lq.asker_id,
    lq.question,
    lq.category,
    lq.answer,
    lq.answered_at,
    lq.likes_count,
    lq.is_public,
    lq.created_at,
    lq.updated_at,
    CASE
      WHEN p_user_id IS NULL THEN false
      ELSE EXISTS (
        SELECT 1 FROM listing_question_likes lql
        WHERE lql.question_id = lq.id
        AND lql.user_id = p_user_id
      )
    END as user_has_liked
  FROM listing_questions lq
  WHERE lq.listing_id = p_listing_id
  AND lq.is_public = true
  ORDER BY lq.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Q&A SCHEMA COMPLETE
-- ============================================================================

/*
USAGE EXAMPLES:

-- Ask a question
INSERT INTO listing_questions (listing_id, asker_id, question, category)
VALUES ('listing-uuid', auth.uid(), 'What is the mileage?', 'condition');

-- Answer a question (seller only)
UPDATE listing_questions
SET answer = 'The mileage is 50,000 km', answered_at = NOW()
WHERE id = 'question-uuid';

-- Like a question
INSERT INTO listing_question_likes (question_id, user_id)
VALUES ('question-uuid', auth.uid());

-- Get questions with like status
SELECT * FROM get_listing_questions_with_likes('listing-uuid', auth.uid());
*/
