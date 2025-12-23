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

  /// Create model from JSON (Supabase response from users table)
  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    // Build full name from first, middle, last name fields
    final firstName = json['first_name'] as String? ?? '';
    final middleName = json['middle_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';

    // Combine names with proper spacing
    final fullName = middleName.isNotEmpty
        ? '$firstName $middleName $lastName'
        : '$firstName $lastName';

    return UserProfileModel(
      id: json['id'] as String,
      coverPhotoUrl: json['cover_photo_url'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String? ?? '',
      fullName: fullName.trim(),
      username: json['username'] as String,
      contactNumber: json['phone_number'] as String? ?? '',
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
