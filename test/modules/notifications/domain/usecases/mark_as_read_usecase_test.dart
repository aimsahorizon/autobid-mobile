import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/mark_as_read_usecase.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late MarkAsReadUseCase useCase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    useCase = MarkAsReadUseCase(mockRepository);
  });

  group('MarkAsReadUseCase', () {
    const testNotificationId = 'notification-123';

    test('should mark notification as read successfully', () async {
      // Arrange
      when(
        () => mockRepository.markAsRead(
          notificationId: any(named: 'notificationId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(notificationId: testNotificationId);

      // Assert
      expect(result, equals(const Right(unit)));
      verify(
        () => mockRepository.markAsRead(notificationId: testNotificationId),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when marking fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to mark as read');
      when(
        () => mockRepository.markAsRead(
          notificationId: any(named: 'notificationId'),
        ),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(notificationId: testNotificationId);

      // Assert
      expect(result, equals(Left(failure)));
      verify(
        () => mockRepository.markAsRead(notificationId: testNotificationId),
      ).called(1);
    });

    test(
      'should return NotFoundFailure when notification does not exist',
      () async {
        // Arrange
        const failure = NotFoundFailure('Notification not found');
        when(
          () => mockRepository.markAsRead(
            notificationId: any(named: 'notificationId'),
          ),
        ).thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(notificationId: testNotificationId);

        // Assert
        expect(result, equals(Left(failure)));
      },
    );

    test('should pass correct notification ID to repository', () async {
      // Arrange
      const specificId = 'specific-notification-id';
      when(
        () => mockRepository.markAsRead(
          notificationId: any(named: 'notificationId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      // Act
      await useCase(notificationId: specificId);

      // Assert
      verify(
        () => mockRepository.markAsRead(notificationId: specificId),
      ).called(1);
    });
  });
}
