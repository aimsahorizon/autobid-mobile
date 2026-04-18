import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';

/// UseCase for uploading profile photo
class UploadProfilePhotoUseCase {
  final ProfileRepository _repository;

  UploadProfilePhotoUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String userId,
    required File imageFile,
  }) async {
    return await _repository.uploadProfilePhoto(userId, imageFile);
  }
}
