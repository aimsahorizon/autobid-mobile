import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

/// UseCase for updating profile with new photo URL
class UpdateProfileWithPhotoUseCase {
  final ProfileRepository _repository;

  UpdateProfileWithPhotoUseCase(this._repository);

  Future<Either<Failure, UserProfileEntity>> call({
    required UserProfileEntity profile,
    String? profilePhotoUrl,
    String? coverPhotoUrl,
  }) async {
    // Create updated profile with new photo URLs
    final updatedProfile = UserProfileEntity(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      username: profile.username,
      contactNumber: profile.contactNumber,
      profilePhotoUrl: profilePhotoUrl ?? profile.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? profile.coverPhotoUrl,
    );

    return await _repository.updateProfile(updatedProfile);
  }
}
