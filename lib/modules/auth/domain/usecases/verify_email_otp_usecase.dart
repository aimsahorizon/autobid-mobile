import '../repositories/auth_repository.dart';

/// Use case for verifying email OTP during registration
class VerifyEmailOtpUseCase {
  final AuthRepository repository;

  VerifyEmailOtpUseCase(this.repository);

  Future<bool> call(String email, String otp) {
    return repository.verifyEmailOtp(email, otp);
  }
}
