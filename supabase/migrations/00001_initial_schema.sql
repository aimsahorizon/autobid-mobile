-- ============================================================================
-- AutoBid Mobile - Complete Database Schema
-- Created: 2025-12-07
-- PostgreSQL 15+ | Supabase
-- ============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- SECTION 1: CORE LOOKUP TABLES (No Dependencies)
-- ============================================================================

-- Admin Roles
CREATE TABLE admin_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_name TEXT UNIQUE NOT NULL CHECK (role_name IN ('super_admin', 'moderator')),
  display_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Roles
CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  role_name TEXT UNIQUE NOT NULL CHECK (role_name IN ('buyer', 'seller', 'both')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KYC Status
CREATE TABLE kyc_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  status_name TEXT UNIQUE NOT NULL CHECK (status_name IN ('pending', 'under_review', 'approved', 'rejected', 'expired')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auction Categories
CREATE TABLE auction_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_name TEXT UNIQUE NOT NULL,
  display_name TEXT NOT NULL,
  icon_url TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auction Status
CREATE TABLE auction_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  status_name TEXT UNIQUE NOT NULL CHECK (status_name IN ('draft', 'pending_approval', 'scheduled', 'live', 'ended', 'cancelled', 'sold', 'unsold')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bid Status
CREATE TABLE bid_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  status_name TEXT UNIQUE NOT NULL CHECK (status_name IN ('active', 'outbid', 'winning', 'won', 'lost', 'refunded')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transaction Types
CREATE TABLE transaction_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type_name TEXT UNIQUE NOT NULL CHECK (type_name IN ('deposit', 'bid', 'payment', 'refund', 'withdrawal', 'seller_payout')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Transaction Status
CREATE TABLE transaction_statuses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  status_name TEXT UNIQUE NOT NULL CHECK (status_name IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
  display_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payment Methods
CREATE TABLE payment_methods (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  method_name TEXT UNIQUE NOT NULL CHECK (method_name IN ('stripe', 'paymongo', 'gcash', 'maya', 'bank_transfer')),
  display_name TEXT NOT NULL,
  is_active BOOLEAN DEFAULT TRUE,
  config JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 2: USER & AUTH TABLES
-- ============================================================================

-- Users (extends Supabase auth.users)
CREATE TABLE users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  phone_encrypted BYTEA, -- pgcrypto encrypted
  full_name TEXT NOT NULL,
  date_of_birth_encrypted BYTEA, -- pgcrypto encrypted
  profile_image_url TEXT,
  role_id UUID REFERENCES user_roles(id) ON DELETE RESTRICT,
  is_verified BOOLEAN DEFAULT FALSE,
  is_active BOOLEAN DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- KYC Documents
CREATE TABLE kyc_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status_id UUID NOT NULL REFERENCES kyc_statuses(id) ON DELETE RESTRICT,
  national_id_vault_key UUID, -- References Supabase Vault
  selfie_url TEXT NOT NULL,
  document_type TEXT NOT NULL CHECK (document_type IN ('national_id', 'passport', 'drivers_license')),
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  rejection_reason TEXT,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Addresses
CREATE TABLE user_addresses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  address_line1 TEXT NOT NULL,
  address_line2 TEXT,
  city TEXT NOT NULL,
  province TEXT NOT NULL,
  postal_code TEXT NOT NULL,
  country TEXT DEFAULT 'Philippines',
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Preferences
CREATE TABLE user_preferences (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notifications_enabled BOOLEAN DEFAULT TRUE,
  email_notifications BOOLEAN DEFAULT TRUE,
  sms_notifications BOOLEAN DEFAULT FALSE,
  push_notifications BOOLEAN DEFAULT TRUE,
  language TEXT DEFAULT 'en',
  timezone TEXT DEFAULT 'Asia/Manila',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 3: AUCTION CORE TABLES
-- ============================================================================

-- Auctions
CREATE TABLE auctions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES auction_categories(id) ON DELETE RESTRICT,
  status_id UUID NOT NULL REFERENCES auction_statuses(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  starting_price NUMERIC(12, 2) NOT NULL CHECK (starting_price > 0),
  reserve_price NUMERIC(12, 2) CHECK (reserve_price IS NULL OR reserve_price >= starting_price),
  current_price NUMERIC(12, 2) DEFAULT 0,
  bid_increment NUMERIC(12, 2) NOT NULL CHECK (bid_increment > 0),
  deposit_amount NUMERIC(12, 2) NOT NULL CHECK (deposit_amount > 0),
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL CHECK (end_time > start_time),
  total_bids INTEGER DEFAULT 0,
  view_count INTEGER DEFAULT 0,
  is_featured BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

-- Auction Images
CREATE TABLE auction_images (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  image_url TEXT NOT NULL,
  display_order INTEGER DEFAULT 0,
  is_primary BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auction Watchers
CREATE TABLE auction_watchers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(auction_id, user_id)
);

-- ============================================================================
-- SECTION 4: BIDDING TABLES
-- ============================================================================

-- Bids
CREATE TABLE bids (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  bidder_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status_id UUID NOT NULL REFERENCES bid_statuses(id) ON DELETE RESTRICT,
  bid_amount NUMERIC(12, 2) NOT NULL CHECK (bid_amount > 0),
  is_auto_bid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auto Bid Settings
CREATE TABLE auto_bid_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  max_bid_amount NUMERIC(12, 2) NOT NULL CHECK (max_bid_amount > 0),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(auction_id, user_id)
);

-- Bid History (for audit trail)
CREATE TABLE bid_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  bid_id UUID NOT NULL REFERENCES bids(id) ON DELETE CASCADE,
  previous_status_id UUID REFERENCES bid_statuses(id) ON DELETE SET NULL,
  new_status_id UUID NOT NULL REFERENCES bid_statuses(id) ON DELETE RESTRICT,
  changed_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 5: TRANSACTION & PAYMENT TABLES
-- ============================================================================

-- Transactions
CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  auction_id UUID REFERENCES auctions(id) ON DELETE SET NULL,
  type_id UUID NOT NULL REFERENCES transaction_types(id) ON DELETE RESTRICT,
  status_id UUID NOT NULL REFERENCES transaction_statuses(id) ON DELETE RESTRICT,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  currency TEXT DEFAULT 'PHP',
  payment_method_id UUID REFERENCES payment_methods(id) ON DELETE SET NULL,
  external_transaction_id TEXT,
  metadata JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Deposits
CREATE TABLE deposits (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID UNIQUE NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  is_refunded BOOLEAN DEFAULT FALSE,
  refunded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Payments
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID UNIQUE NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  deposit_deduction NUMERIC(12, 2) DEFAULT 0,
  net_amount NUMERIC(12, 2) NOT NULL,
  payment_proof_url TEXT,
  verified_at TIMESTAMPTZ,
  verified_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seller Payouts
CREATE TABLE seller_payouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_id UUID UNIQUE NOT NULL REFERENCES transactions(id) ON DELETE CASCADE,
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  platform_fee NUMERIC(12, 2) DEFAULT 0,
  net_amount NUMERIC(12, 2) NOT NULL,
  payout_method TEXT,
  payout_details JSONB,
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 6: Q&A TABLES
-- ============================================================================

-- Auction Questions
CREATE TABLE auction_questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  is_answered BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auction Answers
CREATE TABLE auction_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  question_id UUID UNIQUE NOT NULL REFERENCES auction_questions(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  answer_text TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 7: CHAT & MESSAGING TABLES
-- ============================================================================

-- Chat Rooms
CREATE TABLE chat_rooms (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(auction_id, buyer_id, seller_id)
);

-- Chat Messages
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_text TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 8: NOTIFICATION TABLES
-- ============================================================================

-- Notification Types
CREATE TABLE notification_types (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type_name TEXT UNIQUE NOT NULL CHECK (type_name IN ('bid_placed', 'outbid', 'auction_won', 'auction_lost', 'auction_ending', 'payment_received', 'kyc_approved', 'kyc_rejected', 'message_received', 'auction_approved', 'auction_cancelled')),
  display_name TEXT NOT NULL,
  template TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type_id UUID NOT NULL REFERENCES notification_types(id) ON DELETE RESTRICT,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  data JSONB,
  is_read BOOLEAN DEFAULT FALSE,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- SECTION 9: ADMIN SYSTEM TABLES
-- ============================================================================

-- Admin Users
CREATE TABLE admin_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE RESTRICT,
  is_active BOOLEAN DEFAULT TRUE,
  created_by UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin Audit Log
CREATE TABLE admin_audit_log (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  admin_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id UUID,
  changes JSONB,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- KYC Review Queue
CREATE TABLE kyc_review_queue (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  kyc_document_id UUID UNIQUE NOT NULL REFERENCES kyc_documents(id) ON DELETE CASCADE,
  assigned_to UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  priority INTEGER DEFAULT 0,
  sla_deadline TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auction Moderation
CREATE TABLE auction_moderation (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  auction_id UUID NOT NULL REFERENCES auctions(id) ON DELETE CASCADE,
  moderator_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('approve', 'reject', 'flag', 'cancel')),
  reason TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reported Content
CREATE TABLE reported_content (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL CHECK (content_type IN ('auction', 'user', 'message')),
  content_id UUID NOT NULL,
  reason TEXT NOT NULL,
  description TEXT,
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved', 'dismissed')),
  reviewed_by UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Admin Dashboard Metrics (materialized view refresh)
CREATE TABLE admin_dashboard_metrics (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  metric_date DATE NOT NULL,
  total_users INTEGER DEFAULT 0,
  active_auctions INTEGER DEFAULT 0,
  total_bids INTEGER DEFAULT 0,
  total_revenue NUMERIC(12, 2) DEFAULT 0,
  pending_kyc INTEGER DEFAULT 0,
  pending_auctions INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(metric_date)
);

-- ============================================================================
-- SECTION 10: SYSTEM TABLES
-- ============================================================================

-- System Settings
CREATE TABLE system_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  setting_key TEXT UNIQUE NOT NULL,
  setting_value TEXT NOT NULL,
  data_type TEXT DEFAULT 'string' CHECK (data_type IN ('string', 'number', 'boolean', 'json')),
  description TEXT,
  is_public BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Feature Flags
CREATE TABLE feature_flags (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  flag_name TEXT UNIQUE NOT NULL,
  is_enabled BOOLEAN DEFAULT FALSE,
  description TEXT,
  rollout_percentage INTEGER DEFAULT 0 CHECK (rollout_percentage >= 0 AND rollout_percentage <= 100),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- API Keys (for integrations)
CREATE TABLE api_keys (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  key_name TEXT NOT NULL,
  key_hash TEXT UNIQUE NOT NULL,
  permissions JSONB,
  is_active BOOLEAN DEFAULT TRUE,
  expires_at TIMESTAMPTZ,
  created_by UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  last_used_at TIMESTAMPTZ
);

-- ============================================================================
-- SECTION 11: INDEXES FOR PERFORMANCE
-- ============================================================================

-- Users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role_id ON users(role_id);
CREATE INDEX idx_users_is_active ON users(is_active);

-- KYC Documents
CREATE INDEX idx_kyc_documents_user_id ON kyc_documents(user_id);
CREATE INDEX idx_kyc_documents_status_id ON kyc_documents(status_id);
CREATE INDEX idx_kyc_documents_submitted_at ON kyc_documents(submitted_at);

-- Auctions
CREATE INDEX idx_auctions_seller_id ON auctions(seller_id);
CREATE INDEX idx_auctions_category_id ON auctions(category_id);
CREATE INDEX idx_auctions_status_id ON auctions(status_id);
CREATE INDEX idx_auctions_start_time ON auctions(start_time);
CREATE INDEX idx_auctions_end_time ON auctions(end_time);
CREATE INDEX idx_auctions_is_featured ON auctions(is_featured);

-- Bids
CREATE INDEX idx_bids_auction_id ON bids(auction_id);
CREATE INDEX idx_bids_bidder_id ON bids(bidder_id);
CREATE INDEX idx_bids_status_id ON bids(status_id);
CREATE INDEX idx_bids_created_at ON bids(created_at);

-- Transactions
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_auction_id ON transactions(auction_id);
CREATE INDEX idx_transactions_type_id ON transactions(type_id);
CREATE INDEX idx_transactions_status_id ON transactions(status_id);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);

-- Notifications
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

-- Chat Messages
CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id);
CREATE INDEX idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- Admin Audit Log
CREATE INDEX idx_admin_audit_log_admin_id ON admin_audit_log(admin_id);
CREATE INDEX idx_admin_audit_log_resource_type ON admin_audit_log(resource_type);
CREATE INDEX idx_admin_audit_log_created_at ON admin_audit_log(created_at);

-- ============================================================================
-- SECTION 12: AUTO-UPDATE TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to tables with updated_at
CREATE TRIGGER set_updated_at BEFORE UPDATE ON admin_roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON auction_categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON payment_methods FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON kyc_documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON user_addresses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON user_preferences FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON auctions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON bids FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON auto_bid_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON transactions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON auction_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON auction_answers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON chat_rooms FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON admin_users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON kyc_review_queue FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON reported_content FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON system_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON feature_flags FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================
