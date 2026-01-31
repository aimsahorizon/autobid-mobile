import 'package:flutter/foundation.dart';
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
      final usersResponse = await _supabase.from('users').select('id');
      final usersCount = (usersResponse as List).length;

      // Get total listings count
      final totalResponse = await _supabase.from('auctions').select('id');
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
      // First get the pending_approval status ID
      final pendingStatusId = await _getStatusId('pending_approval');

      // Query with status_id directly instead of JOIN filter
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, is_primary),
            users(full_name, email)
          ''')
          .eq('status_id', pendingStatusId)
          .order('created_at', ascending: true);

      debugPrint(
        'DEBUG: Pending listings response: ${(response as List).length} items',
      );
      if ((response as List).isNotEmpty) {
        debugPrint(
          'DEBUG: First item keys: ${(response[0] as Map).keys.toList()}',
        );
      }

      return (response as List)
          .map((json) => _parseAdminListing(json))
          .toList();
    } catch (e) {
      debugPrint('DEBUG: Failed to fetch pending listings: $e');
      throw Exception('Failed to fetch pending listings: $e');
    }
  }

  /// Get all listings by status
  Future<List<AdminListingEntity>> getListingsByStatus(String status) async {
    try {
      debugPrint('[ADMIN] ===== START FETCH =====');
      debugPrint('[ADMIN] Fetching listings with status: $status');
      debugPrint('[ADMIN] Current user: ${_supabase.auth.currentUser?.id}');

      // Handle 'all' status differently - no status filter
      if (status == 'all') {
        final response = await _supabase
            .from('auctions')
            .select('''
              *,
              auction_statuses(status_name),
              auction_vehicles(*),
              auction_photos(photo_url, is_primary),
              users(full_name, email)
            ''')
            .order('created_at', ascending: false)
            .limit(100);

        debugPrint(
          '[ADMIN] Fetched ${(response as List).length} listings (all statuses)',
        );
        if ((response as List).isNotEmpty) {
          debugPrint('[ADMIN] Sample data: ${(response as List).first}');
        }
        return (response as List)
            .map((json) => _parseAdminListing(json))
            .toList();
      }

      // For specific status, filter by status_id
      debugPrint('[ADMIN] Getting status ID for: $status');
      final statusId = await _getStatusId(status);
      debugPrint('[ADMIN] Status ID: $statusId');

      debugPrint('[ADMIN] Executing query...');
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, is_primary),
            users(full_name, email)
          ''')
          .eq('status_id', statusId)
          .order('created_at', ascending: false)
          .limit(100);

      debugPrint('[ADMIN] Raw response type: ${response.runtimeType}');
      debugPrint(
        '[ADMIN] Fetched ${(response as List).length} listings with status: $status',
      );

      if ((response as List).isNotEmpty) {
        debugPrint('[ADMIN] First item: ${(response as List).first}');
      }

      debugPrint('[ADMIN] Parsing ${(response as List).length} items...');
      final parsed = (response as List)
          .map((json) => _parseAdminListing(json))
          .toList();
      debugPrint('[ADMIN] Successfully parsed ${parsed.length} listings');
      debugPrint('[ADMIN] ===== END FETCH =====');
      return parsed;
    } catch (e) {
      debugPrint('[ADMIN] Error fetching listings: $e');
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Approve a listing (move to approved; seller schedules later)
  Future<void> approveListing(String auctionId, {String? notes}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get admin_users.id for the current user
      final adminUserResponse = await _supabase
          .from('admin_users')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final adminUserId = adminUserResponse['id'] as String;
      // Approval should keep listing in 'approved' status; seller will schedule/go live later
      final statusId = await _getStatusId('scheduled');

      await _supabase
          .from('auctions')
          .update({
            'status_id': statusId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': adminUserId,
            'review_notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);

      debugPrint(
        '[ADMIN] Approved listing $auctionId -> status: approved by admin_user $adminUserId (user: $currentUserId)',
      );
    } catch (e) {
      throw Exception('Failed to approve listing: $e');
    }
  }

  /// Reject a listing (change status to cancelled)
  Future<void> rejectListing(String auctionId, String reason) async {
    try {
      final cancelledStatusId = await _getStatusId('cancelled');
      final currentUserId = _supabase.auth.currentUser?.id;

      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get admin_users.id for the current user
      final adminUserResponse = await _supabase
          .from('admin_users')
          .select('id')
          .eq('user_id', currentUserId)
          .single();

      final adminUserId = adminUserResponse['id'] as String;

      await _supabase
          .from('auctions')
          .update({
            'status_id': cancelledStatusId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': adminUserId,
            'review_notes': reason,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);

      debugPrint(
        '[ADMIN] Rejected listing $auctionId by admin_user $adminUserId (user: $currentUserId): $reason',
      );
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

  /// Get all users
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Helper: Parse admin listing from JSON
  AdminListingEntity _parseAdminListing(Map<String, dynamic> json) {
    try {
      // Extract user data - handle both single object and array formats
      final userData = json['users'];
      String sellerName = 'Unknown';
      String sellerEmail = '';

      if (userData is Map<String, dynamic>) {
        sellerName = userData['full_name'] as String? ?? 'Unknown';
        sellerEmail = userData['email'] as String? ?? '';
      } else if (userData is List && userData.isNotEmpty) {
        final user = userData[0] as Map<String, dynamic>;
        sellerName = user['full_name'] as String? ?? 'Unknown';
        sellerEmail = user['email'] as String? ?? '';
      }

      // Extract vehicle data - one-to-one relationship with auction_id
      final vehicleData = json['auction_vehicles'];
      Map<String, dynamic>? vehicle;

      if (vehicleData is Map<String, dynamic>) {
        vehicle = vehicleData;
      } else if (vehicleData is List && vehicleData.isNotEmpty) {
        vehicle = vehicleData[0] as Map<String, dynamic>;
      }

      // Extract photo data - one-to-many relationship
      final photosData = json['auction_photos'];
      String? coverPhoto;

      if (photosData is List && photosData.isNotEmpty) {
        try {
          final primaryPhoto = photosData.firstWhere(
            (p) => p['is_primary'] == true,
            orElse: () => photosData[0],
          );
          coverPhoto = primaryPhoto['photo_url'] as String?;
        } catch (e) {
          debugPrint('[ADMIN] Error extracting photo: $e');
        }
      }

      // Get status name - many-to-one relationship
      final statusData = json['auction_statuses'];
      String status = 'draft';

      if (statusData is Map<String, dynamic>) {
        status = statusData['status_name'] as String? ?? 'draft';
      } else if (statusData is List && statusData.isNotEmpty) {
        final statusObj = statusData[0] as Map<String, dynamic>;
        status = statusObj['status_name'] as String? ?? 'draft';
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
    } catch (e, stackTrace) {
      debugPrint('[ADMIN] ERROR parsing listing: $e');
      debugPrint('[ADMIN] Stack trace: $stackTrace');
      debugPrint('[ADMIN] JSON keys: ${json.keys.toList()}');
      rethrow;
    }
  }
}
