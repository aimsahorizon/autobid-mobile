import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/user_profile_entity.dart';

/// Abstract repository for profile operations
abstract class ProfileRepository {
  /// Get current user profile
  Future<Either<Failure, UserProfileEntity>> getUserProfile();

  /// Get user profile by email (Used by Auth)
  Future<Either<Failure, UserProfileEntity?>> getUserProfileByEmail(String email);

  /// Check if email exists (Used by Auth)
  Future<Either<Failure, bool>> checkEmailExists(String email);

  /// Update user profile
  Future<Either<Failure, UserProfileEntity>> updateProfile(UserProfileEntity profile);

  /// Sign out user
  Future<Either<Failure, void>> signOut();
}