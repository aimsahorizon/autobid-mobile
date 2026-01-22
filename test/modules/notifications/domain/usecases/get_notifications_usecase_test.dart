import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/entities/notification_entity.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/get_notifications_usecase.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late GetNotificationsUseCase useCase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    useCase = GetNotificationsUseCase(mockRepository);
  });

  group('GetNotificationsUseCase', () {
    const testUserId = 'test-user-id';
    final testNotifications = [
      NotificationEntity(
        id: '1',
        userId: testUserId,
        type: NotificationType.bidUpdate,
        priority: NotificationPriority.high,
        title: 'You have been outbid',
        message: 'Another bidder has placed a higher bid',
        isRead: false,
        createdAt: DateTime(2024, 1, 1),
        relatedEntityId: 'auction-123',
        relatedEntityType: 'auction',
      ),
      NotificationEntity(
        id: '2',
        userId: testUserId,
        type: NotificationType.auctionUpdate,
        priority: NotificationPriority.normal,
        title: 'Auction ending soon',
        message: 'Your watched auction ends in 1 hour',
        isRead: true,
        createdAt: DateTime(2024, 1, 2),
        relatedEntityId: 'auction-456',
        relatedEntityType: 'auction',
      ),
    ];

    test('should return list of notifications when successful', () async {
      // Arrange
      when(
        () => mockRepository.getNotifications(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Right(testNotifications));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(Right(testNotifications)));
      verify(
        () => mockRepository.getNotifications(
          userId: testUserId,
          limit: null,
          offset: null,
        ),
      ).called(1);
    });

    test('should pass limit and offset parameters correctly', () async {
      // Arrange
      const limit = 20;
      const offset = 10;
      when(
        () => mockRepository.getNotifications(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Right(testNotifications));

      // Act
      await useCase(userId: testUserId, limit: limit, offset: offset);

      // Assert
      verify(
        () => mockRepository.getNotifications(
          userId: testUserId,
          limit: limit,
          offset: offset,
        ),
      ).called(1);
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch notifications');
      when(
        () => mockRepository.getNotifications(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(Left(failure)));
    });

    test('should return empty list when no notifications exist', () async {
      // Arrange
      when(
        () => mockRepository.getNotifications(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should not return failure'),
        (r) => expect(r, isEmpty),
      );
    });

    test('should return NetworkFailure when network error occurs', () async {
      // Arrange
      const failure = NetworkFailure('No internet connection');
      when(
        () => mockRepository.getNotifications(
          userId: any(named: 'userId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(Left(failure)));
    });
  });
}
