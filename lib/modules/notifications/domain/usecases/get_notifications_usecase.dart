import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

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
