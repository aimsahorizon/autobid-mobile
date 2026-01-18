import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:autobid_mobile/core/error/exceptions.dart';
import '../models/user_model.dart';
import '../models/kyc_registration_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithUsername(String username, String password);
  Future<UserModel> signInWithGoogle();
  Future<void> signOut();
  Future<void> sendPasswordResetRequest(String username);
  Future<bool> verifyOtp(String username, String otp);
  Future<void> resetPassword(String username, String newPassword);
  Future<UserModel> signUp(String email, String password, {String? username});

  // OTP methods for registration flow
  Future<void> sendEmailOtp(String email);
  Future<void> sendPhoneOtp(String phoneNumber);
  Future<bool> verifyEmailOtp(String email, String otp);
  Future<bool> verifyPhoneOtp(String phoneNumber, String otp);

  // KYC Registration methods
  Future<void> submitKycRegistration(KycRegistrationModel kycData);
  Future<KycRegistrationModel?> getKycRegistrationStatus(String userId);
  Future<bool> checkUsernameAvailable(String username);
  Future<void> setPasswordForOtpUser(String password);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supabase.SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn;

  /// Constructor with Supabase client injection
  /// GoogleSignIn configured with web client ID from .env
  AuthRemoteDataSourceImpl(this._supabase)
    : _googleSignIn = GoogleSignIn(
        clientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
        serverClientId: dotenv.env['GOOGLE_WEB_CLIENT_ID'],
      );

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      // Get current session from Supabase
      final user = _supabase.auth.currentUser;

      if (user == null) return null;

      // Convert Supabase User to UserModel
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        username: user.userMetadata?['username'] as String?,
        displayName: user.userMetadata?['display_name'] as String?,
        photoUrl: user.userMetadata?['avatar_url'] as String?,
      );
    } catch (e) {
      throw ServerException('Failed to get current user: $e');
    }
  }

  @override
  Future<UserModel> signInWithUsername(String username, String password) async {
    try {
      // Step 1: Look up user by username and check account status
      final userRecord = await _supabase
          .from('users')
          .select('email, phone_number, is_active, is_verified, display_name')
          .eq('username', username)
          .maybeSingle();

      // Check if user exists
      if (userRecord == null) {
        // Try case-insensitive search to help debug
        final debugRecord = await _supabase
            .from('users')
            .select('username, email')
            .ilike('username', username)
            .maybeSingle();

        if (debugRecord != null) {
          throw const AuthException('Invalid username or password. Note: Username is case-sensitive.');
        }

        throw const AuthException('Invalid username or password');
      }

      final emailToUse = userRecord['email'] as String;
      final phoneNumber = userRecord['phone_number'] as String?;
      final displayName = userRecord['display_name'] as String?;
      final isActive = userRecord['is_active'] as bool? ?? true;

      // Check if account is active (not suspended/banned)
      if (!isActive) {
        throw const AuthException(
          'Your account has been suspended or deactivated. Please contact support.',
        );
      }

      // Step 2: Authenticate with Supabase Auth using email and password
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: emailToUse,
          password: password,
        );

        if (response.user == null) {
          throw const AuthException('Invalid username or password');
        }

        // Convert to UserModel with phone number from users table
        return UserModel(
          id: response.user!.id,
          email: response.user!.email ?? '',
          username: username,
          displayName: displayName ?? response.user!.userMetadata?['display_name'] as String?,
          photoUrl: response.user!.userMetadata?['avatar_url'] as String?,
          phoneNumber: phoneNumber,
        );
      } on supabase.AuthException catch (authError) {
        // Provide more specific error messages for auth failures
        if (authError.message.contains('Invalid login credentials')) {
          throw const AuthException(
            'Invalid username or password. If you registered via OTP, please use "Forgot Password" to set a password first.',
          );
        } else if (authError.message.contains('Email not confirmed')) {
          throw const AuthException('Email not verified. Please verify your email first.');
        } else {
          throw AuthException(authError.message);
        }
      }
    } on AuthException catch (e) {
      rethrow;
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Database error: ${e.message}');
    } catch (e) {
      throw ServerException('Sign in failed: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw const AuthException('Google sign in was cancelled');
      }

      // Step 2: Get Google authentication tokens
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw const AuthException('Failed to get Google ID token');
      }

      // Step 3: Sign in to Supabase with Google ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: supabase.OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        throw const AuthException('Google sign in failed: No user returned');
      }

      // Step 4: Convert to UserModel
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? '',
        displayName:
            response.user!.userMetadata?['full_name'] as String? ??
            googleUser.displayName,
        photoUrl:
            response.user!.userMetadata?['avatar_url'] as String? ??
            googleUser.photoUrl,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException(e.message);
    } catch (e) {
      throw ServerException('Google sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from both Google and Supabase
      await Future.wait([_googleSignIn.signOut(), _supabase.auth.signOut()]);
    } catch (e) {
      throw ServerException('Sign out failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetRequest(String username) async {
    try {
      // Look up the actual email associated with the username from users table
      final userRecord = await _supabase
          .from('users')
          .select('email, id, full_name')
          .eq('username', username)
          .maybeSingle();

      // Check if user exists
      if (userRecord == null) {
        // Try case-insensitive search to help debug
        final debugRecord = await _supabase
            .from('users')
            .select('username, email')
            .ilike('username', username)
            .maybeSingle();

        if (debugRecord != null) {
          throw const AuthException('Username found but with different case. Usernames are case-sensitive.');
        }

        throw const AuthException('Username not found. Please check your username and try again.');
      }

      final email = userRecord['email'] as String;

      // Send password reset email via Supabase to the actual email
      try {
        await _supabase.auth.resetPasswordForEmail(
          email,
          redirectTo: 'io.supabase.autobid://reset-password',
        );
      } on supabase.AuthException catch (authError) {
        // Check if email sending is configured
        if (authError.message.contains('Email') || authError.message.contains('SMTP')) {
          throw const ServerException(
            'Email service not configured. Please contact support or use OTP verification instead.',
          );
        } else {
          throw ServerException('Failed to send reset email: ${authError.message}');
        }
      }
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Database error: ${e.message}');
    } on AuthException catch (e) {
      rethrow;
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Password reset failed: $e');
    }
  }

  @override
  Future<bool> verifyOtp(String username, String otp) async {
    try {
      // Look up the actual email associated with the username from users table
      final userRecord = await _supabase
          .from('users')
          .select('email')
          .eq('username', username)
          .maybeSingle();

      // Check if user exists
      if (userRecord == null) {
        throw const AuthException('Username not found');
      }

      final email = userRecord['email'] as String;

      // Verify OTP with Supabase using the actual email
      final response = await _supabase.auth.verifyOTP(
        type: supabase.OtpType.email,
        email: email,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Failed to find user: ${e.message}');
    } on supabase.AuthException catch (e) {
      throw AuthException('OTP verification failed: ${e.message}');
    } catch (e) {
      throw ServerException('OTP verification failed: $e');
    }
  }

  @override
  Future<void> resetPassword(String username, String newPassword) async {
    try {
      // Look up the email associated with the username from users table
      final userRecord = await _supabase
          .from('users')
          .select('email')
          .eq('username', username)
          .maybeSingle();

      // Check if user exists
      if (userRecord == null) {
        throw const AuthException('Username not found');
      }

      final email = userRecord['email'] as String;

      // Update password for the authenticated user
      await _supabase.auth.updateUser(
        supabase.UserAttributes(
          email: email,
          password: newPassword,
        ),
      );
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Failed to find user: ${e.message}');
    } on supabase.AuthException catch (e) {
      throw AuthException('Password reset failed: ${e.message}');
    } catch (e) {
      throw ServerException('Password reset failed: $e');
    }
  }

  @override
  Future<UserModel> signUp(
    String email,
    String password, {
    String? username,
  }) async {
    try {
      // Sign up with Supabase
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'display_name': username},
      );

      if (response.user == null) {
        throw const AuthException('Sign up failed: No user returned');
      }

      // Convert to UserModel
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        username: username,
        displayName: username,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException('Sign up failed: ${e.message}');
    } catch (e) {
      throw ServerException('Sign up failed: $e');
    }
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    try {
      // Send OTP to email using Supabase
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);
    } on supabase.AuthException catch (e) {
      throw AuthException('Failed to send email OTP: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to send email OTP: $e');
    }
  }

  @override
  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+63$phoneNumber';

      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
        shouldCreateUser: true,
      );
    } on supabase.AuthException catch (e) {
      throw AuthException('Failed to send phone OTP: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to send phone OTP: $e');
    }
  }

  @override
  Future<bool> verifyEmailOtp(String email, String otp) async {
    try {
      // Verify email OTP with Supabase
      final response = await _supabase.auth.verifyOTP(
        type: supabase.OtpType.email,
        email: email,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on supabase.AuthException catch (e) {
      throw AuthException('Email OTP verification failed: ${e.message}');
    } catch (e) {
      throw ServerException('Email OTP verification failed: $e');
    }
  }

  @override
  Future<bool> verifyPhoneOtp(String phoneNumber, String otp) async {
    try {
      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+63$phoneNumber';

      // Verify phone OTP with Supabase
      final response = await _supabase.auth.verifyOTP(
        type: supabase.OtpType.sms,
        phone: formattedPhone,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on supabase.AuthException catch (e) {
      throw AuthException('Phone OTP verification failed: ${e.message}');
    } catch (e) {
      throw ServerException('Phone OTP verification failed: $e');
    }
  }

  @override
  Future<void> submitKycRegistration(KycRegistrationModel kycData) async {
    try {
      // Get current authenticated user
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw const AuthException('User not authenticated. Please verify OTP first.');
      }

      // Use RPC function
      final result = await _supabase.rpc('register_user_with_kyc', params: {
        'p_user_id': kycData.id,
        'p_email': kycData.email,
        'p_username': kycData.username,
        'p_phone_number': kycData.phoneNumber,
        'p_first_name': kycData.firstName,
        'p_last_name': kycData.lastName,
        'p_middle_name': kycData.middleName ?? '',
        'p_date_of_birth': kycData.dateOfBirth.toIso8601String().split('T')[0],
        'p_sex': kycData.sex.toLowerCase(),
        'p_region': kycData.region,
        'p_province': kycData.province,
        'p_city': kycData.city,
        'p_barangay': kycData.barangay,
        'p_street_address': kycData.streetAddress,
        'p_zipcode': kycData.zipcode,
        'p_national_id_number': kycData.nationalIdNumber,
        'p_national_id_front_url': kycData.nationalIdFrontUrl,
        'p_national_id_back_url': kycData.nationalIdBackUrl,
        'p_secondary_gov_id_type': kycData.secondaryGovIdType.toLowerCase().replaceAll(' ', '_'),
        'p_secondary_gov_id_number': kycData.secondaryGovIdNumber,
        'p_secondary_gov_id_front_url': kycData.secondaryGovIdFrontUrl,
        'p_secondary_gov_id_back_url': kycData.secondaryGovIdBackUrl,
        'p_proof_of_address_type': kycData.proofOfAddressType.toLowerCase().replaceAll(' ', '_'),
        'p_proof_of_address_url': kycData.proofOfAddressUrl,
        'p_selfie_with_id_url': kycData.selfieWithIdUrl,
        'p_accepted_terms_at': kycData.acceptedTermsAt.toIso8601String(),
        'p_accepted_privacy_at': kycData.acceptedPrivacyAt.toIso8601String(),
      });

      // Check if registration was successful
      if (result['success'] != true) {
        throw ServerException(result['error'] ?? 'Failed to submit KYC registration');
      }
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Failed to submit KYC registration: ${e.message}');
    } catch (e) {
      if (e is ServerException || e is AuthException) rethrow;
      throw ServerException('Failed to submit KYC registration: $e');
    }
  }

  @override
  Future<void> setPasswordForOtpUser(String password) async {
    try {
      // Update the current user's password in Supabase Auth
      final response = await _supabase.auth.updateUser(
        supabase.UserAttributes(password: password),
      );

      if (response.user == null) {
        throw const AuthException('Failed to set password');
      }
    } on supabase.AuthException catch (e) {
      throw AuthException('Failed to set password: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to set password: $e');
    }
  }

  @override
  Future<KycRegistrationModel?> getKycRegistrationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      return KycRegistrationModel.fromJson(response);
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Failed to get KYC registration status: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to get KYC registration status: $e');
    }
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final response = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } on supabase.PostgrestException catch (e) {
      throw ServerException('Failed to check username availability: ${e.message}');
    } catch (e) {
      throw ServerException('Failed to check username availability: $e');
    }
  }
}