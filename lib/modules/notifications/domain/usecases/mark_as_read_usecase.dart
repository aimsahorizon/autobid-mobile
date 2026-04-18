import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';

/// UseCase for marking a notification as read
class MarkAsReadUseCase {
  final NotificationRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call({required String notificationId}) {
    return repository.markAsRead(notificationId: notificationId);
  }
}
