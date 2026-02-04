import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ManageLocalAuthUseCase {
  final AuthRepository _repository;

  ManageLocalAuthUseCase(this._repository);

  Future<Either<Failure, void>> cacheRememberMe(bool value) {
    return _repository.cacheRememberMe(value);
  }

  Future<Either<Failure, bool>> getRememberMe() {
    return _repository.getRememberMe();
  }

  Future<Either<Failure, void>> cacheUsername(String username) {
    return _repository.cacheUsername(username);
  }

  Future<Either<Failure, String?>> getCachedUsername() {
    return _repository.getCachedUsername();
  }

  Future<Either<Failure, void>> clearCachedUsername() {
    return _repository.clearCachedUsername();
  }
}
