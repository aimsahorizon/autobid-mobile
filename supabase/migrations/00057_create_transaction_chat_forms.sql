-- ============================================================================
-- AutoBid Mobile - Migration 00057: Create Transaction Chat & Forms Tables
-- ============================================================================
-- Creates tables for real-time chat and form submission between buyer/seller
-- ============================================================================

-- ============================================================================
-- 1. Create Transaction Chat Messages Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS transaction_chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES auction_transactions(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  sender_name TEXT NOT NULL,
  message TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'system', 'attachment')),
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for chat
CREATE INDEX idx_transaction_chat_transaction_id 
  ON transaction_chat_messages(transaction_id);
CREATE INDEX idx_transaction_chat_created_at 
  ON transaction_chat_messages(transaction_id, created_at);

-- ============================================================================
-- 2. Create Transaction Forms Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS transaction_forms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES auction_transactions(id) ON DELETE CASCADE,
  role TEXT NOT NULL CHECK (role IN ('seller', 'buyer')),
  status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'reviewed', 'changes_requested', 'confirmed')),
  
  -- Agreement details
  agreed_price NUMERIC(12, 2) NOT NULL,
  payment_method TEXT,
  delivery_date TIMESTAMPTZ,
  delivery_location TEXT,
  
  -- Legal checklist
  or_cr_verified BOOLEAN DEFAULT FALSE,
  deeds_of_sale_ready BOOLEAN DEFAULT FALSE,
  plate_number_confirmed BOOLEAN DEFAULT FALSE,
  registration_valid BOOLEAN DEFAULT FALSE,
  no_outstanding_loans BOOLEAN DEFAULT FALSE,
  mechanical_inspection_done BOOLEAN DEFAULT FALSE,
  
  -- Additional
  additional_terms TEXT,
  review_notes TEXT,
  
  -- Timestamps
  submitted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  -- Unique constraint: one form per role per transaction
  UNIQUE(transaction_id, role)
);

-- Index for forms
CREATE INDEX idx_transaction_forms_transaction_id 
  ON transaction_forms(transaction_id);

-- ============================================================================
-- 3. Create Transaction Timeline Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS transaction_timeline (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID NOT NULL REFERENCES auction_transactions(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN (
    'created', 'message_sent', 'form_submitted', 'form_reviewed',
    'form_confirmed', 'admin_submitted', 'admin_approved', 
    'delivery_started', 'delivery_completed', 'completed', 'cancelled'
  )),
  actor_id UUID REFERENCES users(id),
  actor_name TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for timeline
CREATE INDEX idx_transaction_timeline_transaction_id 
  ON transaction_timeline(transaction_id);
CREATE INDEX idx_transaction_timeline_created_at 
  ON transaction_timeline(transaction_id, created_at);

-- ============================================================================
-- 4. RLS Policies
-- ============================================================================

-- Chat Messages RLS
ALTER TABLE transaction_chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Transaction parties can view chat"
  ON transaction_chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_chat_messages.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

CREATE POLICY "Transaction parties can insert chat"
  ON transaction_chat_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_chat_messages.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

-- Forms RLS
ALTER TABLE transaction_forms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Transaction parties can view forms"
  ON transaction_forms FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_forms.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

CREATE POLICY "Sellers can manage seller forms"
  ON transaction_forms FOR ALL
  USING (
    role = 'seller' AND
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_forms.transaction_id
      AND t.seller_id = auth.uid()
    )
  );

CREATE POLICY "Buyers can manage buyer forms"
  ON transaction_forms FOR ALL
  USING (
    role = 'buyer' AND
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_forms.transaction_id
      AND t.buyer_id = auth.uid()
    )
  );

-- Timeline RLS
ALTER TABLE transaction_timeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Transaction parties can view timeline"
  ON transaction_timeline FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_timeline.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

CREATE POLICY "Transaction parties can insert timeline"
  ON transaction_timeline FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auction_transactions t
      WHERE t.id = transaction_timeline.transaction_id
      AND (t.seller_id = auth.uid() OR t.buyer_id = auth.uid())
    )
  );

-- ============================================================================
-- 5. Enable Realtime for Chat
-- ============================================================================

ALTER PUBLICATION supabase_realtime ADD TABLE transaction_chat_messages;

-- ============================================================================
-- 6. Helper function to get transaction by auction_id
-- ============================================================================

CREATE OR REPLACE FUNCTION get_transaction_by_auction(p_auction_id UUID)
RETURNS TABLE (
  id UUID,
  auction_id UUID,
  seller_id UUID,
  buyer_id UUID,
  agreed_price NUMERIC,
  status TEXT,
  seller_form_submitted BOOLEAN,
  buyer_form_submitted BOOLEAN,
  seller_confirmed BOOLEAN,
  buyer_confirmed BOOLEAN,
  admin_approved BOOLEAN,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  admin_approved_at TIMESTAMPTZ,
  car_name TEXT,
  car_image_url TEXT,
  seller_name TEXT,
  buyer_name TEXT
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT 
    t.id,
    t.auction_id,
    t.seller_id,
    t.buyer_id,
    t.agreed_price,
    t.status,
    t.seller_form_submitted,
    t.buyer_form_submitted,
    t.seller_confirmed,
    t.buyer_confirmed,
    t.admin_approved,
    t.created_at,
    t.updated_at,
    t.completed_at,
    t.admin_approved_at,
    COALESCE(v.brand || ' ' || v.model, a.title) AS car_name,
    (SELECT photo_url FROM auction_photos WHERE auction_id = t.auction_id AND is_primary = true LIMIT 1) AS car_image_url,
    seller.display_name AS seller_name,
    buyer.display_name AS buyer_name
  FROM auction_transactions t
  JOIN auctions a ON a.id = t.auction_id
  LEFT JOIN auction_vehicles v ON v.auction_id = t.auction_id
  LEFT JOIN users seller ON seller.id = t.seller_id
  LEFT JOIN users buyer ON buyer.id = t.buyer_id
  WHERE t.auction_id = p_auction_id
  LIMIT 1;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_transaction_by_auction TO authenticated;
