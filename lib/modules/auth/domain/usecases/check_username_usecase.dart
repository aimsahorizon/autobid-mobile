import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../repositories/auth_repository.dart';

class CheckUsernameUseCase {
  final AuthRepository repository;

  CheckUsernameUseCase(this.repository);

  Future<Either<Failure, bool>> call(String username) {
    return repository.checkUsernameAvailable(username);
  }
}