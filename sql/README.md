# Database Setup Instructions

Run these SQL files in order in your Supabase SQL Editor:

## 1. User Authentication (Already Done)
- `1_schema.sql` - Users table schema
- `2_rls.sql` - User RLS policies
- `3_storage_fixed.sql` - Storage for KYC documents
- `add_guest_status_policy.sql` - Guest account status checking

## 2. Listings Module (Run These Now)
- `4_listings_schema.sql` - Listing drafts and listings tables
- `5_listings_rls.sql` - Listing RLS policies
- `6_listings_storage.sql` - Storage for listing photos

## Important Notes
- Run each file completely before moving to the next
- Check for errors after each execution
- The order matters due to dependencies
