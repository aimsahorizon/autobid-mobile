import 'package:flutter/material.dart';

class RegistrationController extends ChangeNotifier {
  // TODO: Inject SignUpUseCase when implementing registration

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

  Future<void> signUp({
    required String email,
    required String username,
    required String password,
    required String confirmPassword,
  }) async {
    // TODO: Implement registration logic
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Validation
    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      _isLoading = false;
      notifyListeners();
      return;
    }

    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
      _isLoading = false;
      notifyListeners();
      return;
    }

    // TODO: Call SignUpUseCase
    await Future.delayed(const Duration(seconds: 2));

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
