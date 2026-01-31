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

      // Query auctions with joined data
      // Filter for 'live' auctions (guests should see live auctions)
      final response = await _supabase
          .from('auctions')
          .select('''
            id,
            start_time,
            end_time,
            auction_statuses!inner(status_name),
            auction_vehicles(year, make, model),
            auction_photos(photo_url, is_primary)
          ''')
          .eq('auction_statuses.status_name', 'live')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint(
        '[GuestDataSource] Retrieved ${response.length} auctions from database',
      );

      // Transform to match guest UI expectations
      final auctions = (response as List).map((auction) {
        final vehicle = auction['auction_vehicles'] as Map<String, dynamic>? ?? {};
        final photos = auction['auction_photos'] as List<dynamic>? ?? [];
        
        // Find primary photo
        String? imageUrl;
        if (photos.isNotEmpty) {
          final primary = photos.firstWhere(
            (p) => p['is_primary'] == true,
            orElse: () => photos.first,
          );
          imageUrl = primary['photo_url'] as String?;
        }

        final make = vehicle['make'] as String? ?? 'Unknown';
        final model = vehicle['model'] as String? ?? 'Vehicle';
        final year = vehicle['year'] as int? ?? 0;

        return {
          'id': auction['id'],
          'title': '$year $make $model',
          'description': 'Active auction for $make $model',
          'category': make,
          'image_url': imageUrl,
          'status': 'live',
          'start_date': auction['start_time'],
          'end_date': auction['end_time'],
        };
      }).toList();

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
