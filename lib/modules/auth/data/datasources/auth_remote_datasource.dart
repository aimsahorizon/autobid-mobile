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
      // Supabase uses email for authentication
      // Assuming username is email format or we have email mapping
      final response = await _supabase.auth.signInWithPassword(
        email: username.contains('@') ? username : '$username@autobid.com',
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign in failed: No user returned');
      }

      // Convert to UserModel
      return UserModel(
        id: response.user!.id,
        email: response.user!.email ?? '',
        username: response.user!.userMetadata?['username'] as String?,
        displayName: response.user!.userMetadata?['display_name'] as String?,
        photoUrl: response.user!.userMetadata?['avatar_url'] as String?,
      );
    } on AuthException catch (e) {
      throw Exception('Sign in failed: ${e.message}');
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
      // Convert username to email if needed
      final email = username.contains('@') ? username : '$username@autobid.com';

      // Send password reset email via Supabase
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.autobid://reset-password',
      );
    } on AuthException catch (e) {
      throw Exception('Password reset failed: ${e.message}');
    } catch (e) {
      throw Exception('Password reset failed: $e');
    }
  }

  @override
  Future<bool> verifyOtp(String username, String otp) async {
    try {
      // Convert username to email
      final email = username.contains('@') ? username : '$username@autobid.com';

      // Verify OTP with Supabase
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: otp,
      );

      // Return true if verification successful
      return response.user != null;
    } on AuthException catch (e) {
      throw Exception('OTP verification failed: ${e.message}');
    } catch (e) {
      throw Exception('OTP verification failed: $e');
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

      // Insert KYC registration data into users table
      // kyc_status will default to 'pending' and await admin approval
      await _supabase.from('users').insert(kycData.toJson());
    } on PostgrestException catch (e) {
      // Handle database errors (e.g., duplicate username, constraint violations)
      throw Exception('Failed to submit KYC registration: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit KYC registration: $e');
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
      // Check if username exists in pending_registrations table
      final pendingResponse = await _supabase
          .from('pending_registrations')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      // Check if username exists in user_public_data table (approved users)
      final publicResponse = await _supabase
          .from('user_public_data')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      // Username is available if it doesn't exist in either table
      return pendingResponse == null && publicResponse == null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check username availability: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check username availability: $e');
    }
  }
}
