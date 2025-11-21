import '../entities/user_profile_entity.dart';

/// Abstract repository for profile operations
abstract class ProfileRepository {
  /// Get current user profile
  Future<UserProfileEntity> getUserProfile();

  /// Update user profile
  Future<UserProfileEntity> updateProfile(UserProfileEntity profile);

  /// Sign out user
  Future<void> signOut();
}
