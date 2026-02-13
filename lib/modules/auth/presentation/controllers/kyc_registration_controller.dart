import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/usecases/send_email_otp_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/verify_email_otp_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import '../../domain/usecases/check_national_id_exists_usecase.dart';
import '../../domain/usecases/check_secondary_id_exists_usecase.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/models/kyc_registration_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/services/ai_id_extraction_service.dart';
import 'package:autobid_mobile/core/services/file_encryption_service.dart';
import 'package:autobid_mobile/core/utils/philippine_id_validators.dart';
import '../../data/datasources/demo_data_generator.dart';

enum KYCStep {
  accountInfo, // Step 1: Username, email, phone, password, T&C
  otpVerification, // Step 2: Verify email and phone
  nationalId, // Step 3: Upload National ID for AI extraction
  selfieWithId, // Step 4: Selfie verification
  secondaryId, // Step 5: Secondary ID - triggers AI autofill
  personalInfo, // Step 6: Personal details (auto-filled from AI)
  address, // Step 7: Address details (auto-filled from AI)
  proofOfAddress, // Step 8: Proof of address document
  review, // Step 9: Final review before submission
}

class KYCRegistrationController extends ChangeNotifier {
  final AuthRemoteDataSource? _authDataSource;
  final SendEmailOtpUseCase? _sendEmailOtpUseCase;
  final VerifyEmailOtpUseCase? _verifyEmailOtpUseCase;
  final CheckNationalIdExistsUseCase? _checkNationalIdExistsUseCase;
  final CheckSecondaryIdExistsUseCase? _checkSecondaryIdExistsUseCase;
  final IAiIdExtractionService _aiService;
  final FileEncryptionService? _fileEncryptionService;
  final SharedPreferences? _sharedPreferences;

  Timer? _saveDraftTimer;

  /// Constructor with optional dependencies for Supabase integration
  /// If not provided, registration will use mock implementation
  KYCRegistrationController({
    AuthRemoteDataSource? authDataSource,
    SendEmailOtpUseCase? sendEmailOtpUseCase,
    SendPhoneOtpUseCase? sendPhoneOtpUseCase,
    VerifyEmailOtpUseCase? verifyEmailOtpUseCase,
    VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase,
    CheckNationalIdExistsUseCase? checkNationalIdExistsUseCase,
    CheckSecondaryIdExistsUseCase? checkSecondaryIdExistsUseCase,
    IAiIdExtractionService? aiService,
    FileEncryptionService? fileEncryptionService,
    SharedPreferences? sharedPreferences,
  }) : _authDataSource = authDataSource,
       _sendEmailOtpUseCase = sendEmailOtpUseCase,
       _verifyEmailOtpUseCase = verifyEmailOtpUseCase,
       _checkNationalIdExistsUseCase = checkNationalIdExistsUseCase,
       _checkSecondaryIdExistsUseCase = checkSecondaryIdExistsUseCase,
       _aiService = aiService ?? ProductionAiIdExtractionService(),
       _fileEncryptionService = fileEncryptionService,
       _sharedPreferences = sharedPreferences;

  KYCStep _currentStep = KYCStep.accountInfo;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: National ID
  String? _nationalIdNumber;
  File? _nationalIdFront;
  File? _nationalIdBack;

  // Step 2: Selfie
  File? _selfieWithId;
  bool _aiAutoFillAccepted = false;

  // Step 3: Secondary ID
  String? _secondaryIdType;
  String? _secondaryIdNumber;
  File? _secondaryIdFront;
  File? _secondaryIdBack;

  // Step 4: Personal Info
  String? _firstName;
  String? _middleName;
  String? _lastName;
  DateTime? _dateOfBirth;
  String? _sex;

  // Step 5: Account Info
  String? _username;
  String? _email;
  String? _password;
  String? _confirmPassword;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool? _isUsernameAvailable;
  bool? _isEmailAvailable;

  // Step 6: OTP
  bool _phoneOtpVerified = false;
  bool _emailOtpVerified = false;

  // Step 7: Address
  String? _region;
  String? _province;
  String? _city;
  String? _barangay;
  String? _street;
  String? _zipCode;

  // Step 8: Proof of Address
  File? _proofOfAddress;

  // Getters
  KYCStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentStepIndex => _currentStep.index;
  int get totalSteps => KYCStep.values.length;

  // Step 1 getters
  String? get nationalIdNumber => _nationalIdNumber;
  File? get nationalIdFront => _nationalIdFront;
  File? get nationalIdBack => _nationalIdBack;

  // Step 2 getters
  File? get selfieWithId => _selfieWithId;
  bool get aiAutoFillAccepted => _aiAutoFillAccepted;

  // Step 3 getters
  String? get secondaryIdType => _secondaryIdType;
  String? get secondaryIdNumber => _secondaryIdNumber;
  File? get secondaryIdFront => _secondaryIdFront;
  File? get secondaryIdBack => _secondaryIdBack;

  // Step 4 getters
  String? get firstName => _firstName;
  String? get middleName => _middleName;
  String? get lastName => _lastName;
  DateTime? get dateOfBirth => _dateOfBirth;
  String? get sex => _sex;

  // Step 5 getters
  String? get username => _username;
  String? get email => _email;
  String? get password => _password;
  String? get confirmPassword => _confirmPassword;
  bool get termsAccepted => _termsAccepted;
  bool get privacyAccepted => _privacyAccepted;
  bool? get isUsernameAvailable => _isUsernameAvailable;
  bool? get isEmailAvailable => _isEmailAvailable;

  // Step 6 getters
  bool get phoneOtpVerified => _phoneOtpVerified;
  bool get emailOtpVerified => _emailOtpVerified;

  // Step 7 getters
  String? get region => _region;
  String? get province => _province;
  String? get city => _city;
  String? get barangay => _barangay;
  String? get street => _street;
  String? get zipCode => _zipCode;

  // Step 8 getters
  File? get proofOfAddress => _proofOfAddress;

  void _scheduleSaveDraft() {
    _saveDraftTimer?.cancel();
    _saveDraftTimer = Timer(const Duration(seconds: 1), saveDraft);
  }

  /// Check if any registration data has been entered
  bool hasAnyDataEntered() {
    return (_nationalIdNumber?.isNotEmpty ?? false) ||
        _nationalIdFront != null ||
        _nationalIdBack != null ||
        _selfieWithId != null ||
        (_secondaryIdType?.isNotEmpty ?? false) ||
        (_secondaryIdNumber?.isNotEmpty ?? false) ||
        _secondaryIdFront != null ||
        _secondaryIdBack != null ||
        (_firstName?.isNotEmpty ?? false) ||
        (_middleName?.isNotEmpty ?? false) ||
        (_lastName?.isNotEmpty ?? false) ||
        _dateOfBirth != null ||
        (_sex?.isNotEmpty ?? false) ||
        (_username?.isNotEmpty ?? false) ||
        (_email?.isNotEmpty ?? false) ||
        (_password?.isNotEmpty ?? false) ||
        (_region?.isNotEmpty ?? false) ||
        (_province?.isNotEmpty ?? false) ||
        (_city?.isNotEmpty ?? false) ||
        (_barangay?.isNotEmpty ?? false) ||
        (_street?.isNotEmpty ?? false) ||
        (_zipCode?.isNotEmpty ?? false) ||
        _proofOfAddress != null ||
        _termsAccepted ||
        _privacyAccepted;
  }

  // Step 1 setters
  void setNationalIdNumber(String value) {
    _nationalIdNumber = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setNationalIdFront(File? file) {
    _nationalIdFront = file;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setNationalIdBack(File? file) {
    _nationalIdBack = file;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Step 2 setters
  void setSelfieWithId(File? file) {
    _selfieWithId = file;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setAiAutoFillAccepted(bool value) {
    _aiAutoFillAccepted = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Step 3 setters
  void setSecondaryIdType(String? value) {
    _secondaryIdType = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setSecondaryIdNumber(String value) {
    _secondaryIdNumber = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setSecondaryIdFront(File? file) {
    _secondaryIdFront = file;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setSecondaryIdBack(File? file) {
    _secondaryIdBack = file;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Step 4 setters
  void setFirstName(String value) {
    _firstName = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setMiddleName(String value) {
    _middleName = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setSex(String value) {
    _sex = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Password validation flags
  bool get hasMinLength => _password != null && _password!.length >= 8;
  bool get hasUppercase =>
      _password != null && _password!.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase =>
      _password != null && _password!.contains(RegExp(r'[a-z]'));
  bool get hasDigits =>
      _password != null && _password!.contains(RegExp(r'[0-9]'));
  bool get hasSpecialCharacters =>
      _password != null &&
      _password!.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  double get passwordStrength {
    if (_password == null || _password!.isEmpty) return 0.0;
    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase) score++;
    if (hasLowercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;
    return score / 5.0;
  }

  String get passwordStrengthText {
    final strength = passwordStrength;
    if (strength == 0) return '';
    if (strength <= 0.2) return 'Very Weak';
    if (strength <= 0.4) return 'Weak';
    if (strength <= 0.6) return 'Fair';
    if (strength <= 0.8) return 'Good';
    return 'Strong';
  }

  Color get passwordStrengthColor {
    final strength = passwordStrength;
    if (strength <= 0.2) return Colors.red;
    if (strength <= 0.4) return Colors.orange;
    if (strength <= 0.6) return Colors.yellow;
    if (strength <= 0.8) return Colors.blue;
    return Colors.green;
  }

  // Step 5 setters
  void setUsername(String value) {
    _username = value;
    _isUsernameAvailable = null;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setEmail(String value) {
    // Reset email OTP verification if email changed
    if (_email != null && _email != value) {
      _emailOtpVerified = false;
      _isEmailAvailable = null;
    }
    _email = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    _confirmPassword = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    _termsAccepted = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setPrivacyAccepted(bool value) {
    _privacyAccepted = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Step 6 setters
  void setPhoneOtpVerified(bool value) {
    _phoneOtpVerified = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setEmailOtpVerified(bool value) {
    _emailOtpVerified = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  Future<void> sendEmailOtp() async {
    if (_email == null || _sendEmailOtpUseCase == null) {
      throw 'Email not set or use case not available';
    }

    try {
      final result = await _sendEmailOtpUseCase.call(_email!);
      result.fold(
        (l) => throw l.message, // Throw the failure message directly
        (r) => null,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> verifyEmailOtp(String otp) async {
    if (_email == null || _verifyEmailOtpUseCase == null) {
      return false;
    }

    try {
      final result = await _verifyEmailOtpUseCase.call(_email!, otp);
      return result.fold(
        (l) => throw l.message, // Throw the failure message directly
        (isVerified) {
          if (isVerified) {
            setEmailOtpVerified(true);
          }
          return isVerified;
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // Step 7 setters
  void setRegion(String? value) {
    _region = value;
    _province = null;
    _city = null;
    _barangay = null;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setProvince(String? value) {
    _province = value;
    _city = null;
    _barangay = null;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setCity(String? value) {
    _city = value;
    _barangay = null;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setBarangay(String? value) {
    _barangay = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setStreet(String value) {
    _street = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  void setZipCode(String value) {
    _zipCode = value;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Step 8 setters
  void setProofOfAddress(File? file) {
    _proofOfAddress = file;
    _scheduleSaveDraft();
    notifyListeners();
  }

  // Navigation
  Future<void> nextStep() async {
    // Perform async checks before proceeding
    if (_currentStep == KYCStep.nationalId) {
       if (_nationalIdNumber != null && _checkNationalIdExistsUseCase != null) {
          _isLoading = true;
          notifyListeners();
          
          try {
            final result = await _checkNationalIdExistsUseCase!.call(_nationalIdNumber!);
            final exists = result.fold((l) => false, (r) => r);
            
            if (exists) {
              setError('National ID Number is already registered.');
              _isLoading = false;
              notifyListeners();
              return;
            }
          } catch (e) {
             // Handle error or proceed? Better to fail safe.
             // But if network fails, user can't register?
             // For now, log and maybe warn or proceed if critical.
          } finally {
            _isLoading = false;
            notifyListeners();
          }
       }
    }
    
    if (_currentStep == KYCStep.secondaryId) {
       if (_secondaryIdNumber != null && _secondaryIdType != null && _checkSecondaryIdExistsUseCase != null) {
          _isLoading = true;
          notifyListeners();
          
          try {
            final result = await _checkSecondaryIdExistsUseCase!.call(_secondaryIdNumber!, _secondaryIdType!);
            final exists = result.fold((l) => false, (r) => r);
            
            if (exists) {
              setError('Secondary ID Number is already registered.');
              _isLoading = false;
              notifyListeners();
              return;
            }
          } catch (e) {
             // Handle error
          } finally {
             _isLoading = false;
             notifyListeners();
          }
       }
    }

    if (_currentStep.index < KYCStep.values.length - 1) {
      _currentStep = KYCStep.values[_currentStep.index + 1];
      _errorMessage = null;
      notifyListeners();
    }
  }

  void previousStep() {
    if (_currentStep.index > 0) {
      _currentStep = KYCStep.values[_currentStep.index - 1];
      _errorMessage = null;
      notifyListeners();
    }
  }

  void goToStep(KYCStep step) {
    _currentStep = step;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Trigger AI extraction from secondary ID and autofill data
  /// This is called after secondary ID upload
  Future<ExtractedIdData> extractDataFromIds() async {
    if (_secondaryIdFront == null || _nationalIdFront == null) {
      throw Exception(
        'Both secondary and national ID are required for extraction',
      );
    }

    _isLoading = true;
    notifyListeners();

    try {
      final extractedData = await _aiService.extractFromSecondaryId(
        secondaryIdFront: _secondaryIdFront!,
        secondaryIdBack: _secondaryIdBack,
        nationalIdFront: _nationalIdFront!,
        nationalIdBack: _nationalIdBack,
      );

      // Autofill the extracted data
      if (extractedData.firstName != null) _firstName = extractedData.firstName;
      if (extractedData.middleName != null) {
        _middleName = extractedData.middleName;
      }
      if (extractedData.lastName != null) _lastName = extractedData.lastName;
      if (extractedData.dateOfBirth != null) {
        _dateOfBirth = extractedData.dateOfBirth;
      }
      if (extractedData.sex != null) _sex = extractedData.sex;
      if (extractedData.province != null) _province = extractedData.province;
      if (extractedData.city != null) _city = extractedData.city;
      if (extractedData.barangay != null) _barangay = extractedData.barangay;
      if (extractedData.zipCode != null) _zipCode = extractedData.zipCode;
      if (extractedData.address != null) _street = extractedData.address;

      return extractedData;
    } catch (e) {
      _errorMessage = 'Failed to extract ID data: ${e.toString()}';
      // Return empty data on failure so flow can continue manually
      return const ExtractedIdData(); 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Validation methods
  bool validateNationalIdStep({bool reportError = true}) {
    if (_nationalIdNumber == null || _nationalIdNumber!.isEmpty) {
      if (reportError) setError('Please enter your National ID number');
      return false;
    }
    
    // Strict Format Check
    if (!PhilippineIdValidator.validateNationalId(_nationalIdNumber!)) {
      if (reportError) setError('Invalid National ID format. Must be 12 digits.');
      return false;
    }

    if (_nationalIdFront == null) {
      if (reportError) setError('Please upload the front of your National ID');
      return false;
    }
    if (_nationalIdBack == null) {
      if (reportError) setError('Please upload the back of your National ID');
      return false;
    }
    return true;
  }

  bool validateSelfieStep({bool reportError = true}) {
    if (_selfieWithId == null) {
      if (reportError) setError('Please take a selfie with your ID');
      return false;
    }
    return true;
  }

  bool validateSecondaryIdStep({bool reportError = true}) {
    if (_secondaryIdType == null || _secondaryIdType!.isEmpty) {
      if (reportError) setError('Please select a secondary ID type');
      return false;
    }
    if (_secondaryIdNumber == null || _secondaryIdNumber!.isEmpty) {
      if (reportError) setError('Please enter your secondary ID number');
      return false;
    }

    // Strict Format Check based on Type
    if (!PhilippineIdValidator.validateSecondaryId(_secondaryIdNumber!, _secondaryIdType!)) {
      if (reportError) setError('Invalid format for $_secondaryIdType number');
      return false;
    }

    if (_secondaryIdFront == null) {
      if (reportError) setError('Please upload the front of your secondary ID');
      return false;
    }
    if (_secondaryIdBack == null) {
      if (reportError) setError('Please upload the back of your secondary ID');
      return false;
    }
    return true;
  }

  bool validatePersonalInfoStep({bool reportError = true}) {
    if (_firstName == null || _firstName!.isEmpty) {
      if (reportError) setError('Please enter your first name');
      return false;
    }
    if (_lastName == null || _lastName!.isEmpty) {
      if (reportError) setError('Please enter your last name');
      return false;
    }
    if (_dateOfBirth == null) {
      if (reportError) setError('Please select your date of birth');
      return false;
    }
    if (_sex == null || _sex!.isEmpty) {
      if (reportError) setError('Please select your sex');
      return false;
    }
    return true;
  }

  Future<void> checkUsernameAvailability(String username) async {
    if (_authDataSource == null) return;

    // Check for reserved keywords first
    final lower = username.toLowerCase();
    if (lower.contains('admin') || lower.contains('test')) {
      _isUsernameAvailable = false;
      notifyListeners();
      return;
    }

    try {
      _isUsernameAvailable = await _authDataSource.checkUsernameAvailable(
        username,
      );
    } catch (e) {
      // On error (e.g. network), assume unavailable or keep null?
      // Better to keep null so validation fails/shows error
      _isUsernameAvailable = null;
    }
    notifyListeners();
  }

  Future<void> checkEmailAvailability(String email) async {
    if (_authDataSource == null) return;
    try {
      _isEmailAvailable = await _authDataSource.checkEmailAvailable(email);
    } catch (e) {
      _isEmailAvailable = null;
    }
    notifyListeners();
  }

  bool validateAccountInfoStep({bool reportError = true}) {
    if (_username == null || _username!.isEmpty) {
      if (reportError) setError('Please enter a username');
      return false;
    }
    if (_username!.length < 3) {
      if (reportError) setError('Username must be at least 3 characters');
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(_username!)) {
      if (reportError) {
        setError('Username can only contain letters, numbers, and underscores');
      }
      return false;
    }

    final lowerUsername = _username!.toLowerCase();
    if (lowerUsername.contains('admin') || lowerUsername.contains('test')) {
      if (reportError) setError('Username contains reserved words');
      return false;
    }

    if (_isUsernameAvailable == false) {
      if (reportError) setError('Username is already taken');
      return false;
    }

    // If username availability is unchecked (null), we block progress.
    // However, for silent check (button state), we just return false without error
    if (_isUsernameAvailable == null && _authDataSource != null) {
      // Only block if we are actually validating for progression
      // But silent check should return false so button is disabled
      return false;
    }

    if (_email == null || _email!.isEmpty) {
      if (reportError) setError('Please enter your email');
      return false;
    }

    // Valid Email Check
    final emailRegex = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
    if (!emailRegex.hasMatch(_email!)) {
      if (reportError) setError('Please enter a valid email address');
      return false;
    }

    if (_isEmailAvailable == false) {
      if (reportError) setError('Email is already registered');
      return false;
    }

    if (_isEmailAvailable == null && _authDataSource != null) {
      return false;
    }

    if (_password == null || _password!.isEmpty) {
      if (reportError) setError('Please enter a password');
      return false;
    }

    // Password Complexity Check
    final hasMinLength = _password!.length >= 8;
    final hasUppercase = _password!.contains(RegExp(r'[A-Z]'));
    final hasLowercase = _password!.contains(RegExp(r'[a-z]'));
    final hasDigits = _password!.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = _password!.contains(
      RegExp(r'[!@#$%^&*(),.?":{}|<>]'),
    );

    if (!hasMinLength ||
        !hasUppercase ||
        !hasLowercase ||
        !hasDigits ||
        !hasSpecialCharacters) {
      if (reportError) setError('Password must meet all requirements');
      return false;
    }

    if (_confirmPassword == null || _confirmPassword!.isEmpty) {
      if (reportError) setError('Please confirm your password');
      return false;
    }

    if (_password != _confirmPassword) {
      if (reportError) setError('Passwords do not match');
      return false;
    }

    if (!_termsAccepted) {
      if (reportError) setError('Please accept the Terms & Conditions');
      return false;
    }
    if (!_privacyAccepted) {
      if (reportError) setError('Please accept the Privacy Policy');
      return false;
    }
    return true;
  }

  bool validateOtpStep({bool reportError = true}) {
    // Phone verification removed as per requirement
    if (!_emailOtpVerified) {
      if (reportError) setError('Please verify your email');
      return false;
    }
    return true;
  }

  bool validateAddressStep({bool reportError = true}) {
    if (_region == null || _region!.isEmpty) {
      if (reportError) setError('Please select your region');
      return false;
    }
    if (_province == null || _province!.isEmpty) {
      if (reportError) setError('Please select your province');
      return false;
    }
    if (_city == null || _city!.isEmpty) {
      if (reportError) setError('Please select your city');
      return false;
    }
    if (_barangay == null || _barangay!.isEmpty) {
      if (reportError) setError('Please select your barangay');
      return false;
    }
    if (_street == null || _street!.isEmpty) {
      if (reportError) setError('Please enter your street address');
      return false;
    }
    if (_zipCode == null || _zipCode!.isEmpty) {
      if (reportError) setError('Please enter your ZIP code');
      return false;
    }
    return true;
  }

  bool validateProofOfAddressStep({bool reportError = true}) {
    if (_proofOfAddress == null) {
      if (reportError) setError('Please upload proof of address');
      return false;
    }
    return true;
  }

  bool get isCurrentStepValid {
    switch (_currentStep) {
      case KYCStep.accountInfo:
        return validateAccountInfoStep(reportError: false);
      case KYCStep.otpVerification:
        return validateOtpStep(reportError: false);
      case KYCStep.nationalId:
        return validateNationalIdStep(reportError: false);
      case KYCStep.selfieWithId:
        return validateSelfieStep(reportError: false);
      case KYCStep.secondaryId:
        return validateSecondaryIdStep(reportError: false);
      case KYCStep.personalInfo:
        return validatePersonalInfoStep(reportError: false);
      case KYCStep.address:
        return validateAddressStep(reportError: false);
      case KYCStep.proofOfAddress:
        return validateProofOfAddressStep(reportError: false);
      case KYCStep.review:
        return true; // Review step assumes previous steps are valid
    }
  }

  // AI Auto-fill functionality with randomized demo data
  Future<void> performAIAutoFill() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // Generate randomized demo data
    final demoData = DemoDataGenerator.generateCompleteData();

    _firstName = demoData['firstName'];
    _middleName = demoData['middleName'];
    _lastName = demoData['lastName'];
    _dateOfBirth = demoData['dateOfBirth'];
    _sex = demoData['sex'];
    _nationalIdNumber = demoData['nationalIdNumber'];
    _region = demoData['region'];
    _province = demoData['province'];
    _city = demoData['city'];
    _barangay = demoData['barangay'];
    _street = demoData['street'];
    _zipCode = demoData['zipCode'];

    _isLoading = false;
    notifyListeners();
  }

  /// Save current registration progress as draft to shared preferences
  Future<void> saveDraft() async {
    if (_sharedPreferences == null) {
      debugPrint(
        '[KYCRegistrationController] Cannot save draft: SharedPreferences is null',
      );
      return;
    }

    try {
      final data = {
        'currentStep': _currentStep.index,
        'nationalIdNumber': _nationalIdNumber,
        'secondaryIdType': _secondaryIdType,
        'secondaryIdNumber': _secondaryIdNumber,
        'firstName': _firstName,
        'middleName': _middleName,
        'lastName': _lastName,
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'sex': _sex,
        'username': _username,
        'email': _email,
        'password': _password,
        'confirmPassword': _confirmPassword,
        'region': _region,
        'province': _province,
        'city': _city,
        'barangay': _barangay,
        'street': _street,
        'zipCode': _zipCode,
        'termsAccepted': _termsAccepted,
        'privacyAccepted': _privacyAccepted,
        'emailOtpVerified': _emailOtpVerified,
        'phoneOtpVerified': _phoneOtpVerified,
        'aiAutoFillAccepted': _aiAutoFillAccepted,
        'isUsernameAvailable': _isUsernameAvailable,
        'isEmailAvailable': _isEmailAvailable,
        // Save file paths - checking existence on load
        'nationalIdFrontPath': _nationalIdFront?.path,
        'nationalIdBackPath': _nationalIdBack?.path,
        'selfieWithIdPath': _selfieWithId?.path,
        'secondaryIdFrontPath': _secondaryIdFront?.path,
        'secondaryIdBackPath': _secondaryIdBack?.path,
        'proofOfAddressPath': _proofOfAddress?.path,
      };

      final jsonString = jsonEncode(data);
      final success = await _sharedPreferences.setString(
        'kyc_registration_draft',
        jsonString,
      );

      if (success) {
        debugPrint('[KYCRegistrationController] Draft saved successfully');
      } else {
        debugPrint(
          '[KYCRegistrationController] Failed to save draft to SharedPreferences',
        );
      }
    } catch (e) {
      debugPrint(
        '[KYCRegistrationController] Error encoding or saving draft: $e',
      );
    }
  }

  /// Load saved draft from storage
  Future<bool> hasSavedDraft() async {
    if (_sharedPreferences == null) return false;
    return _sharedPreferences.containsKey('kyc_registration_draft');
  }

  Future<void> loadDraft([String? email]) async {
    if (_sharedPreferences == null) return;

    final draft = _sharedPreferences.getString('kyc_registration_draft');
    if (draft == null) return;

    try {
      final data = jsonDecode(draft) as Map<String, dynamic>;

      _currentStep = KYCStep.values[data['currentStep'] ?? 0];
      _nationalIdNumber = data['nationalIdNumber'];
      _secondaryIdType = data['secondaryIdType'];
      _secondaryIdNumber = data['secondaryIdNumber'];
      _firstName = data['firstName'];
      _middleName = data['middleName'];
      _lastName = data['lastName'];
      if (data['dateOfBirth'] != null) {
        _dateOfBirth = DateTime.tryParse(data['dateOfBirth']);
      }
      _sex = data['sex'];
      _username = data['username'];
      _email = data['email'];
      _password = data['password'];
      _confirmPassword = data['confirmPassword'];
      _region = data['region'];
      _province = data['province'];
      _city = data['city'];
      _barangay = data['barangay'];
      _street = data['street'];
      _zipCode = data['zipCode'];
      _termsAccepted = data['termsAccepted'] ?? false;
      _privacyAccepted = data['privacyAccepted'] ?? false;
      _emailOtpVerified = data['emailOtpVerified'] ?? false;
      _phoneOtpVerified = data['phoneOtpVerified'] ?? false;
      _aiAutoFillAccepted = data['aiAutoFillAccepted'] ?? false;
      _isUsernameAvailable = data['isUsernameAvailable'];
      _isEmailAvailable = data['isEmailAvailable'];

      // Helper to load file if exists
      File? loadFile(String? path) {
        if (path == null) return null;
        final file = File(path);
        return file.existsSync() ? file : null;
      }

      _nationalIdFront = loadFile(data['nationalIdFrontPath']);
      _nationalIdBack = loadFile(data['nationalIdBackPath']);
      _selfieWithId = loadFile(data['selfieWithIdPath']);
      _secondaryIdFront = loadFile(data['secondaryIdFrontPath']);
      _secondaryIdBack = loadFile(data['secondaryIdBackPath']);
      _proofOfAddress = loadFile(data['proofOfAddressPath']);

      notifyListeners();
      debugPrint('[KYCRegistrationController] Draft loaded successfully');
    } catch (e) {
      debugPrint('[KYCRegistrationController] Error loading draft: $e');
    }
  }

  /// Clear all registration data
  void clearAllData() {
    if (_sharedPreferences != null) {
      _sharedPreferences.remove('kyc_registration_draft');
    }

    // Reset all fields to null/default
    _nationalIdNumber = null;
    _nationalIdFront = null;
    _nationalIdBack = null;
    _selfieWithId = null;
    _aiAutoFillAccepted = false;
    _secondaryIdType = null;
    _secondaryIdNumber = null;
    _secondaryIdFront = null;
    _secondaryIdBack = null;
    _firstName = null;
    _middleName = null;
    _lastName = null;
    _dateOfBirth = null;
    _sex = null;
    _username = null;
    _email = null;
    _password = null;
    _confirmPassword = null;
    _termsAccepted = false;
    _privacyAccepted = false;
    _isUsernameAvailable = null;
    _isEmailAvailable = null;
    _phoneOtpVerified = false;
    _emailOtpVerified = false;
    _region = null;
    _province = null;
    _city = null;
    _barangay = null;
    _street = null;
    _zipCode = null;
    _proofOfAddress = null;
    _currentStep = KYCStep.accountInfo;
    notifyListeners();
  }

  // Submit registration
  Future<void> submitRegistration() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if dependencies are injected (real Supabase implementation)
      if (_authDataSource != null) {
        // Get current authenticated user (must exist after OTP verification)
        final user = Supabase.instance.client.auth.currentUser;
        if (user == null) {
          throw Exception('User not authenticated. Please verify OTP first.');
        }

        final userId = user.id;

        // Step 0: Set password for the OTP-authenticated user
        // This enables password-based login after registration
        if (_password != null && _password!.isNotEmpty) {
          await _authDataSource.setPasswordForOtpUser(_password!);
        }

        // Step 1: Upload all KYC documents to kyc-documents bucket
        final timestamp = DateTime.now().millisecondsSinceEpoch;

        // Helper function for uploading
        Future<String> uploadFile(File file, String path) async {
          if (_fileEncryptionService != null) {
            final bytes = await file.readAsBytes();
            return _fileEncryptionService.uploadEncryptedFile(
              fileBytes: bytes,
              userId: userId,
              bucket: 'kyc-documents',
              path: path,
            );
          } else {
            // Fallback for mock/testing without encryption service
            // Note: In strict production this should throw, but allowing for now.
            await Supabase.instance.client.storage
                .from('kyc-documents')
                .upload(path, file);
            return Supabase.instance.client.storage
                .from('kyc-documents')
                .getPublicUrl(path);
          }
        }

        // Upload national ID front
        final nationalIdFrontPath =
            '$userId/national_id_front_$timestamp.${_nationalIdFront?.path.split('.').last}';
        final nationalIdFrontUrl = await uploadFile(
          _nationalIdFront!,
          nationalIdFrontPath,
        );

        // Upload national ID back
        final nationalIdBackPath =
            '$userId/national_id_back_$timestamp.${_nationalIdBack!.path.split('.').last}';
        final nationalIdBackUrl = await uploadFile(
          _nationalIdBack!,
          nationalIdBackPath,
        );

        // Upload selfie with ID
        final selfieWithIdPath =
            '$userId/selfie_with_id_$timestamp.${_selfieWithId!.path.split('.').last}';
        final selfieWithIdUrl = await uploadFile(
          _selfieWithId!,
          selfieWithIdPath,
        );

        // Upload secondary ID front
        final secondaryIdFrontPath =
            '$userId/secondary_id_front_$timestamp.${_secondaryIdFront!.path.split('.').last}';
        final secondaryIdFrontUrl = await uploadFile(
          _secondaryIdFront!,
          secondaryIdFrontPath,
        );

        // Upload secondary ID back
        final secondaryIdBackPath =
            '$userId/secondary_id_back_$timestamp.${_secondaryIdBack!.path.split('.').last}';
        final secondaryIdBackUrl = await uploadFile(
          _secondaryIdBack!,
          secondaryIdBackPath,
        );

        // Upload proof of address
        final proofOfAddressPath =
            '$userId/proof_of_address_$timestamp.${_proofOfAddress?.path.split('.').last}';
        final proofOfAddressUrl = await uploadFile(
          _proofOfAddress!,
          proofOfAddressPath,
        );

        // Step 2: Create KYC registration model with all data
        // Convert sex to single character format (M/F) if needed
        String sexCode = _sex!;
        if (_sex == 'Male') {
          sexCode = 'M';
        } else if (_sex == 'Female') {
          sexCode = 'F';
        } else if (_sex!.length > 1) {
          // Handle any other format - take first character
          sexCode = _sex![0].toUpperCase();
        }

        final kycModel = KycRegistrationModel(
          id: userId,
          email: _email!,
          username: _username!,
          firstName: _firstName!,
          lastName: _lastName!,
          middleName: _middleName,
          dateOfBirth: _dateOfBirth!,
          sex: sexCode,
          region: _region!,
          province: _province!,
          city: _city!,
          barangay: _barangay!,
          streetAddress: _street!,
          zipcode: _zipCode!,
          nationalIdNumber: _nationalIdNumber!,
          nationalIdFrontUrl: nationalIdFrontUrl,
          nationalIdBackUrl: nationalIdBackUrl,
          secondaryGovIdType: _secondaryIdType!,
          secondaryGovIdNumber: _secondaryIdNumber!,
          secondaryGovIdFrontUrl: secondaryIdFrontUrl,
          secondaryGovIdBackUrl: secondaryIdBackUrl,
          proofOfAddressType:
              'Utility Bill', // You may want to add a field for this
          proofOfAddressUrl: proofOfAddressUrl,
          selfieWithIdUrl: selfieWithIdUrl,
          acceptedTermsAt: DateTime.now(),
          acceptedPrivacyAt: DateTime.now(),
          submittedAt: DateTime.now(),
        );

        // Step 3: Submit KYC registration to database
        await _authDataSource.submitKycRegistration(kycModel);
      } else {
        // Mock implementation - just delay
        await Future.delayed(const Duration(seconds: 2));
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
}
