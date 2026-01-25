import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/get_unread_count_usecase.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late GetUnreadCountUseCase useCase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    useCase = GetUnreadCountUseCase(mockRepository);
  });

  group('GetUnreadCountUseCase', () {
    const testUserId = 'test-user-id';

    test('should return unread count when successful', () async {
      // Arrange
      const expectedCount = 5;
      when(
        () => mockRepository.getUnreadCount(userId: any(named: 'userId')),
      ).thenAnswer((_) async => const Right(expectedCount));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(const Right(expectedCount)));
      verify(() => mockRepository.getUnreadCount(userId: testUserId)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return zero when user has no unread notifications', () async {
      // Arrange
      when(
        () => mockRepository.getUnreadCount(userId: any(named: 'userId')),
      ).thenAnswer((_) async => const Right(0));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(const Right(0)));
    });

    test('should return ServerFailure when repository fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to fetch count');
      when(
        () => mockRepository.getUnreadCount(userId: any(named: 'userId')),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(Left(failure)));
      verify(() => mockRepository.getUnreadCount(userId: testUserId)).called(1);
    });

    test('should handle large unread counts correctly', () async {
      // Arrange
      const largeCount = 9999;
      when(
        () => mockRepository.getUnreadCount(userId: any(named: 'userId')),
      ).thenAnswer((_) async => const Right(largeCount));

      // Act
      final result = await useCase(userId: testUserId);

      // Assert
      expect(result, equals(const Right(largeCount)));
    });

    test('should pass correct user ID to repository', () async {
      // Arrange
      const specificUserId = 'specific-user-id-789';
      when(
        () => mockRepository.getUnreadCount(userId: any(named: 'userId')),
      ).thenAnswer((_) async => const Right(3));

      // Act
      await useCase(userId: specificUserId);

      // Assert
      verify(
        () => mockRepository.getUnreadCount(userId: specificUserId),
      ).called(1);
    });
  });
}
