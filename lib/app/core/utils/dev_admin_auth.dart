import 'package:supabase_flutter/supabase_flutter.dart';

/// DEV ONLY: Admin authentication bypass for testing
/// This allows instant admin access without proper authentication flow
class DevAdminAuth {
  static const String devAdminEmail = 'admin@autobid.dev';
  static const String devAdminPassword = 'admin123456';
  static const String devAdminId = '00000000-0000-0000-0000-000000000001';

  /// Quick admin login for development testing
  /// Creates/signs in as admin user instantly
  static Future<bool> quickAdminLogin() async {
    try {
      final supabase = Supabase.instance.client;

      // Try to sign in first
      try {
        await supabase.auth.signInWithPassword(
          email: devAdminEmail,
          password: devAdminPassword,
        );
        return true;
      } catch (signInError) {
        // If sign in fails, try to sign up
        try {
          await supabase.auth.signUp(
            email: devAdminEmail,
            password: devAdminPassword,
          );

          // Sign in after sign up
          await supabase.auth.signInWithPassword(
            email: devAdminEmail,
            password: devAdminPassword,
          );

          return true;
        } catch (signUpError) {
          print('[DevAdminAuth] Sign up failed: $signUpError');
          return false;
        }
      }
    } catch (e) {
      print('[DevAdminAuth] Quick admin login failed: $e');
      return false;
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
