import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';

/// Supabase data source for user profile operations
/// Handles profile CRUD operations and image uploads to Supabase Storage
class ProfileSupabaseDataSource {
  final SupabaseClient _supabase;

  ProfileSupabaseDataSource(this._supabase);

  /// Get current user's profile from users table (KYC users)
  /// Uses phone or email to query, bypasses RLS with public policy
  Future<UserProfileModel?> getUserProfile(String userId) async {
    try {
      // Get current auth user
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      // Query by phone number (with public RLS policy allowing approved users)
      // This works because RLS policy 2 allows viewing approved active users
      final phoneToQuery = currentUser.phone?.replaceAll('+63', '') ?? '';

      var response = await _supabase
          .from('users')
          .select()
          .eq('phone_number', phoneToQuery)
          .maybeSingle();

      // If not found by phone, try by email
      if (response == null && currentUser.email != null) {
        response = await _supabase
            .from('users')
            .select()
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
      if (contactNumber != null) updates['phone_number'] = contactNumber;
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
}
