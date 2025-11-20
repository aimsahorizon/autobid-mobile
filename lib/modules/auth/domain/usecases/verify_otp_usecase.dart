import '../repositories/auth_repository.dart';

class VerifyOtpUseCase {
  final AuthRepository repository;

  VerifyOtpUseCase(this.repository);

  Future<bool> call(String username, String otp) {
    return repository.verifyOtp(username, otp);
  }
}
