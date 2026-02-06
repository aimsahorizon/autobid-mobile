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
  /// Check account status by email or username (full_name)
  /// Returns status if user exists
  Future<AccountStatusModel?> checkAccountStatus(String identifier) async {
    try {
      debugPrint('[GuestDataSource] Checking account status for: $identifier');

      // Join with kyc_documents and kyc_statuses to get verification status
      var query = _supabase.from('users').select('''
            id, 
            email, 
            full_name, 
            created_at, 
            updated_at,
            kyc_documents(
              rejection_reason,
              updated_at,
              kyc_statuses(status_name)
            )
          ''');

      if (identifier.contains('@')) {
        query = query.eq('email', identifier);
      } else {
        query = query.ilike('full_name', '%$identifier%');
      }

      final response = await query.maybeSingle();

      debugPrint('[GuestDataSource] Response: $response');

      if (response == null) {
        debugPrint('[GuestDataSource] No user found with identifier: $identifier');
        return null;
      }

      // Extract KYC info from joined table
      final kycDocs = response['kyc_documents'] as List?;
      final kycDoc = (kycDocs != null && kycDocs.isNotEmpty) ? kycDocs.first : null;
      
      String? statusStr;
      if (kycDoc != null && kycDoc['kyc_statuses'] != null) {
        statusStr = kycDoc['kyc_statuses']['status_name'] as String?;
      }

      // Map to AccountStatusModel
      final accountStatus = AccountStatusModel(
        userId: response['id'] as String,
        status: _parseKycStatus(statusStr),
        submittedAt: response['created_at'] != null
            ? DateTime.parse(response['created_at'] as String)
            : DateTime.now(),
        reviewedAt: kycDoc != null && kycDoc['updated_at'] != null
            ? DateTime.parse(kycDoc['updated_at'] as String)
            : null,
        reviewNotes: kycDoc != null ? kycDoc['rejection_reason'] as String? : null,
        userEmail: response['email'] as String,
        userName: (response['full_name'] as String? ?? '').trim(),
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

      // Query auctions table directly to get real vehicle data
      // Filter for live auctions that haven't ended
      final response = await _supabase
          .from('auctions')
          .select('''
            id,
            title,
            starting_price,
            current_price,
            start_time,
            end_time,
            total_bids,
            auction_statuses!inner(status_name),
            auction_vehicles!inner(
              year,
              brand,
              model,
              mileage,
              province,
              city_municipality
            ),
            auction_photos(
              photo_url,
              is_primary,
              display_order
            )
          ''')
          .eq('auction_statuses.status_name', 'live')
          .gt('end_time', DateTime.now().toIso8601String())
          .order('end_time', ascending: true)
          .range(offset, offset + limit - 1);

      debugPrint(
        '[GuestDataSource] Retrieved ${response.length} live auctions',
      );

      // Transform to match guest UI expectations
      final auctions = (response as List).map((auction) {
        // Extract vehicle info
        final vehicle = auction['auction_vehicles'] as Map<String, dynamic>? ?? {};
        final make = vehicle['brand'] as String? ?? 'Unknown';
        final model = vehicle['model'] as String? ?? 'Vehicle';
        final year = vehicle['year'] as int? ?? 0;
        final mileage = vehicle['mileage'] as int?;
        final city = vehicle['city_municipality'] as String?;
        final province = vehicle['province'] as String?;
        
        final title = auction['title'] as String? ?? '$year $make $model';
        
        // Extract primary photo
        String? imageUrl;
        final photos = auction['auction_photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          // Sort by is_primary then display_order
          photos.sort((a, b) {
            final aPrimary = (a['is_primary'] as bool?) ?? false;
            final bPrimary = (b['is_primary'] as bool?) ?? false;
            if (aPrimary && !bPrimary) return -1;
            if (!aPrimary && bPrimary) return 1;
            return ((a['display_order'] as int?) ?? 0)
                .compareTo((b['display_order'] as int?) ?? 0);
          });
          imageUrl = photos.first['photo_url'] as String?;
        }

        return {
          'id': auction['id'],
          'title': title,
          'description': 'Active auction for $make $model',
          'category': make, // Used as subtitle/brand
          'image_url': imageUrl,
          'status': 'live',
          'start_date': auction['start_time'],
          'end_date': auction['end_time'],
          'current_price': auction['current_price'],
          'starting_price': auction['starting_price'],
          'total_bids': auction['total_bids'],
          'mileage': mileage,
          'location': city != null && province != null ? '$city, $province' : province ?? city,
          'vehicle_year': year,
          'vehicle_make': make,
          'vehicle_model': model,
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
