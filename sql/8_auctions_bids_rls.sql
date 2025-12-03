-- ============================================================================
-- AUCTIONS AND BIDS RLS POLICIES
-- Simple policies for dev testing - not overly complex
-- ============================================================================

-- Enable RLS on auctions and bids tables
ALTER TABLE auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- AUCTIONS POLICIES
-- ============================================================================

-- Anyone can view active auctions
CREATE POLICY "Anyone can view active auctions"
ON auctions FOR SELECT
USING (status = 'active' AND end_time > NOW());

-- Authenticated users can create auctions
CREATE POLICY "Authenticated users can create auctions"
ON auctions FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = seller_id);

-- Sellers can update their own auctions
CREATE POLICY "Sellers can update own auctions"
ON auctions FOR UPDATE
TO authenticated
USING (auth.uid() = seller_id)
WITH CHECK (auth.uid() = seller_id);

-- Sellers can delete their own draft auctions
CREATE POLICY "Sellers can delete own draft auctions"
ON auctions FOR DELETE
TO authenticated
USING (auth.uid() = seller_id AND status = 'draft');

-- ============================================================================
-- BIDS POLICIES
-- ============================================================================

-- Authenticated users can view all bids
CREATE POLICY "Authenticated users can view bids"
ON bids FOR SELECT
TO authenticated
USING (true);

-- Authenticated users can place bids
CREATE POLICY "Authenticated users can place bids"
ON bids FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = bidder_id);

-- Users can view their own bids
CREATE POLICY "Users can view own bids"
ON bids FOR SELECT
USING (auth.uid() = bidder_id);

-- ============================================================================
-- POLICIES COMPLETE
-- RLS is now enabled with simple, functional policies
-- ============================================================================
