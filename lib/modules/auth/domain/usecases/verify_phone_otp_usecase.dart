import '../repositories/auth_repository.dart';

/// Use case for verifying phone OTP during registration
class VerifyPhoneOtpUseCase {
  final AuthRepository repository;

  VerifyPhoneOtpUseCase(this.repository);

  Future<bool> call(String phoneNumber, String otp) {
    return repository.verifyPhoneOtp(phoneNumber, otp);
  }
}
