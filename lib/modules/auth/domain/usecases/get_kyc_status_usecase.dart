import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/kyc_registration_entity.dart';
import '../repositories/auth_repository.dart';

class GetKycRegistrationStatusUseCase {
  final AuthRepository repository;

  GetKycRegistrationStatusUseCase(this.repository);

  Future<Either<Failure, KycRegistrationEntity?>> call(String userId) {
    return repository.getKycRegistrationStatus(userId);
  }
}