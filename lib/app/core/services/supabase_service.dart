import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to initialize and access Supabase client
class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  /// Initialize Supabase with your project credentials
  /// Call this in main.dart before runApp()
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  /// Get the Supabase client instance
  SupabaseClient get client => Supabase.instance.client;

  /// Quick access to auth
  GoTrueClient get auth => client.auth;

  /// Quick access to storage
  SupabaseStorageClient get storage => client.storage;
}
