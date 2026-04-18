import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class VerifyEmailOtpUseCase {
  final AuthRepository repository;

  VerifyEmailOtpUseCase(this.repository);

  Future<Either<Failure, bool>> call(String email, String otp) {
    return repository.verifyEmailOtp(email, otp);
  }
}