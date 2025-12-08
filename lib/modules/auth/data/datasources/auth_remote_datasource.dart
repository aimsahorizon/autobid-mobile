import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final SupabaseClient _supabase;
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
      throw Exception('Failed to get current user: $e');
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
        throw AuthException('Invalid username or password');
      }

      final emailToUse = userRecord['email'] as String;
      final phoneNumber = userRecord['phone_number'] as String?;
      final displayName = userRecord['display_name'] as String?;
      final isActive = userRecord['is_active'] as bool? ?? true;

      // Check if account is active (not suspended/banned)
      if (!isActive) {
        throw AuthException(
          'Your account has been suspended or deactivated. Please contact support.',
        );
      }

      // Note: is_verified is checked separately if needed for feature gating
      // Users can login even if KYC not approved (is_verified = false)
      // but may have limited features until KYC is approved

      // Step 2: Authenticate with Supabase Auth using email and password
      final response = await _supabase.auth.signInWithPassword(
        email: emailToUse,
        password: password,
      );

      if (response.user == null) {
        throw AuthException('Invalid usernames or password');
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
    } on AuthException catch (e) {
      // Re-throw AuthException with proper message
      throw Exception(e.message);
    } on PostgrestException catch (e) {
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    try {
      // Step 1: Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Google sign in was cancelled');
      }

      // Step 2: Get Google authentication tokens
      final googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      // Step 3: Sign in to Supabase with Google ID token
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user == null) {
        throw Exception('Google sign in failed: No user returned');
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
    } catch (e) {
      throw Exception('Google sign in failed: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      // Sign out from both Google and Supabase
      await Future.wait([_googleSignIn.signOut(), _supabase.auth.signOut()]);
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  @override
  Future<void> sendPasswordResetRequest(String username) async {
    try {
      // Look up the actual email associated with the username from users table
      final userRecord = await _supabase
          .from('users')
          .select('email')
          .eq('username', username)
          .maybeSingle();

      // Check if user exists
      if (userRecord == null) {
        throw Exception('Username not found');
      }

      final email = userRecord['email'] as String;

      // Send password reset email via Supabase to the actual email
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.autobid://reset-password',
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to find user: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
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
        throw Exception('Username not found');
      }

      final email = userRecord['email'] as String;

      // Verify OTP with Supabase using the actual email
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to find user: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('OTP verification failed: ${e.message}');
    } catch (e) {
      throw Exception('OTP verification failed: $e');
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
        throw Exception('Username not found');
      }

      final email = userRecord['email'] as String;

      // Update password for the authenticated user
      // Note: User must be authenticated (via OTP verification) to update password
      await _supabase.auth.updateUser(
        UserAttributes(
          email: email,
          password: newPassword,
        ),
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to find user: ${e.message}');
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
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
        throw Exception('Sign up failed: No user returned');
      }

      // Convert to UserModel
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? email,
        username: username,
        displayName: username,
      );
    } on AuthException catch (e) {
      throw Exception('Sign up failed: ${e.message}');
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  @override
  Future<void> sendEmailOtp(String email) async {
    try {
      // Send OTP to email using Supabase
      // shouldCreateUser: true allows OTP sending even if user doesn't exist
      // This is needed for registration flow where user hasn't signed up yet
      await _supabase.auth.signInWithOtp(email: email, shouldCreateUser: true);
    } on AuthException catch (e) {
      throw Exception('Failed to send email OTP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send email OTP: $e');
    }
  }

  @override
  Future<void> sendPhoneOtp(String phoneNumber) async {
    try {
      // Format phone number with country code if not present
      // Philippine phone numbers: +63 followed by 10 digits
      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+63$phoneNumber';

      // Send OTP to phone using Supabase
      // shouldCreateUser: true allows OTP sending for registration flow
      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
        shouldCreateUser: true,
      );
    } on AuthException catch (e) {
      throw Exception('Failed to send phone OTP: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send phone OTP: $e');
    }
  }

  @override
  Future<bool> verifyEmailOtp(String email, String otp) async {
    try {
      // Verify email OTP with Supabase
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on AuthException catch (e) {
      throw Exception('Email OTP verification failed: ${e.message}');
    } catch (e) {
      throw Exception('Email OTP verification failed: $e');
    }
  }

  @override
  Future<bool> verifyPhoneOtp(String phoneNumber, String otp) async {
    try {
      // Format phone number with country code if not present
      final formattedPhone = phoneNumber.startsWith('+')
          ? phoneNumber
          : '+63$phoneNumber';

      // Verify phone OTP with Supabase
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.sms,
        phone: formattedPhone,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on AuthException catch (e) {
      throw Exception('Phone OTP verification failed: ${e.message}');
    } catch (e) {
      throw Exception('Phone OTP verification failed: $e');
    }
  }

  @override
  Future<void> submitKycRegistration(KycRegistrationModel kycData) async {
    try {
      // Get current authenticated user (must be authenticated after OTP verification)
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Please verify OTP first.');
      }

      // Use RPC function to atomically insert across users, user_addresses, and kyc_documents tables
      // This handles normalized 3-table structure properly
      final result = await _supabase.rpc('register_user_with_kyc', params: {
        'p_user_id': kycData.id,
        'p_email': kycData.email,
        'p_username': kycData.username,
        'p_phone_number': kycData.phoneNumber,
        'p_first_name': kycData.firstName,
        'p_last_name': kycData.lastName,
        'p_middle_name': kycData.middleName ?? '', // Handle null middle name
        'p_date_of_birth': kycData.dateOfBirth.toIso8601String().split('T')[0],
        'p_sex': kycData.sex.toLowerCase(), // Convert 'M'/'F' to 'male'/'female'
        'p_region': kycData.region,
        'p_province': kycData.province,
        'p_city': kycData.city,
        'p_barangay': kycData.barangay,
        'p_street_address': kycData.streetAddress,
        'p_zipcode': kycData.zipcode,
        'p_national_id_number': kycData.nationalIdNumber,
        'p_national_id_front_url': kycData.nationalIdFrontUrl,
        'p_national_id_back_url': kycData.nationalIdBackUrl,
        'p_secondary_gov_id_type': kycData.secondaryGovIdType.toLowerCase().replaceAll(' ', '_'), // Normalize format
        'p_secondary_gov_id_number': kycData.secondaryGovIdNumber,
        'p_secondary_gov_id_front_url': kycData.secondaryGovIdFrontUrl,
        'p_secondary_gov_id_back_url': kycData.secondaryGovIdBackUrl,
        'p_proof_of_address_type': kycData.proofOfAddressType.toLowerCase().replaceAll(' ', '_'), // Normalize format
        'p_proof_of_address_url': kycData.proofOfAddressUrl,
        'p_selfie_with_id_url': kycData.selfieWithIdUrl,
        'p_accepted_terms_at': kycData.acceptedTermsAt.toIso8601String(),
        'p_accepted_privacy_at': kycData.acceptedPrivacyAt.toIso8601String(),
      });

      // Check if registration was successful
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to submit KYC registration');
      }
    } on PostgrestException catch (e) {
      // Handle database errors (e.g., duplicate username, constraint violations)
      throw Exception('Failed to submit KYC registration: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit KYC registration: $e');
    }
  }

  /// Set password for OTP-authenticated user
  /// This enables password-based login after OTP registration
  @override
  Future<void> setPasswordForOtpUser(String password) async {
    try {
      // Update the current user's password in Supabase Auth
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );

      if (response.user == null) {
        throw Exception('Failed to set password');
      }
    } on AuthException catch (e) {
      throw Exception('Failed to set password: ${e.message}');
    } catch (e) {
      throw Exception('Failed to set password: $e');
    }
  }

  @override
  Future<KycRegistrationModel?> getKycRegistrationStatus(String userId) async {
    try {
      // Query users table for the user's KYC registration status
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      // Return null if no registration found, otherwise convert to model
      if (response == null) return null;

      return KycRegistrationModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get KYC registration status: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get KYC registration status: $e');
    }
  }

  @override
  Future<bool> checkUsernameAvailable(String username) async {
    try {
      // Check if username exists in users table (all users: pending, approved, rejected)
      final response = await _supabase
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      // Username is available if it doesn't exist
      return response == null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check username availability: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }
}
