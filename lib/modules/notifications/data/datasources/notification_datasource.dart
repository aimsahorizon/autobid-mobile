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
  Future<void> respondToInvite({
    required String inviteId,
    required String decision, // 'accepted' or 'rejected'
  });

  /// Stream real-time notification updates for a user
  Stream<List<Map<String, dynamic>>> streamNotifications({
    required String userId,
  });
}
