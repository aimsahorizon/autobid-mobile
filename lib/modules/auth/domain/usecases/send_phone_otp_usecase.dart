import '../repositories/auth_repository.dart';

/// Use case for sending OTP to phone number during registration
class SendPhoneOtpUseCase {
  final AuthRepository repository;

  SendPhoneOtpUseCase(this.repository);

  Future<void> call(String phoneNumber) async {
    // Supabase sends OTP automatically when you call signInWithOtp
    // This is a wrapper around the repository method
    return repository.sendPhoneOtp(phoneNumber);
  }
}
