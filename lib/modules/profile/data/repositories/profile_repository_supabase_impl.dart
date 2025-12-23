import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_supabase_datasource.dart';
import '../../../../app/core/config/supabase_config.dart';

/// Supabase implementation of ProfileRepository
/// Handles user profile operations with real Supabase backend
class ProfileRepositorySupabaseImpl implements ProfileRepository {
  final ProfileSupabaseDataSource _dataSource;

  ProfileRepositorySupabaseImpl(this._dataSource);

  @override
  Future<UserProfileEntity> getUserProfile() async {
    // Check if user is authenticated
    final currentUser = SupabaseConfig.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found. Please login first.');
    }

    // Fetch profile data from users table (uses email internally)
    final profile = await _dataSource.getUserProfile(currentUser.id);

    // Check if profile exists in database
    if (profile == null) {
      throw Exception('Profile not found. Please ensure you have completed KYC registration.');
    }

    return profile;
  }

  @override
  Future<UserProfileEntity> updateProfile(UserProfileEntity profile) async {
    // Convert entity to model for datasource
    final updated = await _dataSource.updateProfile(
      userId: profile.id,
      fullName: profile.fullName,
      username: profile.username,
      contactNumber: profile.contactNumber,
      coverPhotoUrl: profile.coverPhotoUrl,
      profilePhotoUrl: profile.profilePhotoUrl,
    );

    return updated;
  }

  @override
  Future<void> signOut() async {
    // Sign out from Supabase
    await SupabaseConfig.client.auth.signOut();
  }
}
