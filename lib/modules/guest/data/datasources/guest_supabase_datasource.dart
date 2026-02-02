import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/account_status_entity.dart';
import '../models/account_status_model.dart';
import 'guest_remote_datasource.dart';

/// Data source for guest mode operations
/// Handles account status checking from Supabase
class GuestSupabaseDataSource implements GuestRemoteDataSource {
  final SupabaseClient _supabase;

  GuestSupabaseDataSource(this._supabase);

  @override
  /// Check account status by email
  /// Returns status if user exists and has submitted KYC
  Future<AccountStatusModel?> checkAccountStatus(String email) async {
    try {
      debugPrint('[GuestDataSource] Checking account status for email: $email');

      // Query users table (KYC users are stored here)
      final response = await _supabase
          .from('users')
          .select(
            'id, email, first_name, middle_name, last_name, status, created_at, updated_at, rejection_reason',
          )
          .eq('email', email)
          .maybeSingle();

      debugPrint('[GuestDataSource] Response: $response');

      if (response == null) {
        debugPrint('[GuestDataSource] No user found with email: $email');
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

      debugPrint('[GuestDataSource] Successfully mapped to AccountStatusModel');
      return accountStatus;
    } on PostgrestException catch (e) {
      debugPrint('[GuestDataSource] PostgrestException: ${e.message}');
      debugPrint('[GuestDataSource] Error details: ${e.details}');
      debugPrint('[GuestDataSource] Error hint: ${e.hint}');
      throw Exception('Failed to check account status: ${e.message}');
    } catch (e) {
      debugPrint('[GuestDataSource] Unexpected error: $e');
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

  @override
  /// Get limited auction listings for guest browse
  /// Returns auctions without sensitive bidder information
  Future<List<Map<String, dynamic>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('[GuestDataSource] Fetching guest auctions from database...');

      // Use auction_browse_listings view which filters for live auctions
      // This view is accessible to anonymous users and already has proper RLS
      final response = await _supabase
          .from('auction_browse_listings')
          .select('''
            id,
            title,
            primary_image_url,
            starting_price,
            current_price,
            start_time,
            end_time,
            total_bids,
            vehicle_year,
            vehicle_make,
            vehicle_model
          ''')
          .order('end_time', ascending: true)
          .limit(limit);

      debugPrint(
        '[GuestDataSource] Retrieved ${response.length} live auctions from auction_browse_listings view',
      );

      // Transform to match guest UI expectations
      final auctions = (response as List).map((auction) {
        final make = auction['vehicle_make'] as String? ?? 'Unknown';
        final model = auction['vehicle_model'] as String? ?? 'Vehicle';
        final year = auction['vehicle_year'] as int? ?? 0;

        final title = auction['title'] as String? ?? '$year $make $model';

        return {
          'id': auction['id'],
          'title': title,
          'description': 'Active auction for $make $model',
          'category': make,
          'image_url': auction['primary_image_url'],
          'status': 'live',
          'start_date': auction['start_time'],
          'end_date': auction['end_time'],
          'current_price': auction['current_price'],
          'starting_price': auction['starting_price'],
          'total_bids': auction['total_bids'],
          'current_price': auction['current_price'],
          'starting_price': auction['starting_price'],
          'total_bids': auction['total_bids'],
        };
      }).toList();

      debugPrint(
        '[GuestDataSource] Mapped ${auctions.length} auctions for guest display',
      );

      return auctions;
    } on PostgrestException catch (e) {
      debugPrint('[GuestDataSource] PostgrestException: ${e.message}');
      throw Exception('Failed to fetch auctions: ${e.message}');
    } catch (e) {
      debugPrint('[GuestDataSource] Unexpected error: $e');
      throw Exception('Failed to fetch auctions: $e');
    }
  }
}
