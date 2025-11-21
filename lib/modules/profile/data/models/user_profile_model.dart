import '../../domain/entities/user_profile_entity.dart';

/// Data model for user profile that handles JSON serialization
class UserProfileModel extends UserProfileEntity {
  const UserProfileModel({
    required super.id,
    required super.coverPhotoUrl,
    required super.profilePhotoUrl,
    required super.fullName,
    required super.username,
    required super.contactNumber,
    required super.email,
  });

  /// Create model from JSON (Supabase response)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      coverPhotoUrl: json['cover_photo_url'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      contactNumber: json['contact_number'] as String,
      email: json['email'] as String,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cover_photo_url': coverPhotoUrl,
      'profile_photo_url': profilePhotoUrl,
      'full_name': fullName,
      'username': username,
      'contact_number': contactNumber,
      'email': email,
    };
  }
}
