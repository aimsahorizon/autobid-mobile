class UserEntity {
  final String id;
  final String email;
  final String? username;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;

  const UserEntity({
    required this.id,
    required this.email,
    this.username,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
  });
}
