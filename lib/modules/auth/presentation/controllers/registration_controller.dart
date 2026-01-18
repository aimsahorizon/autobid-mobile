import 'package:flutter/material.dart';
import '../../domain/usecases/sign_up_usecase.dart';

class RegistrationController extends ChangeNotifier {
  final SignUpUseCase signUpUseCase;

  RegistrationController({
    required this.signUpUseCase,
  });

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Validation
    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final result = await signUpUseCase.call(
      email: email,
      username: username,
      password: password,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (user) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}