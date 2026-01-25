import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/account_status_entity.dart';
import '../repositories/guest_repository.dart';

/// UseCase for checking account status by email
class CheckAccountStatusUseCase {
  final GuestRepository repository;

  CheckAccountStatusUseCase(this.repository);

  Future<Either<Failure, AccountStatusEntity?>> call(String email) {
    return repository.checkAccountStatus(email);
  }
}
