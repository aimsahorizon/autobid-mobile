import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';

/// Repository interface for notification operations
abstract class NotificationRepository {
  /// Get all notifications for a user
  Future<Either<Failure, List<NotificationEntity>>> getNotifications({
    required String userId,
    int? limit,
    int? offset,
  });

  /// Get count of unread notifications
  Future<Either<Failure, int>> getUnreadCount({required String userId});

  /// Mark a notification as read
  Future<Either<Failure, void>> markAsRead({required String notificationId});

  /// Mark all notifications as read for a user
  Future<Either<Failure, int>> markAllAsRead();

  /// Delete a notification
  Future<Either<Failure, void>> deleteNotification({
    required String notificationId,
  });

  /// Get only unread notifications for a user
  Future<Either<Failure, List<NotificationEntity>>> getUnreadNotifications({
    required String userId,
  });
}
