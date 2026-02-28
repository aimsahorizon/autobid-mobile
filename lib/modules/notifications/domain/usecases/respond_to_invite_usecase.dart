import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

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
