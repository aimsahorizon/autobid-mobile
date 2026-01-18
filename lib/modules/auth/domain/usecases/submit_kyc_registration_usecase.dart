import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/kyc_registration_entity.dart';
import '../repositories/auth_repository.dart';

class SubmitKycRegistrationUseCase {
  final AuthRepository repository;

  SubmitKycRegistrationUseCase(this.repository);

  Future<Either<Failure, void>> call(KycRegistrationEntity kycData) {
    return repository.submitKycRegistration(kycData);
  }
}