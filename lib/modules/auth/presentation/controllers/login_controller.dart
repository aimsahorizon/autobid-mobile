import 'package:flutter/material.dart';
import '../../../profile/domain/usecases/check_email_exists_usecase.dart';
import '../../../profile/domain/usecases/get_user_profile_by_email_usecase.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import 'package:autobid_mobile/core/error/failures.dart';

enum LoginStep { credentials, otpVerification, completed }

class LoginController extends ChangeNotifier {
  final SignInUseCase signInUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final CheckEmailExistsUseCase checkEmailExistsUseCase;
  final GetUserProfileByEmailUseCase getUserProfileByEmailUseCase;

  LoginController({
    required this.signInUseCase,
    required this.signInWithGoogleUseCase,
    required this.checkEmailExistsUseCase,
    required this.getUserProfileByEmailUseCase,
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

  void _setError(Failure failure) {
    _errorMessage = failure.message;
    _isLoading = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _errorMessage = null;
    notifyListeners();
  }

  Future<bool> signIn(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _errorMessage = 'Please fill in all fields';
      notifyListeners();
      return false;
    }

    _setLoading(true);

    final result = await signInUseCase.call(username, password);

    return result.fold(
      (failure) {
        _setError(failure);
        return false;
      },
      (user) {
        _userEmail = user.email;
        _userPhoneNumber = user.phoneNumber;
        _currentStep = LoginStep.otpVerification;
        _isLoading = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);

    // 1. Sign In
    final userResult = await signInWithGoogleUseCase.call();

    return await userResult.fold(
      (failure) async {
        _setError(failure);
        return false;
      },
      (user) async {
        // 2. Check Email Exists
        final emailCheckResult = await checkEmailExistsUseCase.call(user.email);
        
        return await emailCheckResult.fold(
          (failure) async {
            _setError(failure);
            return false;
          },
          (exists) async {
            if (!exists) {
              _errorMessage = 'Account not registered. Please sign up first.';
              _isLoading = false;
              notifyListeners();
              return false;
            }

            // 3. Get Profile
            final profileResult = await getUserProfileByEmailUseCase.call(user.email);
            
            return profileResult.fold(
              (failure) {
                _setError(failure);
                return false;
              },
              (profile) {
                if (profile == null) {
                   _errorMessage = 'User profile not found. Please register.';
                   _isLoading = false;
                   notifyListeners();
                   return false;
                }
                
                _userEmail = profile.email;
                _userPhoneNumber = profile.contactNumber;
                _currentStep = LoginStep.otpVerification;
                _isLoading = false;
                notifyListeners();
                return true;
              },
            );
          },
        );
      },
    );
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