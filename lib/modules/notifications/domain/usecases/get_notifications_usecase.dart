import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/entities/notification_entity.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';

/// UseCase for getting all notifications for a user
class GetNotificationsUseCase {
  final NotificationRepository repository;

  GetNotificationsUseCase(this.repository);

  Future<Either<Failure, List<NotificationEntity>>> call({
    required String userId,
    int? limit,
    int? offset,
  }) {
    return repository.getNotifications(
      userId: userId,
      limit: limit,
      offset: offset,
    );
  }
}
