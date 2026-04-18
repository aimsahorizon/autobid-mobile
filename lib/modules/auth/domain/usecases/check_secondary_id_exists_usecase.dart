import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class CheckSecondaryIdExistsUseCase {
  final AuthRepository repository;

  CheckSecondaryIdExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String idNumber, String type) {
    return repository.checkSecondaryIdExists(idNumber, type);
  }
}
