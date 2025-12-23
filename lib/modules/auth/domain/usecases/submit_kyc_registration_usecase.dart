import '../entities/kyc_registration_entity.dart';
import '../repositories/auth_repository.dart';

class SubmitKycRegistrationUseCase {
  final AuthRepository repository;

  SubmitKycRegistrationUseCase(this.repository);

  Future<void> call(KycRegistrationEntity kycData) async {
    return await repository.submitKycRegistration(kycData);
  }
}
