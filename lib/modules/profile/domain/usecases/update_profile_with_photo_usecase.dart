import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';

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
      profilePhotoUrl: profilePhotoUrl ?? profile.profilePhotoUrl,
      coverPhotoUrl: coverPhotoUrl ?? profile.coverPhotoUrl,
    );

    return await _repository.updateProfile(updatedProfile);
  }
}
