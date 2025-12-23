-- ============================================================================
-- AutoBid Mobile - Row Level Security (RLS) Policies
-- Default DENY, Explicit ALLOW pattern
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE bid_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE transaction_statuses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE auctions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_watchers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bids ENABLE ROW LEVEL SECURITY;
ALTER TABLE auto_bid_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE bid_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE deposits ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_review_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE auction_moderation ENABLE ROW LEVEL SECURITY;
ALTER TABLE reported_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_dashboard_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE feature_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_keys ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- LOOKUP TABLES (READ-ONLY for all authenticated users)
-- ============================================================================

-- Admin Roles (Super Admin only)
CREATE POLICY "Super admins can view admin roles"
  ON admin_roles FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- User Roles (Public read)
CREATE POLICY "Anyone can view user roles"
  ON user_roles FOR SELECT
  USING (TRUE);

-- KYC Statuses (Authenticated read)
CREATE POLICY "Authenticated users can view KYC statuses"
  ON kyc_statuses FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Auction Categories (Public read)
CREATE POLICY "Anyone can view active auction categories"
  ON auction_categories FOR SELECT
  USING (is_active = TRUE);

CREATE POLICY "Admins can manage auction categories"
  ON auction_categories FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

-- Auction Statuses (Authenticated read)
CREATE POLICY "Authenticated users can view auction statuses"
  ON auction_statuses FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Bid Statuses (Authenticated read)
CREATE POLICY "Authenticated users can view bid statuses"
  ON bid_statuses FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Transaction Types (Authenticated read)
CREATE POLICY "Authenticated users can view transaction types"
  ON transaction_types FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Transaction Statuses (Authenticated read)
CREATE POLICY "Authenticated users can view transaction statuses"
  ON transaction_statuses FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Payment Methods (Public read active only)
CREATE POLICY "Anyone can view active payment methods"
  ON payment_methods FOR SELECT
  USING (is_active = TRUE);

-- ============================================================================
-- USER TABLES
-- ============================================================================

-- Users
CREATE POLICY "Users can view their own profile"
  ON users FOR SELECT
  USING (id = auth.uid());

CREATE POLICY "Users can update their own profile"
  ON users FOR UPDATE
  USING (id = auth.uid());

CREATE POLICY "Admins can view all users"
  ON users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update users"
  ON users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- KYC Documents
CREATE POLICY "Users can view their own KYC documents"
  ON kyc_documents FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert their own KYC documents"
  ON kyc_documents FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all KYC documents"
  ON kyc_documents FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

CREATE POLICY "Admins can update KYC documents"
  ON kyc_documents FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- User Addresses
CREATE POLICY "Users can manage their own addresses"
  ON user_addresses FOR ALL
  USING (user_id = auth.uid());

-- User Preferences
CREATE POLICY "Users can manage their own preferences"
  ON user_preferences FOR ALL
  USING (user_id = auth.uid());

-- ============================================================================
-- AUCTION TABLES
-- ============================================================================

-- Auctions
CREATE POLICY "Anyone can view live auctions"
  ON auctions FOR SELECT
  USING (
    status_id IN (
      SELECT id FROM auction_statuses WHERE status_name IN ('live', 'scheduled', 'ended', 'sold')
    )
  );

CREATE POLICY "Sellers can view their own auctions"
  ON auctions FOR SELECT
  USING (seller_id = auth.uid());

CREATE POLICY "Sellers can create auctions"
  ON auctions FOR INSERT
  WITH CHECK (seller_id = auth.uid());

CREATE POLICY "Sellers can update their own draft auctions"
  ON auctions FOR UPDATE
  USING (
    seller_id = auth.uid() AND
    status_id IN (SELECT id FROM auction_statuses WHERE status_name = 'draft')
  );

CREATE POLICY "Admins can view all auctions"
  ON auctions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can update auctions"
  ON auctions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

-- Auction Images
CREATE POLICY "Anyone can view auction images"
  ON auction_images FOR SELECT
  USING (TRUE);

CREATE POLICY "Sellers can manage their auction images"
  ON auction_images FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM auctions WHERE id = auction_images.auction_id AND seller_id = auth.uid()
    )
  );

-- Auction Watchers
CREATE POLICY "Users can view watchers for auctions they watch"
  ON auction_watchers FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can watch auctions"
  ON auction_watchers FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can unwatch auctions"
  ON auction_watchers FOR DELETE
  USING (user_id = auth.uid());

-- ============================================================================
-- BIDDING TABLES
-- ============================================================================

-- Bids
CREATE POLICY "Bidders can view their own bids"
  ON bids FOR SELECT
  USING (bidder_id = auth.uid());

CREATE POLICY "Sellers can view bids on their auctions"
  ON bids FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auctions WHERE id = bids.auction_id AND seller_id = auth.uid()
    )
  );

CREATE POLICY "Users can place bids"
  ON bids FOR INSERT
  WITH CHECK (bidder_id = auth.uid());

CREATE POLICY "Admins can view all bids"
  ON bids FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

-- Auto Bid Settings
CREATE POLICY "Users can manage their auto-bid settings"
  ON auto_bid_settings FOR ALL
  USING (user_id = auth.uid());

-- Bid History
CREATE POLICY "Users can view their bid history"
  ON bid_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM bids WHERE id = bid_history.bid_id AND bidder_id = auth.uid()
    )
  );

-- ============================================================================
-- TRANSACTION TABLES
-- ============================================================================

-- Transactions
CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create transactions"
  ON transactions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all transactions"
  ON transactions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

CREATE POLICY "Admins can update transactions"
  ON transactions FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Deposits
CREATE POLICY "Users can view their own deposits"
  ON deposits FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can create deposits"
  ON deposits FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can view all deposits"
  ON deposits FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Payments
CREATE POLICY "Buyers can view their own payments"
  ON payments FOR SELECT
  USING (buyer_id = auth.uid());

CREATE POLICY "Sellers can view payments for their auctions"
  ON payments FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auctions WHERE id = payments.auction_id AND seller_id = auth.uid()
    )
  );

CREATE POLICY "Buyers can create payments"
  ON payments FOR INSERT
  WITH CHECK (buyer_id = auth.uid());

CREATE POLICY "Admins can manage payments"
  ON payments FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Seller Payouts
CREATE POLICY "Sellers can view their payouts"
  ON seller_payouts FOR SELECT
  USING (seller_id = auth.uid());

CREATE POLICY "Admins can manage payouts"
  ON seller_payouts FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- ============================================================================
-- Q&A TABLES
-- ============================================================================

-- Auction Questions
CREATE POLICY "Anyone can view questions on active auctions"
  ON auction_questions FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM auctions
      WHERE id = auction_questions.auction_id
      AND status_id IN (SELECT id FROM auction_statuses WHERE status_name IN ('live', 'scheduled'))
    )
  );

CREATE POLICY "Authenticated users can ask questions"
  ON auction_questions FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can view their own questions"
  ON auction_questions FOR SELECT
  USING (user_id = auth.uid());

-- Auction Answers
CREATE POLICY "Anyone can view answers"
  ON auction_answers FOR SELECT
  USING (TRUE);

CREATE POLICY "Sellers can answer questions on their auctions"
  ON auction_answers FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM auction_questions aq
      JOIN auctions a ON aq.auction_id = a.id
      WHERE aq.id = auction_answers.question_id AND a.seller_id = auth.uid()
    )
  );

-- ============================================================================
-- CHAT TABLES
-- ============================================================================

-- Chat Rooms
CREATE POLICY "Users can view their own chat rooms"
  ON chat_rooms FOR SELECT
  USING (buyer_id = auth.uid() OR seller_id = auth.uid());

CREATE POLICY "Users can create chat rooms"
  ON chat_rooms FOR INSERT
  WITH CHECK (buyer_id = auth.uid() OR seller_id = auth.uid());

-- Chat Messages
CREATE POLICY "Room participants can view messages"
  ON chat_messages FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = chat_messages.room_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

CREATE POLICY "Room participants can send messages"
  ON chat_messages FOR INSERT
  WITH CHECK (
    sender_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM chat_rooms
      WHERE id = chat_messages.room_id
      AND (buyer_id = auth.uid() OR seller_id = auth.uid())
    )
  );

CREATE POLICY "Users can update their sent messages"
  ON chat_messages FOR UPDATE
  USING (sender_id = auth.uid());

-- ============================================================================
-- NOTIFICATION TABLES
-- ============================================================================

-- Notification Types
CREATE POLICY "Authenticated users can view notification types"
  ON notification_types FOR SELECT
  USING (auth.uid() IS NOT NULL);

-- Notifications
CREATE POLICY "Users can view their own notifications"
  ON notifications FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can update their notifications"
  ON notifications FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "System can create notifications"
  ON notifications FOR INSERT
  WITH CHECK (TRUE);

-- ============================================================================
-- ADMIN TABLES
-- ============================================================================

-- Admin Users
CREATE POLICY "Admins can view admin users"
  ON admin_users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Super admins can manage admin users"
  ON admin_users FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Admin Audit Log
CREATE POLICY "Admins can view audit log"
  ON admin_audit_log FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

CREATE POLICY "System can insert audit log"
  ON admin_audit_log FOR INSERT
  WITH CHECK (TRUE);

-- KYC Review Queue
CREATE POLICY "Admins can view KYC review queue"
  ON kyc_review_queue FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

CREATE POLICY "Admins can manage KYC review queue"
  ON kyc_review_queue FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Auction Moderation
CREATE POLICY "Admins can view moderation records"
  ON auction_moderation FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Admins can create moderation records"
  ON auction_moderation FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid() AND id = moderator_id
    )
  );

-- Reported Content
CREATE POLICY "Users can report content"
  ON reported_content FOR INSERT
  WITH CHECK (reporter_id = auth.uid());

CREATE POLICY "Users can view their reports"
  ON reported_content FOR SELECT
  USING (reporter_id = auth.uid());

CREATE POLICY "Admins can manage reports"
  ON reported_content FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

-- Admin Dashboard Metrics
CREATE POLICY "Admins can view dashboard metrics"
  ON admin_dashboard_metrics FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users WHERE user_id = auth.uid()
    )
  );

-- ============================================================================
-- SYSTEM TABLES
-- ============================================================================

-- System Settings
CREATE POLICY "Public settings are viewable by all"
  ON system_settings FOR SELECT
  USING (is_public = TRUE);

CREATE POLICY "Admins can view all settings"
  ON system_settings FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

CREATE POLICY "Super admins can manage settings"
  ON system_settings FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- Feature Flags
CREATE POLICY "Authenticated users can view feature flags"
  ON feature_flags FOR SELECT
  USING (auth.uid() IS NOT NULL);

CREATE POLICY "Super admins can manage feature flags"
  ON feature_flags FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- API Keys
CREATE POLICY "Super admins can manage API keys"
  ON api_keys FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM admin_users au
      JOIN admin_roles ar ON au.role_id = ar.id
      WHERE au.user_id = auth.uid() AND ar.role_name = 'super_admin'
    )
  );

-- ============================================================================
-- END OF RLS POLICIES
-- ============================================================================
