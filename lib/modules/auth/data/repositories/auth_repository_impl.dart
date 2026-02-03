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
        // Can optionally return cached user here if implemented
        // For now, just return NetworkFailure or proceed to try remote?
        // Usually getCurrentUser might check local session first.
        // Supabase remoteDataSource.getCurrentUser() likely checks local session.
        // So we might NOT want to block this one on network check strictly if it's local.
        // However, user asked "offline doesn't make the user in".
        // If session is valid locally, they ARE "in".
        // But "signIn" actions should definitely require network.
      }
      final user = await remoteDataSource.getCurrentUser();
      return Right(user);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    // Sign out should be possible locally even if offline?
    // Supabase signout clears local session.
    try {
      await remoteDataSource.signOut();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
      // Convert entity to model for data layer
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
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
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }
}
