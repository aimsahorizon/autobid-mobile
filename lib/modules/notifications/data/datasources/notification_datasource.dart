import '../../domain/entities/notification_entity.dart';

/// Abstract datasource interface for notifications
abstract class INotificationDataSource {
  Future<List<NotificationEntity>> getNotifications({
    required String userId,
    int? limit,
    int? offset,
  });
  Future<int> getUnreadCount({required String userId});
  Future<void> markAsRead({required String notificationId});
  Future<int> markAllAsRead();
  Future<void> deleteNotification({required String notificationId});
  Future<List<NotificationEntity>> getUnreadNotifications({
    required String userId,
  });
}
