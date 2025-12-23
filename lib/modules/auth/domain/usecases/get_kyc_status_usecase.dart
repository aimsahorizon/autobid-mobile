import '../entities/kyc_registration_entity.dart';
import '../repositories/auth_repository.dart';

class GetKycStatusUseCase {
  final AuthRepository repository;

  GetKycStatusUseCase(this.repository);

  Future<KycRegistrationEntity?> call(String userId) async {
    return await repository.getKycRegistrationStatus(userId);
  }
}
