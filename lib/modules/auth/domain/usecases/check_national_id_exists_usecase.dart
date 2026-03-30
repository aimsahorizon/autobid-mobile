import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class CheckNationalIdExistsUseCase {
  final AuthRepository repository;

  CheckNationalIdExistsUseCase(this.repository);

  Future<Either<Failure, bool>> call(String idNumber) {
    return repository.checkNationalIdExists(idNumber);
  }
}
