import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';

/// Use case to get the current user's profile
class GetUserProfileUseCase {
  final ProfileRepository repository;

  GetUserProfileUseCase(this.repository);

  Future<Either<Failure, UserProfileEntity>> call() {
    return repository.getUserProfile();
  }
}
