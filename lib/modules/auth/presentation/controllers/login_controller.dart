import 'package:flutter/material.dart';
import '../../../profile/data/datasources/profile_supabase_datasource.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';

enum LoginStep { credentials, otpVerification, completed }

class LoginController extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final ProfileSupabaseDataSource profileDataSource;

  LoginController({
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
    required this.profileDataSource,
  });

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  LoginStep _currentStep = LoginStep.credentials;

  String? _userEmail;
  String? _userPhoneNumber;

  bool get isLoading => _isLoading;
  bool get obscurePassword => _obscurePassword;
  String? get errorMessage => _errorMessage;
  LoginStep get currentStep => _currentStep;
  String? get userEmail => _userEmail;
  String? get userPhoneNumber => _userPhoneNumber;

  void togglePasswordVisibility() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Sign in returns user with email, username, and phone number from users table
      final user = await signInUseCase.call(username, password);

      // Store user data for email OTP verification
      _userEmail = user.email;
      _userPhoneNumber = user.phoneNumber;

      // Move to email OTP verification step (phone OTP skipped)
      _currentStep = LoginStep.otpVerification;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final user = await signInWithGoogleUseCase.call();

      // Check if email exists in user_profiles
      final emailExists = await profileDataSource.checkEmailExists(user.email);

      if (!emailExists) {
        _isLoading = false;
        _errorMessage = 'Account not registered. Please sign up first.';
        notifyListeners();
        return false;
      }

      // Fetch user profile to get phone number for OTP
      final profile = await profileDataSource.getUserProfileByEmail(user.email);

      if (profile == null) {
        _isLoading = false;
        _errorMessage = 'User profile not found. Please register.';
        notifyListeners();
        return false;
      }

      // Store user data for email OTP verification
      _userEmail = profile.email;
      _userPhoneNumber = profile.contactNumber;

      // Move to email OTP verification step (phone OTP skipped)
      _currentStep = LoginStep.otpVerification;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Google sign in failed: $e';
      notifyListeners();
      return false;
    }
  }

  void completeLogin() {
    _currentStep = LoginStep.completed;
    notifyListeners();
  }

  void reset() {
    _currentStep = LoginStep.credentials;
    _userEmail = null;
    _userPhoneNumber = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
