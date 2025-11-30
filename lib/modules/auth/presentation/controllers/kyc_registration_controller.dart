import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/usecases/send_email_otp_usecase.dart';
import '../../domain/usecases/send_phone_otp_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/verify_email_otp_usecase.dart';
import '../../domain/usecases/verify_phone_otp_usecase.dart';
import '../../../profile/data/datasources/profile_supabase_datasource.dart';

enum KYCStep {
  nationalId,
  selfieWithId,
  secondaryId,
  personalInfo,
  accountInfo,
  otpVerification,
  address,
  proofOfAddress,
  review,
}

class KYCRegistrationController extends ChangeNotifier {
  final SignUpUseCase? _signUpUseCase;
  final ProfileSupabaseDataSource? _profileDataSource;
  final SendEmailOtpUseCase? _sendEmailOtpUseCase;
  final SendPhoneOtpUseCase? _sendPhoneOtpUseCase;
  final VerifyEmailOtpUseCase? _verifyEmailOtpUseCase;
  final VerifyPhoneOtpUseCase? _verifyPhoneOtpUseCase;

  /// Constructor with optional dependencies for Supabase integration
  /// If not provided, registration will use mock implementation
  KYCRegistrationController({
    SignUpUseCase? signUpUseCase,
    ProfileSupabaseDataSource? profileDataSource,
    SendEmailOtpUseCase? sendEmailOtpUseCase,
    SendPhoneOtpUseCase? sendPhoneOtpUseCase,
    VerifyEmailOtpUseCase? verifyEmailOtpUseCase,
    VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase,
  }) : _signUpUseCase = signUpUseCase,
       _profileDataSource = profileDataSource,
       _sendEmailOtpUseCase = sendEmailOtpUseCase,
       _sendPhoneOtpUseCase = sendPhoneOtpUseCase,
       _verifyEmailOtpUseCase = verifyEmailOtpUseCase,
       _verifyPhoneOtpUseCase = verifyPhoneOtpUseCase;

  KYCStep _currentStep = KYCStep.nationalId;
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
  String? _phoneNumber;
  String? _password;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;

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
  String? get phoneNumber => _phoneNumber;
  String? get password => _password;
  bool get termsAccepted => _termsAccepted;
  bool get privacyAccepted => _privacyAccepted;

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

  // Step 1 setters
  void setNationalIdNumber(String value) {
    _nationalIdNumber = value;
    notifyListeners();
  }

  void setNationalIdFront(File? file) {
    _nationalIdFront = file;
    notifyListeners();
  }

  void setNationalIdBack(File? file) {
    _nationalIdBack = file;
    notifyListeners();
  }

  // Step 2 setters
  void setSelfieWithId(File? file) {
    _selfieWithId = file;
    notifyListeners();
  }

  void setAiAutoFillAccepted(bool value) {
    _aiAutoFillAccepted = value;
    notifyListeners();
  }

  // Step 3 setters
  void setSecondaryIdType(String? value) {
    _secondaryIdType = value;
    notifyListeners();
  }

  void setSecondaryIdNumber(String value) {
    _secondaryIdNumber = value;
    notifyListeners();
  }

  void setSecondaryIdFront(File? file) {
    _secondaryIdFront = file;
    notifyListeners();
  }

  void setSecondaryIdBack(File? file) {
    _secondaryIdBack = file;
    notifyListeners();
  }

  // Step 4 setters
  void setFirstName(String value) {
    _firstName = value;
    notifyListeners();
  }

  void setMiddleName(String value) {
    _middleName = value;
    notifyListeners();
  }

  void setLastName(String value) {
    _lastName = value;
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    _dateOfBirth = value;
    notifyListeners();
  }

  void setSex(String value) {
    _sex = value;
    notifyListeners();
  }

  // Step 5 setters
  void setUsername(String value) {
    _username = value;
    notifyListeners();
  }

  void setEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void setPhoneNumber(String value) {
    _phoneNumber = value;
    notifyListeners();
  }

  void setPassword(String value) {
    _password = value;
    notifyListeners();
  }

  void setTermsAccepted(bool value) {
    _termsAccepted = value;
    notifyListeners();
  }

  void setPrivacyAccepted(bool value) {
    _privacyAccepted = value;
    notifyListeners();
  }

  // Step 6 setters
  void setPhoneOtpVerified(bool value) {
    _phoneOtpVerified = value;
    notifyListeners();
  }

  void setEmailOtpVerified(bool value) {
    _emailOtpVerified = value;
    notifyListeners();
  }

  // Step 6: OTP sending and verification methods
  Future<void> sendPhoneOtp() async {
    if (_phoneNumber == null || _sendPhoneOtpUseCase == null) {
      throw Exception('Phone number not set or use case not available');
    }

    try {
      await _sendPhoneOtpUseCase!.call(_phoneNumber!);
    } catch (e) {
      throw Exception('Failed to send phone OTP: $e');
    }
  }

  Future<void> sendEmailOtp() async {
    if (_email == null || _sendEmailOtpUseCase == null) {
      throw Exception('Email not set or use case not available');
    }

    try {
      await _sendEmailOtpUseCase!.call(_email!);
    } catch (e) {
      throw Exception('Failed to send email OTP: $e');
    }
  }

  Future<bool> verifyPhoneOtp(String otp) async {
    if (_phoneNumber == null || _verifyPhoneOtpUseCase == null) {
      return false;
    }

    try {
      final isVerified = await _verifyPhoneOtpUseCase!.call(_phoneNumber!, otp);
      if (isVerified) {
        setPhoneOtpVerified(true);
      }
      return isVerified;
    } catch (e) {
      throw Exception('Phone OTP verification failed: $e');
    }
  }

  Future<bool> verifyEmailOtp(String otp) async {
    if (_email == null || _verifyEmailOtpUseCase == null) {
      return false;
    }

    try {
      final isVerified = await _verifyEmailOtpUseCase!.call(_email!, otp);
      if (isVerified) {
        setEmailOtpVerified(true);
      }
      return isVerified;
    } catch (e) {
      throw Exception('Email OTP verification failed: $e');
    }
  }

  // Step 7 setters
  void setRegion(String? value) {
    _region = value;
    _province = null;
    _city = null;
    _barangay = null;
    notifyListeners();
  }

  void setProvince(String? value) {
    _province = value;
    _city = null;
    _barangay = null;
    notifyListeners();
  }

  void setCity(String? value) {
    _city = value;
    _barangay = null;
    notifyListeners();
  }

  void setBarangay(String? value) {
    _barangay = value;
    notifyListeners();
  }

  void setStreet(String value) {
    _street = value;
    notifyListeners();
  }

  void setZipCode(String value) {
    _zipCode = value;
    notifyListeners();
  }

  // Step 8 setters
  void setProofOfAddress(File? file) {
    _proofOfAddress = file;
    notifyListeners();
  }

  // Navigation
  void nextStep() {
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

  // Validation methods
  bool validateNationalIdStep() {
    if (_nationalIdNumber == null || _nationalIdNumber!.isEmpty) {
      setError('Please enter your National ID number');
      return false;
    }
    if (_nationalIdFront == null) {
      setError('Please upload the front of your National ID');
      return false;
    }
    if (_nationalIdBack == null) {
      setError('Please upload the back of your National ID');
      return false;
    }
    return true;
  }

  bool validateSelfieStep() {
    if (_selfieWithId == null) {
      setError('Please take a selfie with your ID');
      return false;
    }
    return true;
  }

  bool validateSecondaryIdStep() {
    if (_secondaryIdType == null || _secondaryIdType!.isEmpty) {
      setError('Please select a secondary ID type');
      return false;
    }
    if (_secondaryIdNumber == null || _secondaryIdNumber!.isEmpty) {
      setError('Please enter your secondary ID number');
      return false;
    }
    if (_secondaryIdFront == null) {
      setError('Please upload the front of your secondary ID');
      return false;
    }
    if (_secondaryIdBack == null) {
      setError('Please upload the back of your secondary ID');
      return false;
    }
    return true;
  }

  bool validatePersonalInfoStep() {
    if (_firstName == null || _firstName!.isEmpty) {
      setError('Please enter your first name');
      return false;
    }
    if (_lastName == null || _lastName!.isEmpty) {
      setError('Please enter your last name');
      return false;
    }
    if (_dateOfBirth == null) {
      setError('Please select your date of birth');
      return false;
    }
    if (_sex == null || _sex!.isEmpty) {
      setError('Please select your sex');
      return false;
    }
    return true;
  }

  bool validateAccountInfoStep() {
    if (_username == null || _username!.isEmpty) {
      setError('Please enter a username');
      return false;
    }
    if (_email == null || _email!.isEmpty) {
      setError('Please enter your email');
      return false;
    }
    if (_phoneNumber == null || _phoneNumber!.isEmpty) {
      setError('Please enter your phone number');
      return false;
    }
    if (_password == null || _password!.isEmpty) {
      setError('Please enter a password');
      return false;
    }
    if (!_termsAccepted) {
      setError('Please accept the Terms & Conditions');
      return false;
    }
    if (!_privacyAccepted) {
      setError('Please accept the Privacy Policy');
      return false;
    }
    return true;
  }

  bool validateOtpStep() {
    if (!_phoneOtpVerified) {
      setError('Please verify your phone number');
      return false;
    }
    if (!_emailOtpVerified) {
      setError('Please verify your email');
      return false;
    }
    return true;
  }

  bool validateAddressStep() {
    if (_region == null || _region!.isEmpty) {
      setError('Please select your region');
      return false;
    }
    if (_province == null || _province!.isEmpty) {
      setError('Please select your province');
      return false;
    }
    if (_city == null || _city!.isEmpty) {
      setError('Please select your city');
      return false;
    }
    if (_barangay == null || _barangay!.isEmpty) {
      setError('Please select your barangay');
      return false;
    }
    if (_street == null || _street!.isEmpty) {
      setError('Please enter your street address');
      return false;
    }
    if (_zipCode == null || _zipCode!.isEmpty) {
      setError('Please enter your ZIP code');
      return false;
    }
    return true;
  }

  bool validateProofOfAddressStep() {
    if (_proofOfAddress == null) {
      setError('Please upload proof of address');
      return false;
    }
    return true;
  }

  // AI Auto-fill functionality (mock)
  Future<void> performAIAutoFill() async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // Mock AI extracted data
    _firstName = 'Juan';
    _middleName = 'Santos';
    _lastName = 'Dela Cruz';
    _dateOfBirth = DateTime(1990, 5, 15);
    _sex = 'Male';

    _isLoading = false;
    notifyListeners();
  }

  // Submit registration
  Future<void> submitRegistration() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Check if dependencies are injected (real Supabase implementation)
      if (_signUpUseCase != null && _profileDataSource != null) {
        // Step 1: Create auth account
        final user = await _signUpUseCase!.call(
          email: _email!,
          password: _password!,
          username: _email!.split('@')[0],
        );

        // Step 2: Upload profile photo (selfie)
        final profilePhotoUrl = await _profileDataSource!.uploadProfilePhoto(
          user.id,
          _selfieWithId!,
        );

        // Step 3: Create user profile with all KYC data
        await _profileDataSource!.createProfile(
          userId: user.id,
          username: _email!.split('@')[0],
          fullName: '$_firstName ${_middleName ?? ''} $_lastName'.trim(),
          email: _email!,
          contactNumber: _phoneNumber,
        );

        // Step 4: Update profile with photo URL
        await _profileDataSource!.updateProfile(
          userId: user.id,
          profilePhotoUrl: profilePhotoUrl,
        );

        // TODO: Upload ID documents to user-documents bucket
        // This requires a separate storage method for private documents
        // For now, we've completed the basic profile creation
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
