import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/notifications/domain/repositories/notification_repository.dart';

class RespondToInviteUseCase {
  final NotificationRepository repository;

  RespondToInviteUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String inviteId,
    required String decision,
  }) async {
    return await repository.respondToInvite(
      inviteId: inviteId,
      decision: decision,
    );
  }
}
