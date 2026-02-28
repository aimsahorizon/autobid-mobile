import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/mark_all_as_read_usecase.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MarkAllAsReadUseCase useCase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    useCase = MarkAllAsReadUseCase(mockRepository);
  });

  group('MarkAllAsReadUseCase', () {
    test('should mark all notifications as read successfully', () async {
      // Arrange
      const expectedCount = 5;
      when(
        () => mockRepository.markAllAsRead(),
      ).thenAnswer((_) async => const Right(expectedCount));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right(expectedCount)));
      verify(() => mockRepository.markAllAsRead()).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when operation fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to mark all as read');
      when(
        () => mockRepository.markAllAsRead(),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(Left(failure)));
      verify(() => mockRepository.markAllAsRead()).called(1);
    });

    test('should work without user ID parameter', () async {
      // Arrange
      const expectedCount = 3;
      when(
        () => mockRepository.markAllAsRead(),
      ).thenAnswer((_) async => const Right(expectedCount));

      // Act
      await useCase();

      // Assert
      verify(() => mockRepository.markAllAsRead()).called(1);
    });

    test('should handle user with no notifications gracefully', () async {
      // Arrange - even if user has no notifications, should succeed with count 0
      when(
        () => mockRepository.markAllAsRead(),
      ).thenAnswer((_) async => const Right(0));

      // Act
      final result = await useCase();

      // Assert
      expect(result, equals(const Right(0)));
    });
  });
}
