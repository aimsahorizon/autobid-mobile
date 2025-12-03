import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_bid_model.dart';
import '../../domain/entities/user_bid_entity.dart';
import '../../presentation/controllers/bids_controller.dart';

/// Supabase datasource for user's bid history
/// Fetches user's active, won, and lost bids from database
class UserBidsSupabaseDataSource implements IUserBidsDataSource {
  final SupabaseClient _supabase;

  UserBidsSupabaseDataSource(this._supabase);

  /// Fetches all user bids categorized by status
  /// Uses get_user_active_bids function and joins with auctions table
  @override
  Future<Map<String, List<UserBidEntity>>> getUserBids([String? userId]) async {
    if (userId == null) {
      return {'active': [], 'won': [], 'lost': []};
    }
    try {
      // Get user's active bids using PostgreSQL function
      final activeBidsResponse = await _supabase.rpc(
        'get_user_active_bids',
        params: {'user_id': userId},
      );

      // Convert to list and join with auction data
      final activeBidsData = List<Map<String, dynamic>>.from(activeBidsResponse);

      // Fetch full listing details for each bid
      final List<UserBidEntity> activeBids = [];
      final List<UserBidEntity> wonBids = [];
      final List<UserBidEntity> lostBids = [];

      for (final bidData in activeBidsData) {
        final listingId = bidData['listing_id'] as String;

        // Get full listing details
        final listingResponse = await _supabase
            .from('listings')
            .select('*')
            .eq('id', listingId)
            .single();

        // Combine bid and listing data
        final combinedData = {
          ...bidData,
          'listings': listingResponse,
        };

        // Create model from combined data
        final bidModel = UserBidModel.fromJson(combinedData);

        // Categorize by status
        switch (bidModel.status) {
          case UserBidStatus.active:
            activeBids.add(bidModel);
            break;
          case UserBidStatus.won:
            wonBids.add(bidModel);
            break;
          case UserBidStatus.lost:
            lostBids.add(bidModel);
            break;
        }
      }

      return {
        'active': activeBids,
        'won': wonBids,
        'lost': lostBids,
      };
    } on PostgrestException catch (e) {
      throw Exception('Failed to get user bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get user bids: $e');
    }
  }

  /// Fetches only active bids for the user
  /// Active = auction still ongoing and user has placed bids
  Future<List<UserBidEntity>> getActiveBids(String userId) async {
    final allBids = await getUserBids(userId);
    return allBids['active'] ?? [];
  }

  /// Fetches only won bids for the user
  /// Won = auction ended and user was highest bidder
  Future<List<UserBidEntity>> getWonBids(String userId) async {
    final allBids = await getUserBids(userId);
    return allBids['won'] ?? [];
  }

  /// Fetches only lost bids for the user
  /// Lost = auction ended and user was outbid
  Future<List<UserBidEntity>> getLostBids(String userId) async {
    final allBids = await getUserBids(userId);
    return allBids['lost'] ?? [];
  }
}
