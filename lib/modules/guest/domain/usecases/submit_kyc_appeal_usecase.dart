import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/guest_repository.dart';

class SubmitKycAppealUseCase {
  final GuestRepository repository;

  SubmitKycAppealUseCase(this.repository);

  Future<Either<Failure, void>> call(String userId, String appealReason) {
    return repository.submitKycAppeal(userId, appealReason);
  }
}
