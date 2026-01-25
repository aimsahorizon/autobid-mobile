import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

/// UseCase for getting count of unread notifications
class GetUnreadCountUseCase {
  final NotificationRepository repository;

  GetUnreadCountUseCase(this.repository);

  Future<Either<Failure, int>> call({required String userId}) {
    return repository.getUnreadCount(userId: userId);
  }
}
