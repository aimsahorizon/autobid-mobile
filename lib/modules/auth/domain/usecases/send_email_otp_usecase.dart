import '../repositories/auth_repository.dart';

/// Use case for sending OTP to email during registration
class SendEmailOtpUseCase {
  final AuthRepository repository;

  SendEmailOtpUseCase(this.repository);

  Future<void> call(String email) async {
    // Supabase sends OTP automatically when you call signInWithOtp
    // This is a wrapper around the repository method
    return repository.sendEmailOtp(email);
  }
}
