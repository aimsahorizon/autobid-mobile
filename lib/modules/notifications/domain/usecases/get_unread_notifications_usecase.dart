import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

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
