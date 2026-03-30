import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// DEV ONLY: Admin authentication bypass for testing
/// This allows instant admin access without proper authentication flow
class DevAdminAuth {
  static const String devAdminEmail = 'admin@autobid.dev';
  static const String devAdminPassword = 'admin123456';

  /// Quick admin login for development testing
  /// Creates/signs in as admin user and ensures admin_users record exists
  static Future<bool> quickAdminLogin() async {
    try {
      final supabase = Supabase.instance.client;

      debugPrint('[DevAdminAuth] Starting quick admin login...');

      // Try to sign in first
      try {
        final response = await supabase.auth.signInWithPassword(
          email: devAdminEmail,
          password: devAdminPassword,
        );
        debugPrint('[DevAdminAuth] Sign in successful: ${response.user?.id}');
      } catch (signInError) {
        debugPrint('[DevAdminAuth] Sign in failed, attempting sign up...');

        // If sign in fails, try to sign up
        try {
          final signUpResponse = await supabase.auth.signUp(
            email: devAdminEmail,
            password: devAdminPassword,
          );
          debugPrint('[DevAdminAuth] Sign up successful: ${signUpResponse.user?.id}');

          // Sign in after sign up
          await supabase.auth.signInWithPassword(
            email: devAdminEmail,
            password: devAdminPassword,
          );
          debugPrint('[DevAdminAuth] Post-signup sign in successful');
        } catch (signUpError) {
          debugPrint('[DevAdminAuth] Sign up failed: $signUpError');
          return false;
        }
      }

      // Ensure admin_users record exists
      await _ensureAdminUserRecord(supabase);

      return true;
    } catch (e) {
      debugPrint('[DevAdminAuth] Quick admin login failed: $e');
      return false;
    }
  }

  /// Ensures admin_users record exists for current admin user
  static Future<void> _ensureAdminUserRecord(SupabaseClient supabase) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('[DevAdminAuth] No current user, cannot create admin_users record');
        return;
      }

      debugPrint('[DevAdminAuth] Checking admin_users record for: $userId');

      // Check if admin_users record exists
      final existingAdmin = await supabase
          .from('admin_users')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existingAdmin != null) {
        debugPrint('[DevAdminAuth] Admin_users record already exists');
        return;
      }

      debugPrint('[DevAdminAuth] Creating admin_users record...');

      // Get super_admin role ID
      final roleResponse = await supabase
          .from('admin_roles')
          .select('id')
          .eq('role_name', 'super_admin')
          .single();

      final roleId = roleResponse['id'] as String;

      // Ensure users table record exists
      final userExists = await supabase
          .from('users')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (userExists == null) {
        debugPrint('[DevAdminAuth] Creating users table record...');
        await supabase.from('users').insert({
          'id': userId,
          'email': devAdminEmail,
          'full_name': 'System Administrator',
          'is_active': true,
          'is_verified': true,
        });
      }

      // Create admin_users record
      await supabase.from('admin_users').insert({
        'user_id': userId,
        'role_id': roleId,
        'is_active': true,
        'created_by': userId,
      });

      debugPrint('[DevAdminAuth] ✅ Admin_users record created successfully');
    } catch (e) {
      debugPrint('[DevAdminAuth] ⚠️  Failed to create admin_users record: $e');
      debugPrint('[DevAdminAuth] ℹ️  You may need to run create_admin_account.sql manually');
    }
  }

  /// Check if current user is the dev admin
  static bool isDevAdmin() {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    return user?.email == devAdminEmail;
  }

  /// Get admin user ID
  static String? getAdminUserId() {
    final supabase = Supabase.instance.client;
    return supabase.auth.currentUser?.id;
  }
}
