import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/datasources/admin_supabase_datasource.dart';
import 'presentation/controllers/admin_controller.dart';

/// Admin Module - Manages admin dashboard and listing reviews
/// DEV ONLY: For testing and simulating admin functionalities
class AdminModule {
  static final AdminModule _instance = AdminModule._internal();
  static AdminModule get instance => _instance;

  AdminModule._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Datasources
  AdminSupabaseDataSource? _dataSource;

  // Controller
  AdminController? _controller;

  // Initialization flag
  bool _isInitialized = false;

  /// Initialize module and datasources
  void initialize() {
    if (_isInitialized) {
      // Already initialized, skip
      return;
    }
    _dataSource = AdminSupabaseDataSource(_supabase);
    _isInitialized = true;
  }

  /// Get or create admin controller
  AdminController get controller {
    if (_dataSource == null) {
      throw StateError('AdminModule not initialized. Call initialize() first.');
    }
    _controller ??= AdminController(_dataSource!);
    return _controller!;
  }

  /// Create a new admin controller instance
  AdminController createController() {
    if (_dataSource == null) {
      throw StateError('AdminModule not initialized. Call initialize() first.');
    }
    return AdminController(_dataSource!);
  }

  /// Clean up resources
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
