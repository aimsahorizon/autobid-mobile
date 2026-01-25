import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/usecases/upload_profile_photo_usecase.dart';
import '../../domain/usecases/upload_cover_photo_usecase.dart';
import '../../domain/usecases/update_profile_with_photo_usecase.dart';

/// Controller for managing profile state
/// Refactored to use Clean Architecture with UseCases
class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;
  final UploadProfilePhotoUseCase _uploadProfilePhotoUseCase;
  final UploadCoverPhotoUseCase _uploadCoverPhotoUseCase;
  final UpdateProfileWithPhotoUseCase _updateProfileWithPhotoUseCase;

  ProfileController({
    required ProfileRepository repository,
    required UploadProfilePhotoUseCase uploadProfilePhotoUseCase,
    required UploadCoverPhotoUseCase uploadCoverPhotoUseCase,
    required UpdateProfileWithPhotoUseCase updateProfileWithPhotoUseCase,
  }) : _repository = repository,
       _uploadProfilePhotoUseCase = uploadProfilePhotoUseCase,
       _uploadCoverPhotoUseCase = uploadCoverPhotoUseCase,
       _updateProfileWithPhotoUseCase = updateProfileWithPhotoUseCase;

  UserProfileEntity? _profile;
  bool _isLoading = false;
  String? _errorMessage;

  UserProfileEntity? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  Future<void> loadProfile() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getUserProfile();

    result.fold(
      (failure) {
        _errorMessage = 'Failed to load profile: ${failure.message}';
        _profile = null;
      },
      (profileData) {
        _profile = profileData;
        _errorMessage = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    final result = await _repository.signOut();

    result.fold(
      (failure) {
        _errorMessage = 'Failed to sign out: ${failure.message}';
      },
      (_) {
        _profile = null;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Upload and update profile photo
  Future<void> updateProfilePhoto(File imageFile) async {
    if (_profile == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload photo using UseCase
      final uploadResult = await _uploadProfilePhotoUseCase(
        userId: _profile!.id,
        imageFile: imageFile,
      );

      await uploadResult.fold(
        (failure) {
          _errorMessage = 'Failed to upload profile photo: ${failure.message}';
          throw Exception(_errorMessage);
        },
        (photoUrl) async {
          // Update profile with new photo URL using UseCase
          final updateResult = await _updateProfileWithPhotoUseCase(
            profile: _profile!,
            profilePhotoUrl: photoUrl,
          );

          updateResult.fold(
            (failure) {
              _errorMessage = 'Failed to update profile: ${failure.message}';
              throw Exception(_errorMessage);
            },
            (updatedProfile) {
              _profile = updatedProfile;
              _errorMessage = null;
            },
          );
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to update profile photo: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload and update cover photo
  Future<void> updateCoverPhoto(File imageFile) async {
    if (_profile == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload photo using UseCase
      final uploadResult = await _uploadCoverPhotoUseCase(
        userId: _profile!.id,
        imageFile: imageFile,
      );

      await uploadResult.fold(
        (failure) {
          _errorMessage = 'Failed to upload cover photo: ${failure.message}';
          throw Exception(_errorMessage);
        },
        (photoUrl) async {
          // Update profile with new photo URL using UseCase
          final updateResult = await _updateProfileWithPhotoUseCase(
            profile: _profile!,
            coverPhotoUrl: photoUrl,
          );

          updateResult.fold(
            (failure) {
              _errorMessage = 'Failed to update profile: ${failure.message}';
              throw Exception(_errorMessage);
            },
            (updatedProfile) {
              _profile = updatedProfile;
              _errorMessage = null;
            },
          );
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to update cover photo: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
