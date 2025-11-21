import 'package:flutter/material.dart';
import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileController extends ChangeNotifier {
  final ProfileRepository _repository;

  ProfileController(this._repository);

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

    try {
      _profile = await _repository.getUserProfile();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load profile';
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.signOut();
      _profile = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
