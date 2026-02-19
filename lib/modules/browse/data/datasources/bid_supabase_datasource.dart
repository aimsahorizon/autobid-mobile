import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for bid operations
/// Handles placing bids, getting bid history, and managing deposits
class BidSupabaseDataSource {
  final SupabaseClient _supabase;

  BidSupabaseDataSource(this._supabase);

  /// Place a bid on an auction/listing
  /// Uses server-side RPC 'place_bid' to ensure concurrency control and auto-bids
  Future<void> placeBid({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  }) async {
    try {
      // Call RPC — auto-bid settings are saved separately via saveAutoBidSettings()
      final response = await _supabase.rpc(
        'place_bid',
        params: {
          'p_auction_id': auctionId,
          'p_bidder_id': bidderId,
          'p_amount': amount,
          'p_is_auto_bid': isAutoBid,
        },
      );

      // Parse response
      final result = response as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to place bid');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to place bid: ${e.message}');
    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  /// Save or update auto-bid settings via server-side RPC
  /// This persists the user's max bid and increment on the server
  Future<void> saveAutoBidSettings({
    required String auctionId,
    required String userId,
    required double maxBidAmount,
    double? bidIncrement,
    bool isActive = true,
  }) async {
    try {
      final response = await _supabase.rpc(
        'upsert_auto_bid_settings',
        params: {
          'p_auction_id': auctionId,
          'p_user_id': userId,
          'p_max_bid_amount': maxBidAmount,
          'p_bid_increment': bidIncrement,
          'p_is_active': isActive,
        },
      );

      final result = response as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to save auto-bid settings');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to save auto-bid settings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save auto-bid settings: $e');
    }
  }

  /// Get auto-bid settings for a user on a specific auction
  Future<Map<String, dynamic>?> getAutoBidSettings({
    required String auctionId,
    required String userId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_auto_bid_settings',
        params: {'p_auction_id': auctionId, 'p_user_id': userId},
      );

      final result = response as Map<String, dynamic>;
      if (result['exists'] == true) {
        return result;
      }
      return null;
    } on PostgrestException catch (e) {
      debugPrint('Failed to get auto-bid settings: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Failed to get auto-bid settings: $e');
      return null;
    }
  }

  /// Deactivate auto-bid settings for a user on a specific auction
  Future<void> deactivateAutoBid({
    required String auctionId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from('auto_bid_settings')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('auction_id', auctionId)
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to deactivate auto-bid: ${e.message}');
    } catch (e) {
      throw Exception('Failed to deactivate auto-bid: $e');
    }
  }

  /// Stream notification updates for a user (for outbid alerts)
  Stream<List<Map<String, dynamic>>> streamNotifications(String userId) {
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(20);
  }

  /// Extend auction end time by 5 minutes on every bid
  /// Deprecated: Logic moved to server-side 'place_bid' function
  Future<void> _maybeApplySnipeGuard(String auctionId) async {
    // No-op: handled by server
  }

  /// Get bid history for a listing/auction
  /// Joins with users table to get bidder info (LEFT JOIN to handle missing users)
  Future<List<Map<String, dynamic>>> getBidHistory(String auctionId) async {
    try {
      debugPrint(
        'DEBUG [BidDataSource]: Fetching bid history for auction_id: $auctionId',
      );

      // Query bids with users join to get bidder username/display_name
      final response = await _supabase
          .from('bids')
          .select(
            'id, bid_amount, is_auto_bid, created_at, bidder_id, bidder:users!bidder_id(username, display_name)',
          )
          .eq('auction_id', auctionId)
          .order('bid_amount', ascending: false);

      debugPrint(
        'DEBUG [BidDataSource]: Query response type: ${response.runtimeType}',
      );
      debugPrint('DEBUG [BidDataSource]: Response data: $response');

      final result = List<Map<String, dynamic>>.from(response);
      debugPrint('DEBUG [BidDataSource]: Returning ${result.length} bids');

      return result;
    } on PostgrestException catch (e) {
      debugPrint('ERROR [BidDataSource]: PostgrestException - ${e.message}');
      debugPrint(
        'ERROR [BidDataSource]: Code: ${e.code}, Details: ${e.details}',
      );
      throw Exception('Failed to get bid history: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('ERROR [BidDataSource]: Exception - $e');
      debugPrint('ERROR [BidDataSource]: Stack trace: $stackTrace');
      throw Exception('Failed to get bid history: $e');
    }
  }

  /// Get user's active bids (listings they're currently bidding on)
  /// Uses PostgreSQL function to get latest bid per listing
  Future<List<Map<String, dynamic>>> getUserActiveBids(String userId) async {
    try {
      final response = await _supabase.rpc(
        'get_user_active_bids',
        params: {'user_id': userId},
      );

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user active bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user active bids: $e');
    }
  }

  /// Check if user has placed a bid on a specific listing
  /// Returns true if user has at least one bid on the listing
  Future<bool> hasUserBid(String userId, String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('id')
          .eq('auction_id', auctionId)
          .eq('bidder_id', userId)
          .limit(1);

      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check user bid: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check user bid: $e');
    }
  }

  /// Get highest bid amount for a listing
  /// Returns null if no bids exist
  Future<double?> getHighestBid(String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('bid_amount')
          .eq('auction_id', auctionId)
          .order('bid_amount', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return (response['bid_amount'] as num).toDouble();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get highest bid: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get highest bid: $e');
    }
  }

  /// Check if user has deposited for auction
  /// Queries deposits table for confirmed deposit
  Future<bool> hasDeposit(String userId, String vehicleId) async {
    try {
      final response = await _supabase
          .from('deposits')
          .select('id')
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .eq('status', 'confirmed')
          .maybeSingle();

      return response != null;
    } on PostgrestException catch (e) {
      throw Exception('Failed to check deposit: ${e.message}');
    } catch (e) {
      throw Exception('Failed to check deposit: $e');
    }
  }

  /// Submit deposit for auction
  /// Inserts into deposits table with pending status
  Future<void> submitDeposit({
    required String userId,
    required String vehicleId,
    required double amount,
    String? paymentReference,
  }) async {
    try {
      await _supabase.from('deposits').insert({
        'user_id': userId,
        'vehicle_id': vehicleId,
        'amount': amount,
        'status': 'pending',
        'payment_reference': paymentReference,
      });
    } on PostgrestException catch (e) {
      // Handle duplicate deposit error
      if (e.code == '23505') {
        throw Exception('Deposit already submitted for this auction');
      }
      throw Exception('Failed to submit deposit: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit deposit: $e');
    }
  }

  /// Get user's deposit for an auction
  /// Returns deposit details or null if not found
  Future<Map<String, dynamic>?> getDeposit(
    String userId,
    String vehicleId,
  ) async {
    try {
      final response = await _supabase
          .from('deposits')
          .select()
          .eq('user_id', userId)
          .eq('vehicle_id', vehicleId)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get deposit: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get deposit: $e');
    }
  }

  /// Stream bid updates for a specific auction
  /// Listens to changes in the 'bids' table
  Stream<List<Map<String, dynamic>>> streamBidUpdates(String auctionId) {
    return _supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false);
  }
}
