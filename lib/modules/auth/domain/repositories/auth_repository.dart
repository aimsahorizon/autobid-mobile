import '../entities/user_entity.dart';
import '../entities/kyc_registration_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithUsername(String username, String password);
  Future<UserEntity> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetRequest(String username);
  Future<bool> verifyOtp(String username, String otp);
  Future<UserEntity> signUp(String email, String password, {String? username});

  // OTP methods for registration flow
  Future<void> sendEmailOtp(String email);
  Future<void> sendPhoneOtp(String phoneNumber);
  Future<bool> verifyEmailOtp(String email, String otp);
  Future<bool> verifyPhoneOtp(String phoneNumber, String otp);

  // KYC Registration methods
  Future<void> submitKycRegistration(KycRegistrationEntity kycData);
  Future<KycRegistrationEntity?> getKycRegistrationStatus(String userId);
  Future<bool> checkUsernameAvailable(String username);
}
