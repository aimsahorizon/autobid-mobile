import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/core/network/network_info.dart';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_supabase_datasource.dart';

/// Supabase implementation of ProfileRepository
/// Handles user profile operations with real Supabase backend
class ProfileRepositorySupabaseImpl implements ProfileRepository {
  final ProfileSupabaseDataSource _dataSource;
  final NetworkInfo networkInfo;

  ProfileRepositorySupabaseImpl(this._dataSource, this.networkInfo);

  @override
  Future<Either<Failure, UserProfileEntity>> getUserProfile() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      // Check if user is authenticated
      final currentUser = SupabaseConfig.currentUser;
      if (currentUser == null) {
        return const Left(
          AuthFailure('No authenticated user found. Please login first.'),
        );
      }

      // Fetch profile data from users table
      final profile = await _dataSource.getUserProfile(currentUser.id);

      // Check if profile exists
      if (profile == null) {
        return const Left(
          GeneralFailure(
            'Profile not found. Please ensure you have completed KYC registration.',
          ),
        );
      }

      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity>> updateProfile(
    UserProfileEntity profile,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      // Convert entity to model for datasource
      final updated = await _dataSource.updateProfile(
        userId: profile.id,
        fullName: profile.fullName,
        username: profile.username,
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
    // Sign out should be possible locally
    try {
      await SupabaseConfig.client.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserProfileEntity?>> getUserProfileByEmail(
    String email,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final profile = await _dataSource.getUserProfileByEmail(email);
      return Right(profile);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkEmailExists(String email) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final exists = await _dataSource.checkEmailExists(email);
      return Right(exists);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadProfilePhoto(
    String userId,
    File imageFile,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final photoUrl = await _dataSource.uploadProfilePhoto(userId, imageFile);
      return Right(photoUrl);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadCoverPhoto(
    String userId,
    File imageFile,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final photoUrl = await _dataSource.uploadCoverPhoto(userId, imageFile);
      return Right(photoUrl);
    } catch (e) {
      return Left(GeneralFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await _dataSource.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(GeneralFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
