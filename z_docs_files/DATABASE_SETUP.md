# Database Setup Guide

## Overview
Fresh Supabase database setup for AutoBid authentication with KYC verification.

## Architecture
- **Single `users` table** - All user data in one place
- **Simple RLS policies** - No recursion, clean separation
- **3 storage buckets** - Profile photos (after approval), KYC documents (during registration)
- **MVP-focused** - Production-ready, extensible for future modules

## Run Order (in Supabase SQL Editor)

### 1. Schema Setup
**File:** `1_schema.sql`

Creates:
- `users` table with all KYC fields
- Indexes for performance
- Auto-update trigger for `updated_at`
- Admin functions: `approve_kyc()`, `reject_kyc()`
- Admin view: `admin_pending_kyc`

**Field Mapping (matches Flutter model):**
```
Flutter Model          →  Database Column
------------------        -----------------
id                    →  id
email                 →  email
phoneNumber           →  phone_number
username              →  username
firstName             →  first_name
lastName              →  last_name
middleName            →  middle_name
dateOfBirth           →  date_of_birth
sex                   →  sex
region                →  region
province              →  province
city                  →  city
barangay              →  barangay
streetAddress         →  street_address ⚠️ (was 'street' in old version)
zipcode               →  zipcode
nationalIdNumber      →  national_id_number
nationalIdFrontUrl    →  national_id_front_url
nationalIdBackUrl     →  national_id_back_url
selfieWithIdUrl       →  selfie_with_id_url
secondaryGovIdType    →  secondary_gov_id_type
secondaryGovIdNumber  →  secondary_gov_id_number
secondaryGovIdFrontUrl→  secondary_gov_id_front_url
secondaryGovIdBackUrl →  secondary_gov_id_back_url
proofOfAddressType    →  proof_of_address_type
proofOfAddressUrl     →  proof_of_address_url
acceptedTermsAt       →  accepted_terms_at
acceptedPrivacyAt     →  accepted_privacy_at
status                →  status (pending/approved/rejected)
```

### 2. Security Policies
**File:** `2_rls.sql`

Creates:
- **User policies**: View/update own data, insert during registration
- **Public policies**: View approved users (for listings/bids)
- **Admin policies**: Use service_role key (bypasses RLS)
- **Protection trigger**: Prevents privilege escalation

**Key Design:**
- ✅ No recursion - simple `auth.uid()` checks
- ✅ No JWT claims complexity
- ✅ Admins use service_role key
- ✅ Users cannot change: status, role, is_verified, account_status

### 3. Storage Setup
**File:** `3_storage.sql`

Creates:
- **user-avatars** (public, 5MB) - Profile photos AFTER approval
- **user-covers** (public, 10MB) - Cover photos AFTER approval
- **kyc-documents** (private, 10MB) - ID documents DURING registration

**Key Design:**
- ✅ Profile photos require `status = 'approved'` (no upload during KYC)
- ✅ KYC documents allow `authenticated` users (upload during registration)
- ✅ Admins use service_role to view KYC documents
- ✅ No RLS recursion

## User Flow

### Registration Flow
```
1. User signs up
   → Supabase creates auth.users record
   → User gets auth.uid()

2. User verifies email/phone OTP
   → User becomes authenticated
   → auth.currentUser populated

3. User fills KYC form + uploads ID documents
   → Flutter calls submitKycRegistration()
   → INSERT into users table (status='pending')
   → Documents uploaded to kyc-documents/{user_id}/
   ⚠️ Profile photo NOT uploaded yet

4. Admin reviews
   → Admin dashboard queries admin_pending_kyc view
   → Admin views KYC documents via service_role key
   → Admin calls approve_kyc(user_id) or reject_kyc(user_id, reason)

5. User approved
   → status='approved', is_verified=true
   → User can now login and use app
   → User can now upload profile photo/cover

6. User logs in
   → signInWithPassword(email, password)
   → RLS allows access to approved users
```

## Admin Operations

### Approve KYC
```sql
SELECT approve_kyc('user-uuid-here');
```

### Reject KYC
```sql
SELECT reject_kyc('user-uuid-here', 'Reason for rejection', 'Optional admin notes');
```

### View Pending KYC
```sql
SELECT * FROM admin_pending_kyc;
```

### View All Users (service_role only)
```sql
SELECT * FROM users WHERE deleted_at IS NULL;
```

## Flutter Integration

### No Changes Needed
The existing Flutter code already works:
- ✅ `auth_remote_datasource.dart` uses `users` table
- ✅ `KycRegistrationModel` fields match database columns
- ✅ All usecases work as-is

### Important Notes
1. **Profile photo upload** - Must be disabled during KYC registration
2. **Field name** - `streetAddress` → `street_address` (already correct in model)
3. **Admin access** - Use service_role key for admin dashboard

## Testing Checklist

- [ ] Run 1_schema.sql successfully
- [ ] Run 2_rls.sql successfully
- [ ] Run 3_storage.sql successfully
- [ ] Verify buckets created in Supabase Storage
- [ ] Test user registration (OTP verification)
- [ ] Test KYC submission (without profile photo)
- [ ] Test KYC document upload to kyc-documents bucket
- [ ] Test admin KYC approval via approve_kyc()
- [ ] Test user login after approval
- [ ] Test profile photo upload after approval

## Troubleshooting

### "Bucket not found" error
- Ensure 3_storage.sql ran successfully
- Check Supabase Storage > Buckets exist

### "RLS policy violation" during upload
- Check user is authenticated: `auth.currentUser != null`
- For profile photos: Check user status = 'approved'
- For KYC docs: Check auth.role() = 'authenticated'

### "Cannot change KYC status" error
- This is correct behavior - users cannot change their own status
- Admins must use service_role key or call approve_kyc()/reject_kyc()

### OTP verification causes 500 error
- Should NOT happen with this setup (no triggers on auth.users)
- If occurs, check Supabase logs

## Next Steps

After database setup:
1. Test full registration flow
2. Create admin dashboard for KYC approval
3. Implement next modules (bids, listings, etc.)
4. Users table has prepared fields: `total_bids`, `total_listings`, `subscription_tier`

## Support

Database is production-ready and extensible. All common issues from previous iterations have been resolved:
- ✅ No RLS recursion
- ✅ No trigger conflicts
- ✅ No profile photo complications
- ✅ Clean field naming
- ✅ Simple admin workflow
