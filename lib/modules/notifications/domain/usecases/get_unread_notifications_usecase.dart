import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/entities/notification_entity.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';

/// UseCase for getting only unread notifications
class GetUnreadNotificationsUseCase {
  final NotificationRepository repository;

  GetUnreadNotificationsUseCase(this.repository);

  Future<Either<Failure, List<NotificationEntity>>> call({
    required String userId,
  }) {
    return repository.getUnreadNotifications(userId: userId);
  }
}
