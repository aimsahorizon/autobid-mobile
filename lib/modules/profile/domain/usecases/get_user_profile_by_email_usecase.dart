import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/user_profile_entity.dart';
import '../repositories/profile_repository.dart';

class GetUserProfileByEmailUseCase {
  final ProfileRepository repository;

  GetUserProfileByEmailUseCase(this.repository);

  Future<Either<Failure, UserProfileEntity?>> call(String email) {
    return repository.getUserProfileByEmail(email);
  }
}
