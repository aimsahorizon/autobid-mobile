import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// ...existing code...
import 'package:autobid_mobile/modules/notifications/data/repositories/notification_repository_impl.dart';
import 'package:autobid_mobile/modules/notifications/data/datasources/notification_datasource.dart';
import 'package:autobid_mobile/modules/notifications/domain/entities/notification_entity.dart';
import 'package:autobid_mobile/core/error/failures.dart';

// Mock classes
class MockNotificationDataSource extends Mock
    implements INotificationDataSource {}

void main() {
  late NotificationRepositoryImpl repository;
  late MockNotificationDataSource mockDataSource;

  const testUserId = 'test-user-123';
  const testNotificationId = 'notif-123';

  final testNotifications = <NotificationEntity>[
    NotificationEntity(
      id: 'notif-1',
      userId: testUserId,
      type: NotificationType.bidUpdate,
      priority: NotificationPriority.normal,
      title: 'Bid Update',
      message: 'You have been outbid',
      isRead: false,
      createdAt: DateTime.now(),
    ),
    NotificationEntity(
      id: 'notif-2',
      userId: testUserId,
      type: NotificationType.auctionUpdate,
      priority: NotificationPriority.high,
      title: 'Auction Ending Soon',
      message: 'Your watched auction ends in 1 hour',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    NotificationEntity(
      id: 'notif-3',
      userId: testUserId,
      type: NotificationType.system,
      priority: NotificationPriority.low,
      title: 'Welcome',
      message: 'Welcome to AutoBid',
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  setUp(() {
    mockDataSource = MockNotificationDataSource();
    repository = NotificationRepositoryImpl(dataSource: mockDataSource);
  });

  group('NotificationRepositoryImpl', () {
    group('getNotifications', () {
      test(
        'should return list of notifications when datasource succeeds',
        () async {
          // Arrange
          when(
            () => mockDataSource.getNotifications(
              userId: any(named: 'userId'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenAnswer((_) async => testNotifications);

          // Act
          final result = await repository.getNotifications(
            userId: testUserId,
            limit: 10,
            offset: 0,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should return Right but got Left: $failure'),
            (notifications) {
              expect(notifications, hasLength(3));
              expect(notifications[0].id, equals('notif-1'));
              expect(notifications[1].id, equals('notif-2'));
              expect(notifications[2].id, equals('notif-3'));
            },
          );
          verify(
            () => mockDataSource.getNotifications(
              userId: testUserId,
              limit: 10,
              offset: 0,
            ),
          ).called(1);
        },
      );

      test('should return empty list when no notifications exist', () async {
        // Arrange
        when(
          () => mockDataSource.getNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => []);

        // Act
        final result = await repository.getNotifications(
          userId: testUserId,
          limit: 10,
          offset: 0,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (notifications) => expect(notifications, isEmpty),
        );
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.getNotifications(
              userId: any(named: 'userId'),
              limit: any(named: 'limit'),
              offset: any(named: 'offset'),
            ),
          ).thenThrow(Exception('Database error'));

          // Act
          final result = await repository.getNotifications(
            userId: testUserId,
            limit: 10,
            offset: 0,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to get notifications'));
            expect(failure.message, contains('Database error'));
          }, (notifications) => fail('Should return Left but got Right'));
        },
      );

      test('should pass correct parameters to datasource', () async {
        // Arrange
        when(
          () => mockDataSource.getNotifications(
            userId: any(named: 'userId'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => testNotifications);

        // Act
        await repository.getNotifications(
          userId: testUserId,
          limit: 20,
          offset: 5,
        );

        // Assert
        verify(
          () => mockDataSource.getNotifications(
            userId: testUserId,
            limit: 20,
            offset: 5,
          ),
        ).called(1);
      });
    });

    group('getUnreadCount', () {
      test('should return unread count when datasource succeeds', () async {
        // Arrange
        when(
          () => mockDataSource.getUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => 5);

        // Act
        final result = await repository.getUnreadCount(userId: testUserId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (count) => expect(count, equals(5)),
        );
        verify(
          () => mockDataSource.getUnreadCount(userId: testUserId),
        ).called(1);
      });

      test('should return zero when no unread notifications', () async {
        // Arrange
        when(
          () => mockDataSource.getUnreadCount(userId: any(named: 'userId')),
        ).thenAnswer((_) async => 0);

        // Act
        final result = await repository.getUnreadCount(userId: testUserId);

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (count) => expect(count, equals(0)),
        );
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.getUnreadCount(userId: any(named: 'userId')),
          ).thenThrow(Exception('Query failed'));

          // Act
          final result = await repository.getUnreadCount(userId: testUserId);

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to get unread count'));
            expect(failure.message, contains('Query failed'));
          }, (count) => fail('Should return Left but got Right'));
        },
      );
    });

    group('markAsRead', () {
      test('should successfully mark notification as read', () async {
        // Arrange
        when(
          () => mockDataSource.markAsRead(
            notificationId: any(named: 'notificationId'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.markAsRead(
          notificationId: testNotificationId,
        );

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockDataSource.markAsRead(notificationId: testNotificationId),
        ).called(1);
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.markAsRead(
              notificationId: any(named: 'notificationId'),
            ),
          ).thenThrow(Exception('Update failed'));

          // Act
          final result = await repository.markAsRead(
            notificationId: testNotificationId,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to mark as read'));
            expect(failure.message, contains('Update failed'));
          }, (value) => fail('Should return Left but got Right'));
        },
      );
    });

    group('markAllAsRead', () {
      test('should return count of marked notifications', () async {
        // Arrange
        when(() => mockDataSource.markAllAsRead()).thenAnswer((_) async => 10);

        // Act
        final result = await repository.markAllAsRead();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (count) => expect(count, equals(10)),
        );
        verify(() => mockDataSource.markAllAsRead()).called(1);
      });

      test('should return zero when no notifications to mark', () async {
        // Arrange
        when(() => mockDataSource.markAllAsRead()).thenAnswer((_) async => 0);

        // Act
        final result = await repository.markAllAsRead();

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (count) => expect(count, equals(0)),
        );
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.markAllAsRead(),
          ).thenThrow(Exception('Batch update failed'));

          // Act
          final result = await repository.markAllAsRead();

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to mark all as read'));
            expect(failure.message, contains('Batch update failed'));
          }, (count) => fail('Should return Left but got Right'));
        },
      );
    });

    group('deleteNotification', () {
      test('should successfully delete notification', () async {
        // Arrange
        when(
          () => mockDataSource.deleteNotification(
            notificationId: any(named: 'notificationId'),
          ),
        ).thenAnswer((_) async => Future.value());

        // Act
        final result = await repository.deleteNotification(
          notificationId: testNotificationId,
        );

        // Assert
        expect(result.isRight(), true);
        verify(
          () => mockDataSource.deleteNotification(
            notificationId: testNotificationId,
          ),
        ).called(1);
      });

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.deleteNotification(
              notificationId: any(named: 'notificationId'),
            ),
          ).thenThrow(Exception('Delete failed'));

          // Act
          final result = await repository.deleteNotification(
            notificationId: testNotificationId,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(failure.message, contains('Failed to delete notification'));
            expect(failure.message, contains('Delete failed'));
          }, (value) => fail('Should return Left but got Right'));
        },
      );
    });

    group('getUnreadNotifications', () {
      test('should return only unread notifications', () async {
        // Arrange
        final unreadNotifications = testNotifications
            .where((notif) => !notif.isRead)
            .toList();

        when(
          () => mockDataSource.getUnreadNotifications(
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) async => unreadNotifications);

        // Act
        final result = await repository.getUnreadNotifications(
          userId: testUserId,
        );

        // Assert
        expect(result.isRight(), true);
        result.fold(
          (failure) => fail('Should return Right but got Left: $failure'),
          (notifications) {
            expect(notifications, hasLength(2));
            expect(notifications.every((n) => !n.isRead), true);
          },
        );
        verify(
          () => mockDataSource.getUnreadNotifications(userId: testUserId),
        ).called(1);
      });

      test(
        'should return empty list when all notifications are read',
        () async {
          // Arrange
          when(
            () => mockDataSource.getUnreadNotifications(
              userId: any(named: 'userId'),
            ),
          ).thenAnswer((_) async => []);

          // Act
          final result = await repository.getUnreadNotifications(
            userId: testUserId,
          );

          // Assert
          expect(result.isRight(), true);
          result.fold(
            (failure) => fail('Should return Right but got Left: $failure'),
            (notifications) => expect(notifications, isEmpty),
          );
        },
      );

      test(
        'should return ServerFailure when datasource throws exception',
        () async {
          // Arrange
          when(
            () => mockDataSource.getUnreadNotifications(
              userId: any(named: 'userId'),
            ),
          ).thenThrow(Exception('Query error'));

          // Act
          final result = await repository.getUnreadNotifications(
            userId: testUserId,
          );

          // Assert
          expect(result.isLeft(), true);
          result.fold((failure) {
            expect(failure, isA<ServerFailure>());
            expect(
              failure.message,
              contains('Failed to get unread notifications'),
            );
            expect(failure.message, contains('Query error'));
          }, (notifications) => fail('Should return Left but got Right'));
        },
      );
    });
  });
}
