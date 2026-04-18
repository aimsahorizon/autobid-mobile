import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';

/// UseCase for getting count of unread notifications
class GetUnreadCountUseCase {
  final NotificationRepository repository;

  GetUnreadCountUseCase(this.repository);

  Future<Either<Failure, int>> call({required String userId}) {
    return repository.getUnreadCount(userId: userId);
  }
}
