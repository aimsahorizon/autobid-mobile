import '../../domain/entities/notification_entity.dart';
import 'notification_datasource.dart';
import '../models/notification_model.dart';

/// Mock data source for notifications (for testing without backend)
class NotificationMockDataSource implements INotificationDataSource {
  static const _mockDelay = Duration(milliseconds: 500);

  /// Get mock notifications
  @override
  Future<List<NotificationModel>> getNotifications({
    required String userId,
    int? limit,
    int? offset,
  }) async {
    await Future.delayed(_mockDelay);

    final now = DateTime.now();
    final notifications = [
      NotificationModel(
        id: 'notif_001',
        userId: userId,
        type: NotificationType.auctionUpdate,
        priority: NotificationPriority.high,
        title: 'Auction Ending Soon!',
        message: 'The auction for 2023 Toyota Supra GR ends in 30 minutes',
        isRead: false,
        createdAt: now.subtract(const Duration(minutes: 5)),
        relatedEntityId: 'auction_001',
        relatedEntityType: 'auction',
      ),
      NotificationModel(
        id: 'notif_002',
        userId: userId,
        type: NotificationType.bidUpdate,
        priority: NotificationPriority.normal,
        title: 'You\'ve Been Outbid',
        message: 'Someone placed a higher bid on 2022 BMW M4 Competition',
        isRead: false,
        createdAt: now.subtract(const Duration(hours: 1)),
        relatedEntityId: 'auction_002',
        relatedEntityType: 'auction',
      ),
      NotificationModel(
        id: 'notif_003',
        userId: userId,
        type: NotificationType.listingUpdate,
        priority: NotificationPriority.high,
        title: 'Listing Approved!',
        message: 'Your listing "2021 Honda Civic" has been approved',
        isRead: true,
        createdAt: now.subtract(const Duration(hours: 3)),
        relatedEntityId: 'listing_001',
        relatedEntityType: 'listing',
      ),
      NotificationModel(
        id: 'notif_004',
        userId: userId,
        type: NotificationType.transaction,
        priority: NotificationPriority.normal,
        title: 'Token Purchase Successful',
        message: 'You purchased 25 Bidding Tokens for ₱349',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 1)),
        relatedEntityType: 'transaction',
      ),
      NotificationModel(
        id: 'notif_005',
        userId: userId,
        type: NotificationType.auctionUpdate,
        priority: NotificationPriority.urgent,
        title: 'Congratulations!',
        message: 'You won the auction for 2020 Chevrolet Corvette C8!',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 2)),
        relatedEntityId: 'auction_004',
        relatedEntityType: 'auction',
      ),
      NotificationModel(
        id: 'notif_006',
        userId: userId,
        type: NotificationType.system,
        priority: NotificationPriority.low,
        title: 'Welcome to AutoBid!',
        message: 'Your account has been verified. Start bidding now!',
        isRead: true,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
    ];

    // Apply pagination
    final start = offset ?? 0;
    final end = limit != null ? start + limit : notifications.length;
    return notifications.sublist(
      start.clamp(0, notifications.length),
      end.clamp(0, notifications.length),
    );
  }

  /// Get unread count
  @override
  Future<int> getUnreadCount({required String userId}) async {
    await Future.delayed(_mockDelay);
    return 2; // Mock unread count
  }

  /// Mark as read
  @override
  Future<void> markAsRead({required String notificationId}) async {
    await Future.delayed(_mockDelay);
  }

  /// Mark all as read
  @override
  Future<int> markAllAsRead() async {
    await Future.delayed(_mockDelay);
    return 2; // Mock marked count
  }

  /// Delete notification
  @override
  Future<void> deleteNotification({required String notificationId}) async {
    await Future.delayed(_mockDelay);
  }

  /// Get unread notifications
  @override
  Future<List<NotificationModel>> getUnreadNotifications({
    required String userId,
  }) async {
    final all = await getNotifications(userId: userId);
    return all.where((n) => !n.isRead).toList();
  }
}
