import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/error/exceptions.dart';
import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/kyc_registration_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/kyc_registration_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl(this.remoteDataSource, this.networkInfo);

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      if (!await networkInfo.isConnected) {
        // Allow cached user check? Or fail?
        // Supabase might have local session.
      }
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithUsername(
    String username,
    String password,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final user = await remoteDataSource.signInWithUsername(
        username,
        password,
      );
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final user = await remoteDataSource.signInWithGoogle();
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetRequest(
    String username,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.sendPasswordResetRequest(username);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyOtp(String username, String otp) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.verifyOtp(username, otp);
      return Right(result);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
    String username,
    String newPassword,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.resetPassword(username, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp(
    String email,
    String password, {
    String? username,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final user = await remoteDataSource.signUp(
        email,
        password,
        username: username,
      );
      return Right(user);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailOtp(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.sendEmailOtp(email);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendPhoneOtp(String phoneNumber) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.sendPhoneOtp(phoneNumber);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyEmailOtp(String email, String otp) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.verifyEmailOtp(email, otp);
      return Right(result);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> verifyPhoneOtp(
    String phoneNumber,
    String otp,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.verifyPhoneOtp(phoneNumber, otp);
      return Right(result);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, void>> submitKycRegistration(
    KycRegistrationEntity kycData,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final kycModel = KycRegistrationModel(
        id: kycData.id,
        email: kycData.email,
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
      await remoteDataSource.submitKycRegistration(kycModel);
      return const Right(null);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, KycRegistrationEntity?>> getKycRegistrationStatus(
    String userId,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getKycRegistrationStatus(userId);
      return Right(result);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  @override
  Future<Either<Failure, bool>> checkUsernameAvailable(String username) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.checkUsernameAvailable(username);
      return Right(result);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  Failure _handleError(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      
      // DataSource throws "Username not found" when lookup fails
      if (msg.contains('username not found')) {
        return const AuthFailure('Username not found.');
      }

      // DataSource throws this specific string for password failures
      if (msg.contains('invalid username or password')) {
        return const AuthFailure('Incorrect password.');
      }
      
      if (msg.contains('invalid login credentials')) {
        return const AuthFailure('Incorrect password.');
      }

      if (msg.contains('user not found') || msg.contains('not found')) {
        return const AuthFailure('Account does not exist.');
      }
      
      if (msg.contains('email not confirmed')) {
        return const AuthFailure('Please verify your email address.');
      }
      
      if (msg.contains('rate limit')) {
        return const AuthFailure('Too many attempts. Please try again later.');
      }
      
      return AuthFailure(error.message);
    }
    
    if (error is ServerException) {
      return ServerFailure(error.message);
    }
    
    if (error is Exception) {
      return GeneralFailure(error.toString());
    }
    
    return GeneralFailure(error.toString());
  }
}