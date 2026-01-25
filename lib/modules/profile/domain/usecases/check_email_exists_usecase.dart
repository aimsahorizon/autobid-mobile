import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../repositories/profile_repository.dart';

class CheckEmailExistsUseCase {
  final ProfileRepository repository;

  CheckEmailExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String email) {
    return repository.checkEmailExists(email);
  }
}
