import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../data/datasources/profile_supabase_datasource.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;
  final ProfileSupabaseDataSource _dataSource;

  ProfileController(this._repository, this._dataSource);

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
      // Upload to storage
      final photoUrl = await _dataSource.uploadProfilePhoto(_profile!.id, imageFile);

      // Update in database
      final updatedProfile = await _dataSource.updateProfile(
        userId: _profile!.id,
        profilePhotoUrl: photoUrl,
      );

      _profile = updatedProfile;
      _errorMessage = null;
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
      // Upload to storage
      final photoUrl = await _dataSource.uploadCoverPhoto(_profile!.id, imageFile);

      // Update in database
      final updatedProfile = await _dataSource.updateProfile(
        userId: _profile!.id,
        coverPhotoUrl: photoUrl,
      );

      _profile = updatedProfile;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to update cover photo: $e';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}