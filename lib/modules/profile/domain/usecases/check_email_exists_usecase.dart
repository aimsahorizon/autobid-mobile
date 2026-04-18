import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';

class CheckEmailExistsUseCase {
  final ProfileRepository repository;

  CheckEmailExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String email) {
    return repository.checkEmailExists(email);
  }
}
