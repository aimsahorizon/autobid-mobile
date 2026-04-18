import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/guest/domain/entities/account_status_entity.dart';
import 'package:autobid_mobile/modules/guest/domain/repositories/guest_repository.dart';

/// UseCase for checking account status by email or username
class CheckAccountStatusUseCase {
  final GuestRepository repository;

  CheckAccountStatusUseCase(this.repository);

  Future<Either<Failure, AccountStatusEntity?>> call(String identifier) {
    return repository.checkAccountStatus(identifier);
  }
}
