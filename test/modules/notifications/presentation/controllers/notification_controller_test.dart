// ignore_for_file: void_checks

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/entities/notification_entity.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/mark_as_read_usecase.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/delete_notification_usecase.dart';
import 'package:autobid_mobile/modules/notifications/presentation/controllers/notification_controller.dart';

class MockGetNotificationsUseCase extends Mock
    implements GetNotificationsUseCase {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockMarkAsReadUseCase extends Mock implements MarkAsReadUseCase {}

class MockMarkAllAsReadUseCase extends Mock implements MarkAllAsReadUseCase {}

class MockDeleteNotificationUseCase extends Mock
    implements DeleteNotificationUseCase {}

void main() {
  late NotificationController controller;
  late MockGetNotificationsUseCase mockGetNotifications;
  late MockGetUnreadCountUseCase mockGetUnreadCount;
  late MockMarkAsReadUseCase mockMarkAsRead;
  late MockMarkAllAsReadUseCase mockMarkAllAsRead;
  late MockDeleteNotificationUseCase mockDeleteNotification;

  setUp(() {
    mockGetNotifications = MockGetNotificationsUseCase();
    mockGetUnreadCount = MockGetUnreadCountUseCase();
    mockMarkAsRead = MockMarkAsReadUseCase();
    mockMarkAllAsRead = MockMarkAllAsReadUseCase();
    mockDeleteNotification = MockDeleteNotificationUseCase();

    controller = NotificationController(
      getNotificationsUseCase: mockGetNotifications,
      getUnreadCountUseCase: mockGetUnreadCount,
      markAsReadUseCase: mockMarkAsRead,
      markAllAsReadUseCase: mockMarkAllAsRead,
      deleteNotificationUseCase: mockDeleteNotification,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('NotificationController', () {
    const testUserId = 'user-123';
    final testNotifications = <NotificationEntity>[
      NotificationEntity(
        id: 'notif-1',
        userId: testUserId,
        title: 'Test Notification 1',
        message: 'Test message 1',
        type: NotificationType.bidUpdate,
        priority: NotificationPriority.normal,
        isRead: false,
        createdAt: DateTime(2026, 1, 22, 10, 0),
      ),
      NotificationEntity(
        id: 'notif-2',
        userId: testUserId,
        title: 'Test Notification 2',
        message: 'Test message 2',
        type: NotificationType.auctionUpdate,
        priority: NotificationPriority.high,
        isRead: true,
        createdAt: DateTime(2026, 1, 22, 11, 0),
      ),
    ];

    group('Initial State', () {
      test('should have correct initial state', () {
        expect(controller.notifications, isEmpty);
        expect(controller.unreadCount, equals(0));
        expect(controller.isLoading, false);
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
      });
    });

    group('loadNotifications', () {
      test('should load notifications successfully', () async {
        // Arrange
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(1));

        // Act
        await controller.loadNotifications(testUserId);

        // Assert
        expect(controller.notifications, equals(testNotifications));
        expect(controller.unreadCount, equals(1));
        expect(controller.errorMessage, isNull);
        expect(controller.isLoading, false);
        verify(
          () => mockGetNotifications(
            userId: testUserId,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).called(1);
        verify(() => mockGetUnreadCount(userId: testUserId)).called(1);
      });

      test('should update loading state during notification load', () async {
        // Arrange
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(1));

        // Act
        final future = controller.loadNotifications(testUserId);

        // Assert - should be loading
        expect(controller.isLoading, true);
        expect(controller.errorMessage, isNull);

        await future;

        // Assert - should finish loading
        expect(controller.isLoading, false);
      });

      test('should handle failure when loading notifications', () async {
        // Arrange
        const failure = ServerFailure('Failed to load notifications');
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Left(failure));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(0));

        // Act
        await controller.loadNotifications(testUserId);

        // Assert
        expect(controller.notifications, isEmpty);
        expect(controller.errorMessage, equals(failure.message));
        expect(controller.hasError, true);
        expect(controller.isLoading, false);
      });

      test('should handle unread count failure silently', () async {
        // Arrange
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Left(ServerFailure('Count failed')));

        // Act
        await controller.loadNotifications(testUserId);

        // Assert - notifications should load, count stays 0
        expect(controller.notifications, equals(testNotifications));
        expect(controller.unreadCount, equals(0));
        expect(controller.hasError, false);
      });

      test('should clear previous error on new load attempt', () async {
        // Arrange - first load fails
        const failure = ServerFailure('Network error');
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Left(failure));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(0));
        await controller.loadNotifications(testUserId);
        expect(controller.hasError, true);

        // Act - second load succeeds
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        await controller.loadNotifications(testUserId);

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.hasError, false);
        expect(controller.notifications, equals(testNotifications));
      });

      test('should notify listeners on state change', () async {
        // Arrange
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(1));

        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Act
        await controller.loadNotifications(testUserId);

        // Assert - should notify at least twice
        expect(notificationCount, greaterThanOrEqualTo(2));
      });
    });

    group('markAsRead', () {
      test('should mark notification as read successfully', () async {
        // Arrange - First load notifications
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(2));
        await controller.loadNotifications(testUserId);

        // Arrange - Mark as read
        const notificationId = 'notif-1';
        when(
          () => mockMarkAsRead(notificationId: any(named: 'notificationId')),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        await controller.markAsRead(notificationId, testUserId);

        // Assert
        expect(controller.errorMessage, isNull);
        verify(() => mockMarkAsRead(notificationId: notificationId)).called(1);
        expect(controller.unreadCount, equals(1)); // Decreased from 2 to 1
      });

      test('should handle failure when marking as read', () async {
        // Arrange
        const notificationId = 'notif-1';
        const failure = ServerFailure('Failed to mark as read');
        when(
          () => mockMarkAsRead(notificationId: any(named: 'notificationId')),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await controller.markAsRead(notificationId, testUserId);

        // Assert
        expect(controller.errorMessage, equals(failure.message));
        expect(controller.hasError, true);
      });
    });

    group('markAllAsRead', () {
      test('should mark all notifications as read successfully', () async {
        // Arrange
        when(() => mockMarkAllAsRead()).thenAnswer((_) async => const Right(3));
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(0));

        // Act
        await controller.markAllAsRead(testUserId);

        // Assert
        expect(controller.errorMessage, isNull);
        expect(controller.unreadCount, equals(0));
        verify(() => mockMarkAllAsRead()).called(1);
      });

      test('should handle failure when marking all as read', () async {
        // Arrange
        const failure = ServerFailure('Failed to mark all as read');
        when(
          () => mockMarkAllAsRead(),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await controller.markAllAsRead(testUserId);

        // Assert
        expect(controller.errorMessage, equals(failure.message));
        expect(controller.hasError, true);
      });
    });

    group('deleteNotification', () {
      test('should delete notification successfully', () async {
        // Arrange - First load notifications
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(2));
        await controller.loadNotifications(testUserId);

        // Arrange - Delete notification
        const notificationId = 'notif-1';
        when(
          () => mockDeleteNotification(
            notificationId: any(named: 'notificationId'),
          ),
        ).thenAnswer((_) async => const Right(unit));

        // Act
        await controller.deleteNotification(notificationId, testUserId);

        // Assert
        expect(controller.errorMessage, isNull);
        verify(
          () => mockDeleteNotification(notificationId: notificationId),
        ).called(1);
        verify(
          () => mockGetNotifications(
            userId: testUserId,
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).called(1);
      });

      test('should handle failure when deleting notification', () async {
        // Arrange
        const notificationId = 'notif-1';
        const failure = ServerFailure('Failed to delete notification');
        when(
          () => mockDeleteNotification(
            notificationId: any(named: 'notificationId'),
          ),
        ).thenAnswer((_) async => const Left(failure));

        // Act
        await controller.deleteNotification(notificationId, testUserId);

        // Assert
        expect(controller.errorMessage, equals(failure.message));
        expect(controller.hasError, true);
      });
    });

    group('Edge Cases', () {
      test('should handle empty notification list', () async {
        // Arrange
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Right([]));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(0));

        // Act
        await controller.loadNotifications(testUserId);

        // Assert
        expect(controller.notifications, isEmpty);
        expect(controller.unreadCount, equals(0));
        expect(controller.hasError, false);
      });

      test('should handle multiple rapid load calls', () async {
        // Arrange
        when(
          () => mockGetNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => Right(testNotifications));
        when(
          () => mockGetUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => const Right(1));

        // Act
        await Future.wait([
          controller.loadNotifications(testUserId),
          controller.loadNotifications(testUserId),
          controller.loadNotifications(testUserId),
        ]);

        // Assert
        expect(controller.notifications, equals(testNotifications));
        expect(controller.hasError, false);
      });
    });
  });
}
