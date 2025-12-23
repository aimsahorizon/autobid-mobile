-- ============================================================================
-- Fix Missing Columns in users Table
-- Issue: 'accepted_privacy_at' and 'accepted_terms_at' columns not found
-- Status: SUPERSEDED by 00009_complete_kyc_schema_fix.sql
-- ============================================================================

-- NOTE: This migration has been superseded by migration 00009
-- The columns are now added in 00009 along with all other missing fields
-- Keeping this file for historical reference only

-- Original migration (with syntax error fixed):
-- ALTER TABLE users
-- ADD COLUMN IF NOT EXISTS accepted_terms_at TIMESTAMPTZ DEFAULT NULL,
-- ADD COLUMN IF NOT EXISTS accepted_privacy_at TIMESTAMPTZ DEFAULT NULL,
-- ADD COLUMN IF NOT EXISTS admin_notes TEXT DEFAULT NULL;

-- Migration 00009 handles all these fields properly
-- No action needed here

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================
