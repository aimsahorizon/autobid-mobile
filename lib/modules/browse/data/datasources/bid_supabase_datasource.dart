import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for bid operations
/// Handles placing bids, getting bid history, and managing deposits
class BidSupabaseDataSource {
  final SupabaseClient _supabase;

  BidSupabaseDataSource(this._supabase);

  /// Place a bid on an auction/listing
  /// Inserts new bid into bids table
  /// Automatically updates listing's current_bid and total_bids via trigger
  Future<void> placeBid({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  }) async {
    try {
      // Get status ID for 'active' bid status
      final statusResponse = await _supabase
          .from('bid_statuses')
          .select('id')
          .eq('status_name', 'active')
          .single();

      final statusId = statusResponse['id'] as String;

      // Insert new bid
      await _supabase.from('bids').insert({
        'auction_id': auctionId,
        'bidder_id': bidderId,
        'status_id': statusId,
        'bid_amount': amount,
        'is_auto_bid': isAutoBid,
      });

      // If auto-bid is enabled, create/update auto_bid_settings
      if (isAutoBid && maxAutoBid != null) {
        await _supabase.from('auto_bid_settings').upsert({
          'auction_id': auctionId,
          'user_id': bidderId,
          'max_bid_amount': maxAutoBid,
          'is_active': true,
        });
      }

      await _maybeApplySnipeGuard(auctionId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to place bid: ${e.message}');
    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  /// Extend auction end time by 5 minutes on every bid
  Future<void> _maybeApplySnipeGuard(String auctionId) async {
    try {
      print('[SnipeGuard] 🔍 Adding 5 minutes to auction $auctionId');

      final auction = await _supabase
          .from('auctions')
          .select('end_time')
          .eq('id', auctionId)
          .maybeSingle();

      if (auction == null) {
        print('[SnipeGuard] ❌ Auction not found');
        return;
      }

      final endTimeRaw = auction['end_time'] as String?;
      if (endTimeRaw == null) {
        print('[SnipeGuard] ❌ No end_time found');
        return;
      }

      final endTime = DateTime.parse(endTimeRaw).toUtc();
      final now = DateTime.now().toUtc();
      final newEndTime = endTime.add(const Duration(minutes: 5));

      print('[SnipeGuard] Old end: $endTime');
      print('[SnipeGuard] New end: $newEndTime (+ 5 minutes)');

      await _supabase
          .from('auctions')
          .update({
            'end_time': newEndTime.toIso8601String(),
            'snipe_guard_last_applied_at': now.toIso8601String(),
          })
          .eq('id', auctionId);

      print('[SnipeGuard] ✅ Added 5 minutes successfully!');
    } catch (e) {
      // Non-fatal; bid already placed. Log and continue.
      print('[SnipeGuard] ❌ Failed to add time: $e');
    }
  }

  /// Get bid history for a listing/auction
  /// Joins with users table to get bidder info (LEFT JOIN to handle missing users)
  Future<List<Map<String, dynamic>>> getBidHistory(String auctionId) async {
    try {
      print(
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

      print(
        'DEBUG [BidDataSource]: Query response type: ${response.runtimeType}',
      );
      print('DEBUG [BidDataSource]: Response data: $response');

      final result = List<Map<String, dynamic>>.from(response);
      print('DEBUG [BidDataSource]: Returning ${result.length} bids');

      return result;
    } on PostgrestException catch (e) {
      print('ERROR [BidDataSource]: PostgrestException - ${e.message}');
      print('ERROR [BidDataSource]: Code: ${e.code}, Details: ${e.details}');
      throw Exception('Failed to get bid history: ${e.message}');
    } catch (e, stackTrace) {
      print('ERROR [BidDataSource]: Exception - $e');
      print('ERROR [BidDataSource]: Stack trace: $stackTrace');
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
