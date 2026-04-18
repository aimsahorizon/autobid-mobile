import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';

/// UseCase for marking all notifications as read
class MarkAllAsReadUseCase {
  final NotificationRepository repository;

  MarkAllAsReadUseCase(this.repository);

  Future<Either<Failure, int>> call() {
    return repository.markAllAsRead();
  }
}
