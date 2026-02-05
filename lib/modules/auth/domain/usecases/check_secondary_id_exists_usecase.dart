import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class CheckSecondaryIdExistsUseCase {
  final AuthRepository repository;

  CheckSecondaryIdExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String idNumber, String type) {
    return repository.checkSecondaryIdExists(idNumber, type);
  }
}
