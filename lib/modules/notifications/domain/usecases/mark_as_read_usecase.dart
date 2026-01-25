import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// UseCase for marking a notification as read
class MarkAsReadUseCase {
  final NotificationRepository repository;

  MarkAsReadUseCase(this.repository);

  Future<Either<Failure, void>> call({required String notificationId}) {
    return repository.markAsRead(notificationId: notificationId);
  }
}
