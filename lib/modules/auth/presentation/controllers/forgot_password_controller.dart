import 'package:flutter/material.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';

enum ForgotPasswordStep { enterUsername, verifyOtp, setNewPassword, success }

class ForgotPasswordController extends ChangeNotifier {
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;

  ForgotPasswordController({
    required this.sendPasswordResetUseCase,
    required this.verifyOtpUseCase,
    required this.resetPasswordUseCase,
  });

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterUsername;
  bool _isLoading = false;
  String? _errorMessage;
  String _username = '';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  ForgotPasswordStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get username => _username;
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }

  Future<void> sendResetRequest(String username) async {
    if (username.isEmpty) {
      _errorMessage = 'Please enter your username';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _username = username;
    notifyListeners();

    final result = await sendPasswordResetUseCase.call(username);
    
    result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        _currentStep = ForgotPasswordStep.verifyOtp;
        notifyListeners();
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (otp.length != 6) {
      _errorMessage = 'Please enter a valid 6-digit code';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await verifyOtpUseCase.call(_username, otp);

    result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (isValid) {
        _isLoading = false;
        if (isValid) {
          _currentStep = ForgotPasswordStep.setNewPassword;
        } else {
          _errorMessage = 'Invalid code. Please try again.';
        }
        notifyListeners();
      },
    );
  }

  Future<void> resetPassword(String password, String confirmPassword) async {
    // Validate password fields
    if (password.isEmpty || confirmPassword.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return;
    }

    if (password.length < 8) {
      _errorMessage = 'Password must be at least 8 characters';
      notifyListeners();
      return;
    }

    if (password != confirmPassword) {
      _errorMessage = 'Passwords do not match';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await resetPasswordUseCase.call(_username, password);

    result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        _currentStep = ForgotPasswordStep.success;
        notifyListeners();
      },
    );
  }

  void resendOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await sendPasswordResetUseCase.call(_username);

    result.fold(
      (failure) {
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void reset() {
    _currentStep = ForgotPasswordStep.enterUsername;
    _username = '';
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}