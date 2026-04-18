import 'dart:io';
import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/profile/domain/repositories/profile_repository.dart';

/// UseCase for uploading cover photo
class UploadCoverPhotoUseCase {
  final ProfileRepository _repository;

  UploadCoverPhotoUseCase(this._repository);

  Future<Either<Failure, String>> call({
    required String userId,
    required File imageFile,
  }) async {
    return await _repository.uploadCoverPhoto(userId, imageFile);
  }
}
