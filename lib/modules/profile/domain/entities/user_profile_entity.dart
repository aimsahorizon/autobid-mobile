/// Represents user profile in the domain layer
class UserProfileEntity {
  final String id;
  final String coverPhotoUrl;
  final String profilePhotoUrl;
  final String fullName;
  final String username;
  final String email;
  final String? province;
  final String? city;
  final String? barangay;

  const UserProfileEntity({
    required this.id,
    required this.coverPhotoUrl,
    required this.profilePhotoUrl,
    required this.fullName,
    required this.username,
    required this.email,
    this.province,
    this.city,
    this.barangay,
  });
}
