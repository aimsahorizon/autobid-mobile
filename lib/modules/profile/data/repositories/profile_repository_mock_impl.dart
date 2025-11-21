import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_mock_datasource.dart';
import '../models/user_profile_model.dart';

/// Mock implementation of ProfileRepository
class ProfileRepositoryMockImpl implements ProfileRepository {
  final ProfileMockDataSource _mockDataSource;

  ProfileRepositoryMockImpl(this._mockDataSource);

  @override
  Future<UserProfileEntity> getUserProfile() async {
    return await _mockDataSource.getUserProfile();
  }

  @override
  Future<UserProfileEntity> updateProfile(UserProfileEntity profile) async {
    final model = UserProfileModel(
      id: profile.id,
      coverPhotoUrl: profile.coverPhotoUrl,
      profilePhotoUrl: profile.profilePhotoUrl,
      fullName: profile.fullName,
      username: profile.username,
      contactNumber: profile.contactNumber,
      email: profile.email,
    );
    return await _mockDataSource.updateProfile(model);
  }

  @override
  Future<void> signOut() async {
    // Mock sign out - just delay
    await Future.delayed(const Duration(milliseconds: 300));
  }
}
