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
  late final AdminSupabaseDataSource _dataSource;

  // Controller
  AdminController? _controller;

  /// Initialize module and datasources
  void initialize() {
    _dataSource = AdminSupabaseDataSource(_supabase);
  }

  /// Get or create admin controller
  AdminController get controller {
    _controller ??= AdminController(_dataSource);
    return _controller!;
  }

  /// Create a new admin controller instance
  AdminController createController() {
    return AdminController(_dataSource);
  }

  /// Clean up resources
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
