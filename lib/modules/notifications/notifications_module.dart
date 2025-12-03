import '../../app/core/config/supabase_config.dart';
import 'data/datasources/notification_mock_datasource.dart';
import 'data/datasources/notification_supabase_datasource.dart';
import 'presentation/controllers/notification_controller.dart';

/// Notifications module dependency injection
class NotificationsModule {
  static final NotificationsModule _instance = NotificationsModule._internal();
  static NotificationsModule get instance => _instance;

  NotificationsModule._internal();

  /// Toggle for mock data vs real Supabase backend
  static bool useMockData = true;

  // Data source instances
  final _mockDataSource = NotificationMockDataSource();
  NotificationSupabaseDataSource? _supabaseDataSource;

  /// Singleton controller instance
  static NotificationController? _notificationController;

  /// Create Supabase datasource
  NotificationSupabaseDataSource _createSupabaseDataSource() {
    return NotificationSupabaseDataSource(supabase: SupabaseConfig.client);
  }

  /// Get data source based on useMockData flag
  INotificationDataSource _getDataSource() {
    if (useMockData) {
      return _mockDataSource;
    } else {
      _supabaseDataSource ??= _createSupabaseDataSource();
      return _supabaseDataSource!;
    }
  }

  /// Get or create notification controller
  NotificationController get controller {
    if (_notificationController == null) {
      _notificationController = NotificationController(_getDataSource());
    }
    return _notificationController!;
  }

  /// Create a new notification controller
  NotificationController createNotificationController() {
    return NotificationController(_getDataSource());
  }

  /// Toggle demo mode (switch between mock and Supabase)
  static void toggleDemoMode() {
    useMockData = !useMockData;
    dispose();
  }

  /// Dispose resources
  static void dispose() {
    _notificationController?.dispose();
    _notificationController = null;
  }

  /// Factory constructor
  factory NotificationsModule() => _instance;
}
