import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_supabase_datasource.dart';

/// Supabase implementation of ProfileRepository
/// Handles user profile operations with real Supabase backend
class ProfileRepositorySupabaseImpl implements ProfileRepository {
  final ProfileSupabaseDataSource _dataSource;

  ProfileRepositorySupabaseImpl(this._dataSource);

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile() async {
    try {
      // Check if user is authenticated
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        return const Left(AuthFailure('No authenticated user found. Please login first.'));
      }

      // Fetch profile data from users table
      final profile = await _dataSource.getUserProfile(currentUser.id);

      // Check if profile exists
      if (profile == null) {
        return const Left(GeneralFailure('Profile not found. Please ensure you have completed KYC registration.'));
      }

      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateProfile(UserProfileEntity profile) async {
    try {
      // Convert entity to model for datasource
      final updated = await _dataSource.updateProfile(
        userId: profile.id,
        fullName: profile.fullName,
        username: profile.username,
        contactNumber: profile.contactNumber,
        coverPhotoUrl: profile.coverPhotoUrl,
        profilePhotoUrl: profile.profilePhotoUrl,
      );

      return Right(updated);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity?>> getUserProfileByEmail(String email) async {
    try {
      final profile = await _dataSource.getUserProfileByEmail(email);
      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    try {
      final exists = await _dataSource.checkEmailExists(email);
      return Right(exists);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }
}