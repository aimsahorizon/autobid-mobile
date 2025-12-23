import '../models/user_profile_model.dart';

/// Mock data source for user profile
class ProfileMockDataSource {
  /// Simulated network delay
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// Mock user profile data
  static const _mockProfile = UserProfileModel(
    id: 'user_001',
    coverPhotoUrl: 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=1200',
    profilePhotoUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
    fullName: 'Juan Dela Cruz',
    username: '@juandelacruz',
    contactNumber: '+63 917 123 4567',
    email: 'juan.delacruz@email.com',
  );

  /// Get current user profile
  Future<UserProfileModel> getUserProfile() async {
    await _simulateDelay();
    return _mockProfile;
  }

  /// Update user profile
  Future<UserProfileModel> updateProfile(UserProfileModel profile) async {
    await _simulateDelay();
    return profile;
  }
}
