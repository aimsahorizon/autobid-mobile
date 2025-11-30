import '../../domain/entities/user_entity.dart';
import '../../domain/entities/kyc_registration_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/kyc_registration_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> getCurrentUser() {
    return remoteDataSource.getCurrentUser();
  }

  @override
  Future<UserEntity> signInWithUsername(String username, String password) {
    return remoteDataSource.signInWithUsername(username, password);
  }

  @override
  Future<UserEntity> signInWithGoogle() {
    return remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetRequest(String username) {
    return remoteDataSource.sendPasswordResetRequest(username);
  }

  @override
  Future<bool> verifyOtp(String username, String otp) {
    return remoteDataSource.verifyOtp(username, otp);
  }

  @override
  Future<UserEntity> signUp(String email, String password, {String? username}) {
    return remoteDataSource.signUp(email, password, username: username);
  }

  @override
  Future<void> sendEmailOtp(String email) {
    return remoteDataSource.sendEmailOtp(email);
  }

  @override
  Future<void> sendPhoneOtp(String phoneNumber) {
    return remoteDataSource.sendPhoneOtp(phoneNumber);
  }

  @override
  Future<bool> verifyEmailOtp(String email, String otp) {
    return remoteDataSource.verifyEmailOtp(email, otp);
  }

  @override
  Future<bool> verifyPhoneOtp(String phoneNumber, String otp) {
    return remoteDataSource.verifyPhoneOtp(phoneNumber, otp);
  }

  @override
  Future<void> submitKycRegistration(KycRegistrationEntity kycData) {
    // Convert entity to model for data layer
    final kycModel = KycRegistrationModel(
      id: kycData.id,
      email: kycData.email,
      phoneNumber: kycData.phoneNumber,
      username: kycData.username,
      firstName: kycData.firstName,
      lastName: kycData.lastName,
      middleName: kycData.middleName,
      dateOfBirth: kycData.dateOfBirth,
      sex: kycData.sex,
      region: kycData.region,
      province: kycData.province,
      city: kycData.city,
      barangay: kycData.barangay,
      streetAddress: kycData.streetAddress,
      zipcode: kycData.zipcode,
      nationalIdNumber: kycData.nationalIdNumber,
      nationalIdFrontUrl: kycData.nationalIdFrontUrl,
      nationalIdBackUrl: kycData.nationalIdBackUrl,
      secondaryGovIdType: kycData.secondaryGovIdType,
      secondaryGovIdNumber: kycData.secondaryGovIdNumber,
      secondaryGovIdFrontUrl: kycData.secondaryGovIdFrontUrl,
      secondaryGovIdBackUrl: kycData.secondaryGovIdBackUrl,
      proofOfAddressType: kycData.proofOfAddressType,
      proofOfAddressUrl: kycData.proofOfAddressUrl,
      selfieWithIdUrl: kycData.selfieWithIdUrl,
      acceptedTermsAt: kycData.acceptedTermsAt,
      acceptedPrivacyAt: kycData.acceptedPrivacyAt,
      status: kycData.status,
      reviewedBy: kycData.reviewedBy,
      reviewedAt: kycData.reviewedAt,
      rejectionReason: kycData.rejectionReason,
      adminNotes: kycData.adminNotes,
      submittedAt: kycData.submittedAt,
      createdAt: kycData.createdAt,
      updatedAt: kycData.updatedAt,
    );
    return remoteDataSource.submitKycRegistration(kycModel);
  }

  @override
  Future<KycRegistrationEntity?> getKycRegistrationStatus(String userId) {
    return remoteDataSource.getKycRegistrationStatus(userId);
  }

  @override
  Future<bool> checkUsernameAvailable(String username) {
    return remoteDataSource.checkUsernameAvailable(username);
  }
}
