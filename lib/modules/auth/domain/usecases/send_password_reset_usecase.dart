import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SendPasswordResetUseCase {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  Future<Either<Failure, void>> call(String username) {
    return repository.sendPasswordResetRequest(username);
  }
}