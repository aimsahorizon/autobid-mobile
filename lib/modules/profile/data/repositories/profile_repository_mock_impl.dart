import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_mock_datasource.dart';
import '../models/user_profile_model.dart';

/// Mock implementation of ProfileRepository
class ProfileRepositoryMockImpl implements ProfileRepository {
  final ProfileMockDataSource _mockDataSource;

  ProfileRepositoryMockImpl(this._mockDataSource);

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile() async {
    try {
      final profile = await _mockDataSource.getUserProfile();
      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateProfile(UserProfileEntity profile) async {
    try {
      final model = UserProfileModel(
        id: profile.id,
        coverPhotoUrl: profile.coverPhotoUrl,
        profilePhotoUrl: profile.profilePhotoUrl,
        fullName: profile.fullName,
        username: profile.username,
        contactNumber: profile.contactNumber,
        email: profile.email,
      );
      final updated = await _mockDataSource.updateProfile(model);
      return Right(updated);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      // Mock sign out - just delay
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity?>> getUserProfileByEmail(String email) async {
    try {
      final profile = await _mockDataSource.getUserProfile();
      if (profile.email == email) {
        return Right(profile);
      }
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    try {
      final profile = await _mockDataSource.getUserProfile();
      return Right(profile.email == email);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }
}