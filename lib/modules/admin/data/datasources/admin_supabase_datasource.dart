import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/admin_listing_entity.dart';

/// Admin datasource for managing listings and users
class AdminSupabaseDataSource {
  final SupabaseClient _supabase;

  AdminSupabaseDataSource(this._supabase);

  /// Get admin statistics
  Future<AdminStatsEntity> getAdminStats() async {
    try {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Get pending listings count
      final pendingResponse = await _supabase
          .from('auctions')
          .select('id')
          .eq('status_id', await _getStatusId('pending_approval'));
      final pendingCount = (pendingResponse as List).length;

      // Get active listings count
      final activeResponse = await _supabase
          .from('auctions')
          .select('id')
          .eq('status_id', await _getStatusId('live'));
      final activeCount = (activeResponse as List).length;

      // Get total users count
      final usersResponse = await _supabase
          .from('users')
          .select('id');
      final usersCount = (usersResponse as List).length;

      // Get total listings count
      final totalResponse = await _supabase
          .from('auctions')
          .select('id');
      final totalCount = (totalResponse as List).length;

      // Get today's submissions
      final todayResponse = await _supabase
          .from('auctions')
          .select('id')
          .gte('created_at', todayStart.toIso8601String());
      final todayCount = (todayResponse as List).length;

      return AdminStatsEntity(
        pendingListings: pendingCount,
        activeListings: activeCount,
        totalUsers: usersCount,
        totalListings: totalCount,
        todaySubmissions: todayCount,
      );
    } catch (e) {
      throw Exception('Failed to fetch admin stats: $e');
    }
  }

  /// Get all pending listings for review
  Future<List<AdminListingEntity>> getPendingListings() async {
    try {
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses!inner(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, is_primary),
            users!auctions_seller_id_fkey(full_name, email)
          ''')
          .eq('auction_statuses.status_name', 'pending_approval')
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => _parseAdminListing(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending listings: $e');
    }
  }

  /// Get all listings by status
  Future<List<AdminListingEntity>> getListingsByStatus(String status) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses!inner(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, is_primary),
            users!auctions_seller_id_fkey(full_name, email)
          ''')
          .eq('auction_statuses.status_name', status)
          .order('created_at', ascending: false)
          .limit(100);

      return (response as List)
          .map((json) => _parseAdminListing(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Approve a listing (change status to scheduled)
  Future<void> approveListing(String auctionId, {String? notes}) async {
    try {
      final scheduledStatusId = await _getStatusId('scheduled');

      await _supabase
          .from('auctions')
          .update({
            'status_id': scheduledStatusId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);

      // TODO: Add admin action log
    } catch (e) {
      throw Exception('Failed to approve listing: $e');
    }
  }

  /// Reject a listing (change status to cancelled)
  Future<void> rejectListing(String auctionId, String reason) async {
    try {
      final cancelledStatusId = await _getStatusId('cancelled');

      await _supabase
          .from('auctions')
          .update({
            'status_id': cancelledStatusId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);

      // TODO: Add admin action log with reason
    } catch (e) {
      throw Exception('Failed to reject listing: $e');
    }
  }

  /// Change listing status
  Future<void> changeListingStatus(String auctionId, String newStatus) async {
    try {
      final statusId = await _getStatusId(newStatus);

      await _supabase
          .from('auctions')
          .update({
            'status_id': statusId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);
    } catch (e) {
      throw Exception('Failed to change listing status: $e');
    }
  }

  /// Helper: Get status ID from status name
  Future<String> _getStatusId(String statusName) async {
    final response = await _supabase
        .from('auction_statuses')
        .select('id')
        .eq('status_name', statusName)
        .single();

    return response['id'] as String;
  }

  /// Helper: Parse admin listing from JSON
  AdminListingEntity _parseAdminListing(Map<String, dynamic> json) {
    // Extract user data
    final userData = json['users'] as Map<String, dynamic>?;
    final sellerName = userData?['full_name'] as String? ?? 'Unknown';
    final sellerEmail = userData?['email'] as String? ?? '';

    // Extract vehicle data
    final vehicleData = json['auction_vehicles'];
    Map<String, dynamic>? vehicle;
    if (vehicleData is List && vehicleData.isNotEmpty) {
      vehicle = vehicleData[0];
    } else if (vehicleData is Map<String, dynamic>) {
      vehicle = vehicleData;
    }

    // Extract photo data
    final photosData = json['auction_photos'];
    String? coverPhoto;
    if (photosData is List && photosData.isNotEmpty) {
      // Find primary photo or use first photo
      final primaryPhoto = photosData.firstWhere(
        (p) => p['is_primary'] == true,
        orElse: () => photosData[0],
      );
      coverPhoto = primaryPhoto['photo_url'] as String?;
    }

    // Get status name
    final statusData = json['auction_statuses'];
    String status = 'draft';
    if (statusData is Map<String, dynamic>) {
      status = statusData['status_name'] as String? ?? 'draft';
    }

    return AdminListingEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      sellerId: json['seller_id'] as String,
      sellerName: sellerName,
      sellerEmail: sellerEmail,
      status: status,
      startingPrice: (json['starting_price'] as num?)?.toDouble() ?? 0.0,
      reservePrice: (json['reserve_price'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      submittedAt: json['submitted_at'] != null
          ? DateTime.parse(json['submitted_at'] as String)
          : null,
      coverPhotoUrl: coverPhoto,
      year: vehicle?['year'] as int? ?? 0,
      brand: vehicle?['brand'] as String? ?? 'Unknown',
      model: vehicle?['model'] as String? ?? 'Unknown',
      variant: vehicle?['variant'] as String?,
      mileage: vehicle?['mileage'] as int? ?? 0,
      condition: vehicle?['condition'] as String? ?? 'used',
      reviewNotes: json['review_notes'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
    );
  }
}
