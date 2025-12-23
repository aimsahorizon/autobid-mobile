import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase configuration and client initialization
/// Loads credentials from .env file for security
class SupabaseConfig {
  static SupabaseClient? _client;

  /// Initialize Supabase with environment variables
  /// Must be called before app starts (in main.dart)
  static Future<void> initialize() async {
    // Load environment variables from .env file
    await dotenv.load(fileName: '.env');

    // Get Supabase credentials from environment
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

    // Validate credentials exist
    if (supabaseUrl == null || supabaseAnonKey == null) {
      throw Exception(
        'Supabase credentials not found. Please create .env file with SUPABASE_URL and SUPABASE_ANON_KEY',
      );
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce, // Use PKCE flow for better security
      ),
    );

    _client = Supabase.instance.client;
  }

  /// Get Supabase client instance
  /// Throws error if not initialized
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseConfig.initialize() in main.dart',
      );
    }
    return _client!;
  }

  /// Check if Supabase is initialized
  static bool get isInitialized => _client != null;

  /// Get current authenticated user (shorthand)
  static User? get currentUser => _client?.auth.currentUser;

  /// Get auth stream (listen to auth state changes)
  static Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();
}
