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
      // Insert new bid - trigger will update listing automatically
      await _supabase.from('bids').insert({
        'listing_id': auctionId, // listings table
        'bidder_id': bidderId,
        'amount': amount,
        'is_auto_bid': isAutoBid,
        'max_auto_bid': maxAutoBid,
        'auto_bid_increment': autoBidIncrement,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to place bid: ${e.message}');
    } catch (e) {
      throw Exception('Failed to place bid: $e');
    }
  }

  /// Get bid history for a listing/auction
  /// Joins with users table to get bidder info
  Future<List<Map<String, dynamic>>> getBidHistory(String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('''
            id,
            amount,
            is_auto_bid,
            created_at,
            bidder_id,
            users!inner(username, avatar_url)
          ''')
          .eq('listing_id', auctionId)
          .order('amount', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get bid history: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get bid history: $e');
    }
  }

  /// Get user's active bids (listings they're currently bidding on)
  /// Uses PostgreSQL function to get latest bid per listing
  Future<List<Map<String, dynamic>>> getUserActiveBids(String userId) async {
    try {
      final response = await _supabase.rpc('get_user_active_bids', params: {
        'user_id': userId,
      });

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
          .eq('listing_id', auctionId)
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
          .select('amount')
          .eq('listing_id', auctionId)
          .order('amount', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return (response['amount'] as num).toDouble();
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
  Future<Map<String, dynamic>?> getDeposit(String userId, String vehicleId) async {
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
}
