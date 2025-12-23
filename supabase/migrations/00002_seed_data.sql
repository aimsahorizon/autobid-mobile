-- ============================================================================
-- AutoBid Mobile - Seed Data
-- Initial lookup data and system configuration
-- ============================================================================

-- Admin Roles
INSERT INTO admin_roles (role_name, display_name, description) VALUES
('super_admin', 'Super Admin', 'Full system access - KYC, payments, reports, settings'),
('moderator', 'Moderator', 'Auction monitoring and content review');

-- User Roles
INSERT INTO user_roles (role_name, display_name) VALUES
('buyer', 'Buyer'),
('seller', 'Seller'),
('both', 'Buyer & Seller');

-- KYC Statuses
INSERT INTO kyc_statuses (status_name, display_name) VALUES
('pending', 'Pending'),
('under_review', 'Under Review'),
('approved', 'Approved'),
('rejected', 'Rejected'),
('expired', 'Expired');

-- Auction Categories
INSERT INTO auction_categories (category_name, display_name, icon_url, sort_order) VALUES
('electronics', 'Electronics', 'electronics.png', 1),
('vehicles', 'Vehicles', 'vehicles.png', 2),
('real_estate', 'Real Estate', 'real_estate.png', 3),
('art', 'Art & Collectibles', 'art.png', 4),
('jewelry', 'Jewelry & Watches', 'jewelry.png', 5),
('furniture', 'Furniture', 'furniture.png', 6),
('fashion', 'Fashion & Accessories', 'fashion.png', 7),
('sports', 'Sports & Outdoors', 'sports.png', 8),
('other', 'Other', 'other.png', 99);

-- Auction Statuses
INSERT INTO auction_statuses (status_name, display_name) VALUES
('draft', 'Draft'),
('pending_approval', 'Pending Approval'),
('scheduled', 'Scheduled'),
('live', 'Live'),
('ended', 'Ended'),
('cancelled', 'Cancelled'),
('sold', 'Sold'),
('unsold', 'Unsold');

-- Bid Statuses
INSERT INTO bid_statuses (status_name, display_name) VALUES
('active', 'Active'),
('outbid', 'Outbid'),
('winning', 'Winning'),
('won', 'Won'),
('lost', 'Lost'),
('refunded', 'Refunded');

-- Transaction Types
INSERT INTO transaction_types (type_name, display_name) VALUES
('deposit', 'Deposit'),
('bid', 'Bid'),
('payment', 'Payment'),
('refund', 'Refund'),
('withdrawal', 'Withdrawal'),
('seller_payout', 'Seller Payout');

-- Transaction Statuses
INSERT INTO transaction_statuses (status_name, display_name) VALUES
('pending', 'Pending'),
('processing', 'Processing'),
('completed', 'Completed'),
('failed', 'Failed'),
('cancelled', 'Cancelled'),
('refunded', 'Refunded');

-- Payment Methods
INSERT INTO payment_methods (method_name, display_name, is_active, config) VALUES
('stripe', 'Stripe', TRUE, '{"fee_percentage": 2.9, "fee_fixed": 30}'::jsonb),
('paymongo', 'PayMongo', TRUE, '{"fee_percentage": 3.5, "fee_fixed": 0}'::jsonb),
('gcash', 'GCash', TRUE, '{"fee_percentage": 2.0, "fee_fixed": 0}'::jsonb),
('maya', 'Maya', TRUE, '{"fee_percentage": 2.5, "fee_fixed": 0}'::jsonb),
('bank_transfer', 'Bank Transfer', TRUE, '{"fee_percentage": 0, "fee_fixed": 0}'::jsonb);

-- Notification Types
INSERT INTO notification_types (type_name, display_name, template) VALUES
('bid_placed', 'Bid Placed', 'Your bid of {amount} has been placed on {auction_title}'),
('outbid', 'Outbid', 'You have been outbid on {auction_title}. Current bid: {amount}'),
('auction_won', 'Auction Won', 'Congratulations! You won {auction_title} for {amount}'),
('auction_lost', 'Auction Lost', 'You lost the auction for {auction_title}'),
('auction_ending', 'Auction Ending Soon', '{auction_title} is ending in {time_remaining}'),
('payment_received', 'Payment Received', 'Payment of {amount} has been received'),
('kyc_approved', 'KYC Approved', 'Your KYC verification has been approved'),
('kyc_rejected', 'KYC Rejected', 'Your KYC verification was rejected. Reason: {reason}'),
('message_received', 'New Message', 'You have a new message from {sender}'),
('auction_approved', 'Auction Approved', 'Your auction {auction_title} has been approved'),
('auction_cancelled', 'Auction Cancelled', 'Auction {auction_title} has been cancelled');

-- System Settings
INSERT INTO system_settings (setting_key, setting_value, data_type, description, is_public) VALUES
('platform_fee_percentage', '5.0', 'number', 'Platform commission percentage', FALSE),
('min_deposit_percentage', '10.0', 'number', 'Minimum deposit as percentage of starting price', TRUE),
('kyc_expiry_days', '365', 'number', 'Days until KYC expires', FALSE),
('auction_min_duration_hours', '1', 'number', 'Minimum auction duration in hours', TRUE),
('auction_max_duration_days', '30', 'number', 'Maximum auction duration in days', TRUE),
('max_auto_bid_amount', '1000000', 'number', 'Maximum auto-bid amount in PHP', TRUE),
('sla_kyc_review_hours', '48', 'number', 'SLA for KYC review in hours', FALSE),
('sla_auction_approval_hours', '24', 'number', 'SLA for auction approval in hours', FALSE),
('maintenance_mode', 'false', 'boolean', 'Enable maintenance mode', TRUE),
('app_version', '1.0.0', 'string', 'Current app version', TRUE);

-- Feature Flags
INSERT INTO feature_flags (flag_name, is_enabled, description, rollout_percentage) VALUES
('auto_bidding', TRUE, 'Enable auto-bidding feature', 100),
('live_chat', TRUE, 'Enable live chat between buyers and sellers', 100),
('push_notifications', TRUE, 'Enable push notifications', 100),
('featured_auctions', TRUE, 'Enable featured auctions', 100),
('auction_reports', FALSE, 'Enable auction reporting feature', 0),
('multi_currency', FALSE, 'Enable multi-currency support', 0);

-- ============================================================================
-- END OF SEED DATA
-- ============================================================================
