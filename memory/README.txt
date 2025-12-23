================================================================================
AUTOBID MOBILE - MEMORY DIRECTORY
================================================================================
Database Schema & Implementation Reference
Complete documentation for fresh database rebuild with 3NF normalization
================================================================================

PURPOSE:
This directory contains comprehensive documentation for rebuilding the AutoBid
Mobile database from scratch with proper normalization, encryption, and admin
functionality. Use these documents as the single source of truth for database
implementation.

================================================================================
DOCUMENT INDEX
================================================================================

1. IMPLEMENTATION_REFERENCE.txt ⭐ START HERE
   - Master implementation guide
   - Complete overview of all tables, features, and requirements
   - Implementation checklist (100+ items)
   - Migration strategy with phase breakdown
   - Performance optimization guidelines
   - Security best practices
   - Support and maintenance procedures

   USE FOR: Understanding the full system, planning implementation

2. database_schema.txt 📊 PRIMARY REFERENCE
   - Complete 3NF normalized schema (51 tables)
   - All column definitions with data types and constraints
   - All foreign key relationships
   - Index strategy (primary, composite, partial, GIN)
   - RLS policy specifications
   - Triggers and automation
   - Storage buckets configuration
   - RPC functions (30+)
   - Materialized views
   - Migration notes from current schema

   USE FOR: Creating tables, setting up constraints, writing SQL

3. data_encryption_guidelines.txt 🔐 SECURITY REFERENCE
   - 3-layer encryption strategy (Vault, pgcrypto, app-level)
   - Field-by-field encryption classification
   - Supabase Vault implementation for national IDs
   - pgcrypto implementation for phone/DOB
   - Application-level AES-256-GCM for KYC photos
   - Key management and rotation procedures
   - RLS policies for encrypted data
   - Compliance (GDPR, Philippine Data Privacy Act 2012)
   - Encryption audit logging
   - Performance considerations
   - Testing and validation procedures
   - Flutter/Dart code examples

   USE FOR: Implementing encryption, security compliance, audit logging

4. admin_system_requirements.txt 👨‍💼 ADMIN MODULE REFERENCE
   - Complete admin functionality specification
   - 2 admin roles: Super Admin and Moderator
   - Permission matrix (RBAC)
   - Dashboard with real-time metrics (30s refresh)
   - KYC review system (document viewer, SLA tracking)
   - Auction live monitoring (final 2-minute alerts)
   - Financial management (payment verification, refunds)
   - User management (editing, suspension, impersonation)
   - Support ticket system (SLA tracking, templates)
   - Content moderation (listing review, AI detection)
   - Dispute resolution workflows
   - System settings configuration
   - Audit log and activity tracking
   - Notification center (alerts, digests)

   USE FOR: Building admin dashboard, implementing admin workflows

5. nextjs_admin_portal_guide.txt 🌐 NEXT.JS WEB PORTAL GUIDE
   - Next.js 14+ App Router architecture
   - Unified admin portal for 2 roles (Super Admin, Moderator)
   - Role-based access control (RBAC) implementation
   - Supabase authentication and authorization
   - Real-time features (auction monitoring, notifications)
   - API routes with permission checks
   - Sidebar navigation (role-based filtering)
   - Component structure and examples
   - Deployment guide (Vercel)
   - Security best practices

   USE FOR: Building Next.js web admin portal for desktop use

================================================================================
QUICK START GUIDE
================================================================================

STEP 1: READ IMPLEMENTATION_REFERENCE.txt
- Understand the complete system architecture
- Review the 51-table schema overview
- Understand normalization improvements (1.5NF → 3NF)
- Review encryption strategy overview
- Review admin role permissions

STEP 2: REVIEW database_schema.txt
- Study each section (Authentication, Vehicles, Auctions, etc.)
- Note all table relationships (foreign keys)
- Note all constraints (CHECK, UNIQUE, NOT NULL)
- Note all indexes required
- Note all RLS policies

STEP 3: REVIEW data_encryption_guidelines.txt
- Understand which fields require encryption (HIGH/MEDIUM/LOW priority)
- Review Supabase Vault setup for national IDs
- Review pgcrypto setup for phone numbers
- Review file encryption for KYC documents
- Plan key management strategy

STEP 4: REVIEW admin_system_requirements.txt
- Understand admin role hierarchy (5 roles)
- Review dashboard requirements (metrics, charts, alerts)
- Review KYC review workflow
- Review auction monitoring requirements
- Review financial management workflows

STEP 5: IMPLEMENT
Follow the implementation checklist in IMPLEMENTATION_REFERENCE.txt:
□ Database Setup (51 tables, indexes, RLS, triggers)
□ Encryption Setup (Vault, pgcrypto, file encryption)
□ Admin System Setup (roles, permissions, dashboard)
□ Flutter App Integration (datasources, entities, repositories)
□ Testing (unit, integration, security, performance)
□ Deployment (migration, monitoring, validation)

================================================================================
KEY STATISTICS
================================================================================

TOTAL TABLES: 51 (3NF normalized)
  - 35 application tables
  - 16 admin system tables

APPLICATION TABLES BREAKDOWN:
  - 3 authentication/user tables (auth.users, addresses, users)
  - 6 vehicle/listing tables (car_brands, car_models, listing_drafts, listing_photos, listing_documents, listing_features)
  - 6 auction/bidding tables (auctions, auction_participants, bids, auction_deposits, watchlist, auction_questions)
  - 4 transaction tables (transactions, transaction_forms, transaction_messages, transaction_timeline)
  - 5 payment/token tables (user_token_balances, user_subscriptions, token_packages, token_transactions, payment_transactions)
  - 4 support tables (support_categories, support_tickets, support_ticket_messages, support_ticket_attachments)
  - 1 notification table (notifications)
  - 2 AI feature tables (ai_photo_analysis, ai_price_recommendations)
  - 4 auto-bidding tables (auto_bid_configs, auto_bid_history, bidding_strategies, bid_alerts)

ADMIN TABLES: 16
  - 3 RBAC tables (admin_roles, admin_permissions, admin_role_permissions)
  - 2 admin user tables (admin_users, admin_sessions)
  - 2 audit log tables (admin_audit_log, encryption_audit_log)
  - 5 operational tables (admin_auction_monitoring, admin_kyc_review_queue, admin_payment_verification_queue, admin_notifications, admin_activity_summary)
  - 2 reporting tables (admin_dashboard_metrics, admin_reports)
  - 2 system tables (encryption_keys, system_settings)

STORAGE BUCKETS: 6
  - kyc-documents (encrypted KYC photos/documents)
  - listing-photos (vehicle photos for auctions)
  - listing-documents (vehicle documents, deed of sale)
  - profile-photos (user profile and cover photos)
  - support-attachments (support ticket attachments)
  - admin-reports (generated PDF/CSV/Excel reports)

RPC FUNCTIONS: 30+
  - 6 encryption functions (Vault store/retrieve, pgcrypto encrypt/decrypt)
  - 8 auction functions (place_bid, get_auction_status, check_snipe_guard, etc.)
  - 4 transaction functions (create_transaction, submit_form, send_message, etc.)
  - 4 payment functions (verify_payment, process_refund, consume_tokens, etc.)
  - 4 admin functions (assign_kyc_review, flag_auction, generate_report, etc.)
  - 4 utility functions (calculate_time_remaining, check_reserve_met, etc.)

MATERIALIZED VIEWS: 2
  - auction_stats_by_category (revenue, bid counts by category)
  - user_activity_summary (login counts, bid counts, transaction counts)

INDEXES: 150+
  - Primary key indexes (51 tables)
  - Foreign key indexes (100+ foreign keys)
  - Composite indexes (20+ for complex queries)
  - Partial indexes (10+ for status-based queries)
  - GIN indexes (5+ for JSONB and array searches)
  - Text search indexes (2 for full-text search)

TRIGGERS: 20+
  - auto_update_updated_at (on all tables with updated_at)
  - Denormalized counter maintenance (bid_count, token_balance)
  - Auto-priority KYC queue (days_pending > 7)
  - Auto-SLA breach tracking (payment queue > 24h, KYC queue > 2d)
  - Auction monitoring automation (time_remaining, final_2_minutes)
  - Admin notification generation (auction alerts, queue alerts)
  - Audit logging triggers (Vault access, admin actions)
  - Soft delete triggers (deleted_at timestamp)

================================================================================
ENCRYPTION SUMMARY
================================================================================

FIELDS ENCRYPTED:
✅ national_id_number (Supabase Vault)
✅ secondary_gov_id_number (Supabase Vault)
✅ phone_number (pgcrypto with hash for lookup)
✅ date_of_birth (pgcrypto with birth_year for age calc)
✅ National ID photos - front/back (AES-256-GCM file encryption)
✅ Secondary ID photos - front/back (AES-256-GCM file encryption)
✅ Selfie with ID photo (AES-256-GCM file encryption)
✅ Proof of address document (AES-256-GCM file encryption)

ENCRYPTION METHODS:
1. Supabase Vault (AES-256, Supabase-managed keys)
   - national_id_number, secondary_gov_id_number
   - Access via RPC functions with audit logging

2. pgcrypto Extension (Searchable encryption)
   - phone_number (bytea + hash for exact match)
   - date_of_birth (bytea + birth_year integer)
   - Access via decrypt functions

3. Application-level AES-256-GCM (User-specific keys)
   - All KYC photo/document files
   - Encrypt before upload, decrypt on download
   - Key derived from master key + user ID

COMPLIANCE:
✅ Philippine Data Privacy Act 2012 (Section 20)
✅ GDPR Article 32 (if applicable)
✅ Encryption audit logging (7-year retention)
✅ Key rotation mechanism (annual recommended)
✅ Right to erasure (vault.delete_secret)
✅ Right to access (decryption available)

================================================================================
ADMIN ROLES SUMMARY
================================================================================

SUPER_ADMIN (Full Access):
- User management (create/delete admins and moderators)
- KYC review and approval
- Auction monitoring and management
- Payment verification and refunds
- User support tickets
- Content moderation
- Dispute resolution
- Financial reports and analytics
- Token package management
- System configuration
- Database management
- Audit log access

MODERATOR (Limited Access):
- Auction monitoring (real-time)
- Content review (listings/descriptions)
- Flag inappropriate content
- Flag suspicious auctions
- Monitor Q&A and transaction chats
- Limited read-only access

================================================================================
THESIS DEFENSE ENHANCEMENTS IMPLEMENTED
================================================================================

✅ Minimum bid increment (per auction configuration)
✅ Rebid/next bidder option (offer_to_next_bidder flag)
✅ Incremental bidding below $500k (configurable thresholds)
✅ Private vs public bidding (bidding_type + auction_participants)
✅ Snipe guard / bid delay seconds (snipe_guard_seconds, auto-extends timer)
✅ Separate photo vs document uploads (listing_photos, listing_documents)
✅ Deed of sale document generation (transaction_forms, listing_documents)
✅ Vehicle history fields:
   - insurance_status, insurance_expiry_date
   - maintenance_history (JSONB array)
   - damage_history (JSONB array)
   - past_condition, current_condition
✅ Admin monitoring dashboard (admin_dashboard_metrics, 30s refresh)
✅ Moving timer on monitoring (time_remaining_seconds, updated every 10s)
✅ Final 2-minute moderator notifications (admin_notifications + alerts)
✅ Highlight highest bid visibility (current_highest_bid tracking)
✅ Bid status management (active, outbid, winning, won, lost, cancelled)
✅ AI photo-based keyword suggestions (ai_photo_analysis table)
✅ AI auto-fill data from photo scan (OCR integration)
✅ AI starting/reserve price recommendations (ai_price_recommendations)

================================================================================
NORMALIZATION IMPROVEMENTS (1.5NF → 3NF)
================================================================================

FIRST NORMAL FORM (1NF) VIOLATIONS FIXED:
❌ photo_urls JSONB (repeating groups)
✅ listing_photos table (one photo per row)

❌ features TEXT[] (repeating groups)
✅ listing_features table (one feature per row)

THIRD NORMAL FORM (3NF) VIOLATIONS FIXED:
❌ Address fields denormalized in users table (city, province, region)
✅ addresses table (normalized location hierarchy)

❌ Car brand/model denormalized in listings
✅ car_brands + car_models tables (brand → model hierarchy)

CONSOLIDATION:
❌ Redundant tables: vehicles, listings, auctions
✅ Merged into: listing_drafts + auctions

❌ Redundant tables: users, user_profiles
✅ Merged into: users

❌ Duplicate bids table definitions
✅ Consolidated into: bids

STRATEGIC DENORMALIZATION (Performance):
✅ bid_count, active_bidders_count cached in auctions (updated via triggers)
✅ token_balance cached in user_token_balances (updated via triggers)
✅ Materialized views for heavy reporting queries

================================================================================
REALTIME FEATURES (Supabase Realtime)
================================================================================

1. AUCTION BIDDING:
   - Subscribe to auctions table WHERE auction_id = :id
   - Updates: current_highest_bid, bid_count, time_remaining
   - Live for all watchers/bidders

2. TRANSACTION CHAT:
   - Subscribe to transaction_messages WHERE transaction_id = :id
   - Real-time chat between buyer and seller
   - Typing indicators, read receipts

3. ADMIN AUCTION MONITORING:
   - Subscribe to admin_auction_monitoring WHERE is_final_two_minutes = true
   - Real-time alerts for moderators
   - Auto-refresh every 10 seconds

4. ADMIN NOTIFICATIONS:
   - Subscribe to admin_notifications WHERE admin_id = :id AND is_read = false
   - Push notifications to admin dashboard
   - Auto-dismiss after 30 days if read

5. USER NOTIFICATIONS:
   - Subscribe to notifications WHERE user_id = :id AND is_read = false
   - Auction win, outbid, transaction updates
   - Real-time delivery

================================================================================
PERFORMANCE OPTIMIZATION
================================================================================

QUERY OPTIMIZATION:
✅ Indexes on all foreign keys
✅ Composite indexes for complex queries
✅ Partial indexes for status-based queries
✅ GIN indexes for JSONB and arrays
✅ Materialized views for reporting

CONNECTION POOLING:
✅ Supabase connection pooling (max 100)
✅ pgBouncer for production
✅ Monitor connection usage

CACHING:
✅ Dashboard metrics cached (30s refresh)
✅ In-memory cache in Flutter app
✅ Redis for session management (optional)

REALTIME OPTIMIZATION:
✅ Filtered subscriptions (WHERE clauses)
✅ Unsubscribe on screen exit
✅ Batch updates to reduce events

STORAGE OPTIMIZATION:
✅ Compress images before upload (max 10MB)
✅ WebP format for photos
✅ Lazy loading for galleries
✅ Scheduled cleanup of orphaned files

DATABASE MAINTENANCE:
✅ VACUUM ANALYZE monthly
✅ Rebuild indexes quarterly
✅ Monitor table bloat
✅ Archive old audit logs (> 7 years)

================================================================================
MIGRATION STRATEGY
================================================================================

PHASE 1: PREPARATION (No downtime)
- Export current data to CSV backups
- Document current RLS policies
- Test new schema in staging
- Prepare transformation scripts

PHASE 2: CREATE NEW SCHEMA (Parallel)
- Create all 51 tables
- Create admin tables
- Set up encryption (Vault, pgcrypto)
- Create indexes, RLS, triggers

PHASE 3: MIGRATE DATA (Scheduled maintenance, 2-4 hours)
- Maintenance mode ON
- Transform data (addresses, brands, photos)
- Encrypt sensitive data (IDs, phone, photos)
- Update foreign keys
- Validate integrity

PHASE 4: SWITCH OVER
- Deploy new Flutter app
- Switch database connection
- Monitor for errors
- Keep old schema 7 days (rollback)

PHASE 5: CLEANUP
- Drop old tables
- Reclaim storage
- Archive backups

ESTIMATED DOWNTIME: 2-4 hours

================================================================================
SUPPORT & MAINTENANCE
================================================================================

DAILY:
- Database backups
- Dashboard metrics refresh
- Admin notifications generation
- Cleanup read notifications

WEEKLY:
- Cleanup expired reports
- Performance review
- Security audit

MONTHLY:
- VACUUM ANALYZE
- Rebuild indexes
- Archive old data

QUARTERLY:
- Encryption key rotation check
- Performance optimization review

YEARLY:
- Rotate encryption keys
- Archive audit logs (> 7 years to cold storage)
- Comprehensive security audit

================================================================================
CONTACT & UPDATES
================================================================================

Documentation maintained by: AutoBid Development Team
Last updated: 2025-12-07
Version: 2.0 - Fresh Database Start

For questions or updates:
1. Review IMPLEMENTATION_REFERENCE.txt for general guidance
2. Review specific documents for detailed implementation
3. Refer to Supabase documentation for platform-specific features
4. Refer to Flutter/Dart documentation for app integration

================================================================================
END OF README
================================================================================
