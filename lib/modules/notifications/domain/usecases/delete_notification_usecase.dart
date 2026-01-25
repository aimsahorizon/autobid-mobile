import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// UseCase for deleting a notification
class DeleteNotificationUseCase {
  final NotificationRepository repository;

  DeleteNotificationUseCase(this.repository);

  Future<Either<Failure, void>> call({required String notificationId}) {
    return repository.deleteNotification(notificationId: notificationId);
  }
}
