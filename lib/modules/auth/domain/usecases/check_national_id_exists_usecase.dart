import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class CheckNationalIdExistsUseCase {
  final AuthRepository repository;

  CheckNationalIdExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String idNumber) {
    return repository.checkNationalIdExists(idNumber);
  }
}
