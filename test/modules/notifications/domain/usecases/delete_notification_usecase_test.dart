import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';
import 'package:autobid_mobile/modules/notifications/domain/usecases/delete_notification_usecase.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

void main() {
  late DeleteNotificationUseCase useCase;
  late MockNotificationRepository mockRepository;

  setUp(() {
    mockRepository = MockNotificationRepository();
    useCase = DeleteNotificationUseCase(mockRepository);
  });

  group('DeleteNotificationUseCase', () {
    const testNotificationId = 'notification-123';

    test('should delete notification successfully', () async {
      // Arrange
      when(
        () => mockRepository.deleteNotification(
          notificationId: any(named: 'notificationId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      // Act
      final result = await useCase(notificationId: testNotificationId);

      // Assert
      expect(result, equals(const Right(unit)));
      verify(
        () => mockRepository.deleteNotification(
          notificationId: testNotificationId,
        ),
      ).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when deletion fails', () async {
      // Arrange
      const failure = ServerFailure('Failed to delete notification');
      when(
        () => mockRepository.deleteNotification(
          notificationId: any(named: 'notificationId'),
        ),
      ).thenAnswer((_) async => Left(failure));

      // Act
      final result = await useCase(notificationId: testNotificationId);

      // Assert
      expect(result, equals(Left(failure)));
      verify(
        () => mockRepository.deleteNotification(
          notificationId: testNotificationId,
        ),
      ).called(1);
    });

    test(
      'should return NotFoundFailure when notification does not exist',
      () async {
        // Arrange
        const failure = NotFoundFailure('Notification not found');
        when(
          () => mockRepository.deleteNotification(
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
      const specificId = 'specific-notification-id-456';
      when(
        () => mockRepository.deleteNotification(
          notificationId: any(named: 'notificationId'),
        ),
      ).thenAnswer((_) async => const Right(unit));

      // Act
      await useCase(notificationId: specificId);

      // Assert
      verify(
        () => mockRepository.deleteNotification(notificationId: specificId),
      ).called(1);
    });

    test(
      'should return PermissionFailure when user lacks permission',
      () async {
        // Arrange
        const failure = PermissionFailure('Not authorized to delete');
        when(
          () => mockRepository.deleteNotification(
            notificationId: any(named: 'notificationId'),
          ),
        ).thenAnswer((_) async => Left(failure));

        // Act
        final result = await useCase(notificationId: testNotificationId);

        // Assert
        expect(result, equals(Left(failure)));
      },
    );
  });
}
