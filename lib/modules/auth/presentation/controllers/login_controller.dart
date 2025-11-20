import 'package:flutter/material.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

class LoginController extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;

  LoginController({
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
  });

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<void> signIn(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await signInUseCase.call(username, password);
      _isLoading = false;
      notifyListeners();
      // TODO: Navigate to home on success
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Invalid username or password';
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await signInWithGoogleUseCase.call();
      _isLoading = false;
      notifyListeners();
      // TODO: Navigate to home on success
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign in failed';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
