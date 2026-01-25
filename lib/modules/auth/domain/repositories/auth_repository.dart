import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/user_entity.dart';
import '../entities/kyc_registration_entity.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity?>> getCurrentUser();
  Future<Either<Failure, UserEntity>> signInWithUsername(String username, String password);
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> sendPasswordResetRequest(String username);
  Future<Either<Failure, bool>> verifyOtp(String username, String otp);
  Future<Either<Failure, void>> resetPassword(String username, String newPassword);
  Future<Either<Failure, UserEntity>> signUp(String email, String password, {String? username});

  // OTP methods for registration flow
  Future<Either<Failure, void>> sendEmailOtp(String email);
  Future<Either<Failure, void>> sendPhoneOtp(String phoneNumber);
  Future<Either<Failure, bool>> verifyEmailOtp(String email, String otp);
  Future<Either<Failure, bool>> verifyPhoneOtp(String phoneNumber, String otp);

  // KYC Registration methods
  Future<Either<Failure, void>> submitKycRegistration(KycRegistrationEntity kycData);
  Future<Either<Failure, KycRegistrationEntity?>> getKycRegistrationStatus(String userId);
  Future<Either<Failure, bool>> checkUsernameAvailable(String username);
}