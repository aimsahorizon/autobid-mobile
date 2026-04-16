import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../../domain/entities/user_review_entity.dart';

/// Supabase data source for user profile operations
/// Handles profile CRUD operations and image uploads to Supabase Storage
class ProfileSupabaseDataSource {
  final SupabaseClient _supabase;

  ProfileSupabaseDataSource(this._supabase);

  /// Get current user's profile from users table (KYC users)
  /// Get current user's profile from users table (KYC users)
  /// Uses user ID or email to query, bypasses RLS with public policy
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      // Get current auth user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      // Query by user ID first (most direct) with address join
      var response = await _supabase
          .from('users')
          .select('*, user_addresses(*)')
          .eq('id', userId)
          .maybeSingle();

      // If not found by ID, try by email
      if (response == null && currentUser.email != null) {
        response = await _supabase
            .from('users')
            .select('*, user_addresses(*)')
            .eq('email', currentUser.email!)
            .maybeSingle();
      }

      // Return null if no profile found
      if (response == null) {
        return null;
      }

      // Convert JSON response to UserProfileModel
      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Handle database errors (including RLS violations)
      throw Exception('Failed to get profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Create new user profile (called after signup or Google Sign-In)
  /// Inserts minimal data into user_profiles table
  Future<UserProfileModel> createProfile({
    required String userId,
    required String username,
    required String fullName,
    required String email,
    String? contactNumber,
  }) async {
    try {
      // Insert user profile data into user_profiles table
      final response = await _supabase
          .from('user_profiles')
          .insert({
            'id': userId,
            'username': username,
            'full_name': fullName,
            'email': email,
            'contact_number': contactNumber ?? '',
          })
          .select()
          .single();

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }

  /// Update user profile information
  /// Updates fields in users table
  Future<UserProfileModel> updateProfile({
    required String userId,
    String? fullName,
    String? username,
    String? contactNumber,
    String? coverPhotoUrl,
    String? profilePhotoUrl,
  }) async {
    try {
      // Build update map with only non-null fields
      final Map<String, dynamic> updates = {};
      if (username != null) updates['username'] = username;
      if (coverPhotoUrl != null) updates['cover_photo_url'] = coverPhotoUrl;
      if (profilePhotoUrl != null) {
        updates['profile_photo_url'] = profilePhotoUrl;
      }

      // Note: fullName is not updated here as it's derived from first/middle/last names
      // To update name, update first_name, middle_name, last_name separately

      // Update profile in users table and return updated data
      final response = await _supabase
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();

      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Check for duplicate username constraint violation
      if (e.code == '23505') {
        throw Exception('Username already taken');
      }
      throw Exception('Failed to update profile: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Upload profile photo to Supabase Storage (avatars bucket)
  /// Returns public URL of uploaded image
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final filename = 'profile_$timestamp.$extension';
      final filepath = '$userId/$filename';

      // Upload to avatars bucket
      await _supabase.storage
          .from('avatars')
          .upload(
            filepath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filepath);

      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Failed to upload profile photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload profile photo: $e');
    }
  }

  /// Upload cover photo to Supabase Storage (avatars bucket with cover prefix)
  /// Returns public URL of uploaded image
  Future<String> uploadCoverPhoto(String userId, File imageFile) async {
    try {
      // Generate unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final filename = 'cover_$timestamp.$extension';
      final filepath = '$userId/$filename';

      // Upload to avatars bucket
      await _supabase.storage
          .from('avatars')
          .upload(
            filepath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl(filepath);

      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Failed to upload cover photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload cover photo: $e');
    }
  }

  /// Delete old photo from Storage (cleanup)
  /// Call before uploading new photo to avoid storage bloat
  Future<void> deletePhoto(String photoUrl, String bucket) async {
    try {
      // Extract filepath from public URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // URL format: /storage/v1/object/public/bucket-name/filepath
      if (pathSegments.length < 5) return; // Invalid URL format

      final filepath = pathSegments.sublist(5).join('/');

      // Delete from storage
      await _supabase.storage.from(bucket).remove([filepath]);
    } on StorageException catch (e) {
      // Log error but don't throw - deletion is not critical
      debugPrint('Failed to delete photo: ${e.message}');
    } catch (e) {
      debugPrint('Failed to delete photo: $e');
    }
  }

  /// Check if email exists in user_profiles table
  /// Used for Google Sign-In validation
  Future<bool> checkEmailExists(String email) async {
    try {
      // Query user_profiles for email
      final response = await _supabase
          .from('user_profiles')
          .select('id')
          .eq('email', email)
          .maybeSingle();

      // Return true if profile found
      return response != null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check email: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check email: $e');
    }
  }

  /// Get user profile by email
  /// Used to fetch profile data during login
  Future<UserProfileModel?> getUserProfileByEmail(String email) async {
    try {
      // Query user_profiles table by email
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('email', email)
          .maybeSingle();

      // Return null if no profile found
      if (response == null) return null;

      // Convert JSON response to UserProfileModel
      return UserProfileModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get profile by email: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get profile by email: $e');
    }
  }

  /// Get all reviews received by a user (as reviewee)
  /// Joins with users table to get reviewer name and photo
  Future<List<UserReviewEntity>> getReviewsForUser(String userId) async {
    try {
      final response = await _supabase
          .from('transaction_reviews')
          .select('''
            id,
            transaction_id,
            reviewer_id,
            rating,
            comment,
            created_at,
            reviewer:users!transaction_reviews_reviewer_id_fkey(
              full_name,
              profile_photo_url
            )
          ''')
          .eq('reviewee_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((data) {
        final reviewer = data['reviewer'] as Map<String, dynamic>?;

        // Build full_name from first/middle/last or use full_name directly
        String reviewerName = 'Anonymous';
        if (reviewer != null) {
          if (reviewer['full_name'] != null &&
              (reviewer['full_name'] as String).isNotEmpty) {
            reviewerName = reviewer['full_name'] as String;
          }
        }

        return UserReviewEntity(
          id: data['id'] as String,
          transactionId: data['transaction_id'] as String,
          reviewerId: data['reviewer_id'] as String,
          reviewerName: reviewerName,
          reviewerPhotoUrl: reviewer?['profile_photo_url'] as String?,
          rating: data['rating'] as int,
          comment: data['comment'] as String?,
          createdAt: DateTime.parse(data['created_at'] as String),
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('Failed to get reviews for user: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Failed to get reviews for user: $e');
      return [];
    }
  }

  /// Change user password
  /// Verifies old password first by re-authenticating
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      // 1. Verify old password by attempting to sign in
      try {
        await _supabase.auth.signInWithPassword(
          email: user.email,
          password: currentPassword,
        );
      } on AuthException {
        throw Exception('Incorrect current password');
      }

      // 2. Update password
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user == null) {
        throw Exception('Failed to update password');
      }
    } on AuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception('Failed to change password: $e');
    }
  }

  /// Get another user's public profile with bidding & transaction stats
  /// Uses the get_user_bidding_stats RPC
  Future<UserProfileModel?> getUserBiddingStats(String userId) async {
    try {
      final result = await _supabase.rpc(
        'get_user_bidding_stats',
        params: {'p_user_id': userId},
      );
      if (result is Map<String, dynamic>) {
        return UserProfileModel.fromStatsJson(result);
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('Failed to get user bidding stats: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Failed to get user bidding stats: $e');
      return null;
    }
  }

  /// Fetch the current user's KYC data (personal info + documents).
  /// Returns a merged map from `users`, `user_addresses`, and `kyc_documents`.
  Future<Map<String, dynamic>?> getMyKycData() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return null;

    // ── 1. Fetch user row (with email fallback) ─────────────────────────────
    Map<String, dynamic>? userRow = await _supabase
        .from('users')
        .select(
          'id, first_name, last_name, middle_name, date_of_birth, sex, '
          'accepted_terms_at, accepted_privacy_at',
        )
        .eq('id', currentUser.id)
        .maybeSingle();

    if (userRow == null && currentUser.email != null) {
      userRow = await _supabase
          .from('users')
          .select(
            'id, first_name, last_name, middle_name, date_of_birth, sex, '
            'accepted_terms_at, accepted_privacy_at',
          )
          .eq('email', currentUser.email!)
          .maybeSingle();
    }

    final userId = userRow?['id'] as String? ?? currentUser.id;

    // ── 2. Fetch default address separately ─────────────────────────────────
    final addressList = await _supabase
        .from('user_addresses')
        .select('region, province, city, barangay, street_address, zipcode')
        .eq('user_id', userId);

    Map<String, dynamic> address = {};
    if (addressList.isNotEmpty) {
      // Prefer the default address if the column exists and is flagged
      final rows = addressList.cast<Map<String, dynamic>>();
      address = rows.firstWhere(
        (r) => r['is_default'] == true,
        orElse: () => rows.first,
      );
    }

    // ── 3. Fetch all KYC documents (most recent first) ───────────────────────
    final kycList = await _supabase
        .from('kyc_documents')
        .select(
          'id, user_id, status_id, '
          'national_id_number, national_id_front_url, national_id_back_url, '
          'secondary_gov_id_type, secondary_gov_id_number, '
          'secondary_gov_id_front_url, secondary_gov_id_back_url, '
          'proof_of_address_type, proof_of_address_url, '
          'selfie_with_id_url, document_type, '
          'submitted_at, reviewed_at, reviewed_by, '
          'rejection_reason, admin_notes, expires_at, '
          'created_at, updated_at, '
          'kyc_statuses(status_name)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    Map<String, dynamic>? latestKyc;
    String? kycStatusName;

    if (kycList.isNotEmpty) {
      latestKyc = Map<String, dynamic>.from(
        (kycList as List).first as Map<String, dynamic>,
      );
      // Resolve status name from joined kyc_statuses
      final statusData = latestKyc['kyc_statuses'];
      if (statusData is Map<String, dynamic>) {
        kycStatusName = statusData['status_name'] as String?;
      } else if (statusData is List && statusData.isNotEmpty) {
        kycStatusName =
            (statusData.first as Map<String, dynamic>)['status_name']
                as String?;
      }
      kycStatusName ??= 'pending';
    }

    if (userRow == null && latestKyc == null) return null;

    return {
      ...?userRow,
      'address': address,
      'kyc': latestKyc,
      'kyc_all': kycList,
      'kyc_status': kycStatusName,
    };
  }
}
