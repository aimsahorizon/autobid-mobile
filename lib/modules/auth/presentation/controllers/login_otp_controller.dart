import 'package:flutter/material.dart';
import '../../domain/usecases/send_email_otp_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/verify_email_otp_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';

class LoginOtpController extends ChangeNotifier {
  final SendEmailOtpUseCase sendEmailOtpUseCase;
  final SendPhoneOtpUseCase sendPhoneOtpUseCase;
  final VerifyEmailOtpUseCase verifyEmailOtpUseCase;
  final VerifyPhoneOtpUseCase verifyPhoneOtpUseCase;

  LoginOtpController({
    required this.sendEmailOtpUseCase,
    required this.sendPhoneOtpUseCase,
    required this.verifyEmailOtpUseCase,
    required this.verifyPhoneOtpUseCase,
  });

  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isEmailVerified => _isEmailVerified;
  bool get isPhoneVerified => _isPhoneVerified;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isBothVerified => _isEmailVerified && _isPhoneVerified;

  Future<void> sendEmailOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await sendEmailOtpUseCase.call(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send email OTP: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await sendPhoneOtpUseCase.call(phoneNumber);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to send phone OTP: $e';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> verifyEmailOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isVerified = await verifyEmailOtpUseCase.call(email, otp);
      _isEmailVerified = isVerified;
      _isLoading = false;
      notifyListeners();
      return isVerified;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Email verification failed: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final isVerified = await verifyPhoneOtpUseCase.call(phoneNumber, otp);
      _isPhoneVerified = isVerified;
      _isLoading = false;
      notifyListeners();
      return isVerified;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Phone verification failed: $e';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _isEmailVerified = false;
    _isPhoneVerified = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
