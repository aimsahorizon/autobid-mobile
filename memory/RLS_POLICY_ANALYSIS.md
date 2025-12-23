## Deep Analysis: RLS Policy Error on Draft Deletion

### The Error
```
failed to delete drafts: exception new row violates row level security policy for table "listing_drafts"
```

### Root Cause Analysis

#### 1. **The Original RLS Policy (Problematic)**
Located in `00018_create_listing_drafts_table.sql`:

```sql
CREATE POLICY listing_drafts_delete_own
  ON listing_drafts
  FOR UPDATE
  USING (
    seller_id = auth.uid()
  )
  WITH CHECK (
    deleted_at IS NOT NULL
  );
```

**Problems:**
- The `USING` clause checks: "Is the current user the seller?" ✓
- The `WITH CHECK` clause requires: "Is deleted_at NOT NULL?" ✓
- **But the issue**: The `WITH CHECK` condition only verifies `deleted_at IS NOT NULL`, not that `seller_id` matches
- This creates a logical inconsistency: after soft-delete, the row might not satisfy all constraints

#### 2. **Why It Fails in Practice**

When the update is executed:
1. PostgreSQL evaluates `USING`: Checks if `seller_id = auth.uid()` → **PASS**
2. PostgreSQL applies the update (sets `deleted_at`)
3. PostgreSQL evaluates `WITH CHECK`: Checks if `deleted_at IS NOT NULL` → **PASS (after update)**
4. **BUT**: If `auth.uid()` context is lost or user's auth session isn't properly passed, the policy can fail

#### 3. **Additional Complications**

- **Auth Context Loss**: Supabase client-side auth might not properly propagate `auth.uid()` in all conditions
- **Session Expiry**: If the user's session expired between loading the draft and deleting it
- **Permission Mismatch**: The draft's `seller_id` doesn't match the authenticated user's ID

### Solutions Implemented

#### Solution 1: Improved RLS Policy (Migration 00041)
```sql
CREATE POLICY listing_drafts_soft_delete_own
  ON listing_drafts
  FOR UPDATE
  USING (
    seller_id = auth.uid()
  )
  WITH CHECK (
    seller_id = auth.uid()  -- Verify ownership is maintained
    AND TRUE  -- Allow the update if user owns it
  );
```

**Why this works:**
- Explicitly verifies ownership both before (`USING`) and after (`WITH CHECK`)
- More robust: doesn't rely on single condition being true after update
- Clearer intent: "Only update if you own it, and you still own it after"

#### Solution 2: Enhanced Datasource Method
Added to `listing_supabase_datasource.dart`:

```dart
Future<void> deleteDraft(String draftId) async {
  // 1. Check authentication explicitly
  final currentUser = _supabase.auth.currentUser;
  if (currentUser == null) {
    throw Exception('User must be authenticated to delete draft');
  }

  // 2. Attempt soft delete
  final response = await _supabase
      .from('listing_drafts')
      .update({'deleted_at': DateTime.now().toIso8601String()})
      .eq('id', draftId)
      .select();  // Get response to verify update happened

  // 3. Verify the update was successful
  if (response.isEmpty) {
    throw Exception('Draft not found or access denied. Ensure you own this draft.');
  }
}
```

**Why this helps:**
- Validates authentication before attempting database operation
- Provides clear feedback if draft wasn't found or is not owned by user
- Returns response to confirm operation succeeded (not just that query ran)
- Better error messages for RLS violations

### How to Apply the Fix

1. **Apply the migration:**
   ```bash
   cd supabase
   supabase migration up
   ```

2. **Rebuild the app:**
   ```bash
   flutter pub get
   flutter run
   ```

### Testing the Fix

To verify the RLS policy works correctly:

```sql
-- As authenticated user (replace with actual user_id):
UPDATE listing_drafts
SET deleted_at = NOW()
WHERE id = 'draft-uuid-here'
AND seller_id = auth.uid();  -- Verify user owns draft
```

### Alternative: Hard Delete Instead of Soft Delete

If soft delete continues to cause issues, you can switch to hard delete:

1. Create new policy in migration:
```sql
CREATE POLICY listing_drafts_hard_delete_own
  ON listing_drafts
  FOR DELETE
  USING (
    seller_id = auth.uid()
  );
```

2. Update datasource:
```dart
await _supabase
    .from('listing_drafts')
    .delete()
    .eq('id', draftId);
```

**Trade-off**: Hard delete permanently removes the record (no audit trail), while soft delete preserves data.

### Prevention for Future RLS Issues

When creating RLS policies:
1. **Always verify auth context**: Check `auth.uid()` exists before policy evaluation
2. **Keep policies simple**: Complex conditions increase failure modes
3. **Test with real auth**: Don't test with null/invalid auth tokens
4. **Use explicit constraints**: Check ownership both in USING and WITH CHECK
5. **Add logging**: Log auth state and policy violations for debugging

### References
- Supabase RLS Documentation: https://supabase.com/docs/guides/auth/row-level-security
- PostgreSQL RLS: https://www.postgresql.org/docs/current/ddl-rowsecurity.html
