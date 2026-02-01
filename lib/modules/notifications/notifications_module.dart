import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'data/datasources/notification_datasource.dart';
import 'data/datasources/notification_supabase_datasource.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'domain/repositories/notification_repository.dart';
import 'domain/usecases/get_notifications_usecase.dart';
import 'domain/usecases/get_unread_count_usecase.dart';
import 'domain/usecases/mark_as_read_usecase.dart';
import 'domain/usecases/mark_all_as_read_usecase.dart';
import 'domain/usecases/delete_notification_usecase.dart';
import 'domain/usecases/get_unread_notifications_usecase.dart';
import 'presentation/controllers/notification_controller.dart';

// Export the controller so it can be used by other modules
export 'presentation/controllers/notification_controller.dart';

/// Initialize Notifications module dependencies
Future<void> initNotificationsModule() async {
  final sl = GetIt.instance;

  // Datasources
  sl.registerLazySingleton<INotificationDataSource>(
    () => NotificationSupabaseDataSource(supabase: sl()),
  );

  // Repository
  sl.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(dataSource: sl()),
  );

  // UseCases
  sl.registerLazySingleton(() => GetNotificationsUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadCountUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => MarkAllAsReadUseCase(sl()));
  sl.registerLazySingleton(() => DeleteNotificationUseCase(sl()));
  sl.registerLazySingleton(() => GetUnreadNotificationsUseCase(sl()));

  // Controllers (Factory)
  sl.registerFactory(
    () => NotificationController(
      getNotificationsUseCase: sl(),
      getUnreadCountUseCase: sl(),
      markAsReadUseCase: sl(),
      markAllAsReadUseCase: sl(),
      deleteNotificationUseCase: sl(),
    ),
  );
}

/// Notifications module dependency injection (Legacy)
/// @deprecated Use GetIt with initNotificationsModule() instead
@Deprecated('Use GetIt with initNotificationsModule()')
class NotificationsModule {
  static final NotificationsModule _instance = NotificationsModule._internal();
  static NotificationsModule get instance => _instance;

  NotificationsModule._internal();

  /// Singleton controller instance (deprecated)
  static NotificationController? _notificationController;

  /// Get or create notification controller
  /// @deprecated Use GetIt.instance.get[NotificationController] instead
  @Deprecated('Use GetIt.instance.get<NotificationController>()')
  NotificationController get controller {
    // Return GetIt controller if available
    if (GetIt.instance.isRegistered<NotificationController>()) {
      return GetIt.instance<NotificationController>();
    }
    // Fallback to legacy implementation using Supabase directly
    _notificationController ??= NotificationController(
      getNotificationsUseCase: GetNotificationsUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      getUnreadCountUseCase: GetUnreadCountUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      markAsReadUseCase: MarkAsReadUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      markAllAsReadUseCase: MarkAllAsReadUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      deleteNotificationUseCase: DeleteNotificationUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
    );
    return _notificationController!;
  }

  /// Create a new notification controller
  /// @deprecated Use GetIt.instance.get[NotificationController] instead
  @Deprecated('Use GetIt.instance.get<NotificationController>()')
  NotificationController createNotificationController() {
    return NotificationController(
      getNotificationsUseCase: GetNotificationsUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      getUnreadCountUseCase: GetUnreadCountUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      markAsReadUseCase: MarkAsReadUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      markAllAsReadUseCase: MarkAllAsReadUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
      deleteNotificationUseCase: DeleteNotificationUseCase(
        NotificationRepositoryImpl(
          dataSource: NotificationSupabaseDataSource(
            supabase: SupabaseConfig.client,
          ),
        ),
      ),
    );
  }

  /// Dispose resources
  static void dispose() {
    _notificationController?.dispose();
    _notificationController = null;
  }

  /// Factory constructor
  factory NotificationsModule() => _instance;
}
