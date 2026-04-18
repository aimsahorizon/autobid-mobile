import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/auth/domain/repositories/auth_repository.dart';

class VerifyPhoneOtpUseCase {
  final AuthRepository repository;

  VerifyPhoneOtpUseCase(this.repository);

  Future<Either<Failure, bool>> call(String phoneNumber, String otp) {
    return repository.verifyPhoneOtp(phoneNumber, otp);
  }
}