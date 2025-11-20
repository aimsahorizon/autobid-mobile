import 'package:flutter/material.dart';
import '../../domain/usecases/send_password_reset_usecase.dart';
import '../../domain/usecases/verify_otp_usecase.dart';

enum ForgotPasswordStep { enterUsername, verifyOtp, success }

class ForgotPasswordController extends ChangeNotifier {
  final SendPasswordResetUseCase sendPasswordResetUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;

  ForgotPasswordController({
    required this.sendPasswordResetUseCase,
    required this.verifyOtpUseCase,
  });

  ForgotPasswordStep _currentStep = ForgotPasswordStep.enterUsername;
  bool _isLoading = false;
  String? _errorMessage;
  String _username = '';

  ForgotPasswordStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get username => _username;

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

    try {
      await sendPasswordResetUseCase.call(username);
      _isLoading = false;
      _currentStep = ForgotPasswordStep.verifyOtp;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send reset code. Please try again.';
      notifyListeners();
    }
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

    try {
      final isValid = await verifyOtpUseCase.call(_username, otp);
      _isLoading = false;

      if (isValid) {
        _currentStep = ForgotPasswordStep.success;
      } else {
        _errorMessage = 'Invalid code. Please try again.';
      }
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Verification failed. Please try again.';
      notifyListeners();
    }
  }

  void resendOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await sendPasswordResetUseCase.call(_username);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to resend code. Please try again.';
      notifyListeners();
    }
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
