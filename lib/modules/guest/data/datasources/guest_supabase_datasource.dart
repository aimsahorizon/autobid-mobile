import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/account_status_entity.dart';
import '../models/account_status_model.dart';

/// Data source for guest mode operations
/// Handles account status checking from Supabase
class GuestSupabaseDataSource {
  final SupabaseClient _supabase;

  GuestSupabaseDataSource(this._supabase);

  /// Check account status by email
  /// Returns status if user exists and has submitted KYC
  Future<AccountStatusModel?> checkAccountStatus(String email) async {
    try {
      print('[GuestDataSource] Checking account status for email: $email');

      // Query users table (KYC users are stored here)
      final response = await _supabase
          .from('users')
          .select(
            'id, email, first_name, middle_name, last_name, status, created_at, updated_at, rejection_reason',
          )
          .eq('email', email)
          .maybeSingle();

      print('[GuestDataSource] Response: $response');

      if (response == null) {
        print('[GuestDataSource] No user found with email: $email');
        return null;
      }

      // Build full name from first, middle, last name
      final firstName = response['first_name'] as String? ?? '';
      final middleName = response['middle_name'] as String? ?? '';
      final lastName = response['last_name'] as String? ?? '';
      final fullName = middleName.isNotEmpty
          ? '$firstName $middleName $lastName'
          : '$firstName $lastName';

      // Map to AccountStatusModel
      final accountStatus = AccountStatusModel(
        userId: response['id'] as String,
        status: _parseKycStatus(response['status'] as String?),
        submittedAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'] as String)
            : DateTime.now(),
        reviewedAt: response['updated_at'] != null
            ? DateTime.parse(response['updated_at'] as String)
            : null,
        reviewNotes: response['rejection_reason'] as String?,
        userEmail: response['email'] as String,
        userName: fullName.trim(),
      );

      print('[GuestDataSource] Successfully mapped to AccountStatusModel');
      return accountStatus;
    } on PostgrestException catch (e) {
      print('[GuestDataSource] PostgrestException: ${e.message}');
      print('[GuestDataSource] Error details: ${e.details}');
      print('[GuestDataSource] Error hint: ${e.hint}');
      throw Exception('Failed to check account status: ${e.message}');
    } catch (e) {
      print('[GuestDataSource] Unexpected error: $e');
      throw Exception('Failed to check account status: $e');
    }
  }

  /// Parse KYC status from database string
  AccountStatus _parseKycStatus(String? status) {
    if (status == null) return AccountStatus.pending;

    switch (status.toLowerCase()) {
      case 'pending':
        return AccountStatus.pending;
      case 'under_review':
        return AccountStatus.underReview;
      case 'approved':
        return AccountStatus.approved;
      case 'rejected':
        return AccountStatus.rejected;
      case 'suspended':
        return AccountStatus.suspended;
      default:
        return AccountStatus.pending;
    }
  }

  /// Get limited auction listings for guest browse
  /// Returns auctions without sensitive bidder information
  Future<List<Map<String, dynamic>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      print('[GuestDataSource] Fetching guest auctions from database...');

      // Query auctions with limited information
      // Hide bidder details, bid amounts, Q&A section
      final response = await _supabase
          .from('auctions')
          .select(
            'id, car_image_url, year, make, model, status, start_time, end_time, watchers_count, bidders_count',
          )
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      print('[GuestDataSource] Retrieved ${response.length} auctions from database');

      // Transform to match guest UI expectations
      final auctions = (response as List).map((auction) {
        return {
          'id': auction['id'],
          'title': '${auction['year']} ${auction['make']} ${auction['model']}',
          'description': 'Active auction for ${auction['make']} ${auction['model']}',
          'category': auction['make'], // Use make as category
          'image_url': auction['car_image_url'],
          'status': auction['status'],
          'start_date': auction['start_time'],
          'end_date': auction['end_time'],
        };
      }).toList();

      return auctions;
    } on PostgrestException catch (e) {
      print('[GuestDataSource] PostgrestException: ${e.message}');
      throw Exception('Failed to fetch auctions: ${e.message}');
    } catch (e) {
      print('[GuestDataSource] Unexpected error: $e');
      throw Exception('Failed to fetch auctions: $e');
    }
  }
}
