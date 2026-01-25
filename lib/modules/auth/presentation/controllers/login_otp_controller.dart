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

    final result = await sendEmailOtpUseCase.call(email);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> sendPhoneOtp(String phoneNumber) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await sendPhoneOtpUseCase.call(phoneNumber);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
      },
      (_) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<bool> verifyEmailOtp(String email, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await verifyEmailOtpUseCase.call(email, otp);
    
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (isVerified) {
        _isEmailVerified = isVerified;
        _isLoading = false;
        notifyListeners();
        return isVerified;
      },
    );
  }

  Future<bool> verifyPhoneOtp(String phoneNumber, String otp) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await verifyPhoneOtpUseCase.call(phoneNumber, otp);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
      (isVerified) {
        _isPhoneVerified = isVerified;
        _isLoading = false;
        notifyListeners();
        return isVerified;
      },
    );
  }

  void reset() {
    _isEmailVerified = false;
    _isPhoneVerified = false;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}