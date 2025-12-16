import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_bid_model.dart';
import '../../domain/entities/user_bid_entity.dart';
import '../../presentation/controllers/bids_controller.dart';

/// Supabase datasource for user's bid history
/// Fetches user's active, won, lost, and cancelled bids from database
class UserBidsSupabaseDataSource implements IUserBidsDataSource {
  final SupabaseClient _supabase;

  UserBidsSupabaseDataSource(this._supabase);

  /// Fetches all user bids categorized by status
  /// Logic:
  /// - Active: auction not ended (end_time in future)
  /// - Won: auction ended, user is highest bidder and transaction active
  /// - Lost: auction ended, user not highest bidder
  /// - Cancelled: auction in deal_failed status, user was highest bidder
  @override
  Future<Map<String, List<UserBidEntity>>> getUserBids([String? userId]) async {
    if (userId == null) {
      print('[UserBidsSupabaseDataSource] getUserBids: userId is null');
      return {'active': [], 'won': [], 'lost': [], 'cancelled': []};
    }

    print(
      '[UserBidsSupabaseDataSource] getUserBids: fetching bids for userId=$userId',
    );

    final List<UserBidEntity> activeBids = [];
    final List<UserBidEntity> wonBids = [];
    final List<UserBidEntity> lostBids = [];
    final List<UserBidEntity> cancelledBids = [];

    try {
      // Get all bids by this user - fetch auction details separately
      final response = await _supabase
          .from('bids')
          .select('id, auction_id, bid_amount, created_at')
          .eq('bidder_id', userId);

      print(
        '[UserBidsSupabaseDataSource] Query response type: ${response.runtimeType}',
      );
      print('[UserBidsSupabaseDataSource] Query response: $response');

      final bidsList = response is List
          ? List<Map<String, dynamic>>.from(response)
          : <Map<String, dynamic>>[];

      print(
        '[UserBidsSupabaseDataSource] Parsed bidsList length: ${bidsList.length}',
      );

      if (bidsList.isEmpty) {
        print('[UserBidsSupabaseDataSource] No bids found for user');
        return {'active': [], 'won': [], 'lost': []};
      }

      // Group bids by auction_id to get max bid per auction
      final Map<String, List<Map<String, dynamic>>> bidsByAuctionId = {};
      for (final bid in bidsList) {
        final auctionId = bid['auction_id'] as String;
        bidsByAuctionId.putIfAbsent(auctionId, () => []).add(bid);
      }

      print(
        '[UserBidsSupabaseDataSource] Grouped bids by auctionId. Count: ${bidsByAuctionId.length}',
      );

      // Process each auction
      for (final auctionId in bidsByAuctionId.keys) {
        print('[UserBidsSupabaseDataSource] Processing auctionId: $auctionId');
        try {
          final bidsForThisAuction = bidsByAuctionId[auctionId]!;

          // Fetch auction directly by ID - try without any filters first
          Map<String, dynamic>? auction;
          try {
            final auctionResponse = await _supabase
                .from('auctions')
                .select('*')
                .eq('id', auctionId)
                .maybeSingle();

            print(
              '[UserBidsSupabaseDataSource]   Direct auction query result: $auctionResponse',
            );

            if (auctionResponse != null) {
              auction = auctionResponse as Map<String, dynamic>;
            }
          } catch (e) {
            print(
              '[UserBidsSupabaseDataSource]   Direct auction query error: $e',
            );
          }

          if (auction == null) {
            print(
              '[UserBidsSupabaseDataSource]   Auction $auctionId not accessible, skipping',
            );
            continue;
          }

          // Skip if the current user is the seller; prevents showing seller-owned
          // listings in the buyer tab when the auction enters transaction state.
          final sellerId = auction['seller_id'] as String?;
          if (sellerId != null && sellerId == userId) {
            print(
              '[UserBidsSupabaseDataSource]   Skipping auction $auctionId because user is seller',
            );
            continue;
          }

          // Fetch status separately
          String? statusName;
          try {
            final statusResponse = await _supabase
                .from('auction_statuses')
                .select('status_name')
                .eq('id', auction['status_id'])
                .single();
            statusName = statusResponse['status_name'] as String?;
          } catch (_) {
            statusName = null;
          }

          // Fetch vehicle separately
          String vehicleDisplay = 'Vehicle';
          int vehicleYear = 0;
          try {
            final vehicleResponse = await _supabase
                .from('auction_vehicles')
                .select('brand, model, year')
                .eq('auction_id', auctionId)
                .limit(1);
            if (vehicleResponse is List && vehicleResponse.isNotEmpty) {
              final v = vehicleResponse.first;
              final brand = v['brand'] as String? ?? '';
              final model = v['model'] as String? ?? '';
              vehicleYear = (v['year'] as num?)?.toInt() ?? 0;
              if (brand.isNotEmpty && model.isNotEmpty) {
                vehicleDisplay = '$brand $model';
              }
            }
          } catch (_) {
            // Use default values
          }

          // Fetch cover photo separately
          String? coverPhotoUrl;
          try {
            final photoResponse = await _supabase
                .from('auction_photos')
                .select('photo_url')
                .eq('auction_id', auctionId)
                .eq('is_primary', true)
                .limit(1);
            if (photoResponse is List && photoResponse.isNotEmpty) {
              coverPhotoUrl = photoResponse.first['photo_url'] as String?;
            }
          } catch (_) {
            coverPhotoUrl = null;
          }

          // Calculate user's max bid for this auction
          final userMaxBid = bidsForThisAuction
              .map((b) => (b['bid_amount'] as num).toDouble())
              .fold<double>(0, (prev, val) => val > prev ? val : prev);

          // Auction info
          final title = auction['title'] as String? ?? 'Unknown';
          final currentPrice =
              (auction['current_price'] as num?)?.toDouble() ?? 0;
          final startingPrice =
              (auction['starting_price'] as num?)?.toDouble() ?? 0;
          final endTimeStr = auction['end_time'] as String?;
          final endTime = endTimeStr != null
              ? DateTime.tryParse(endTimeStr)
              : null;

          print('[UserBidsSupabaseDataSource]   title: $title');
          print('[UserBidsSupabaseDataSource]   statusName: $statusName');
          print('[UserBidsSupabaseDataSource]   vehicle: $vehicleDisplay');
          print('[UserBidsSupabaseDataSource]   endTime: $endTime');

          // Check if auction ended: consider both end_time and explicit status
          final hasExplicitEndedStatus =
              statusName != null && statusName!.toLowerCase() != 'live';
          final isTimeElapsed =
              endTime != null && DateTime.now().isAfter(endTime);
          final isAuctionEnded = hasExplicitEndedStatus || isTimeElapsed;

          // Check if in_transaction status - buyer can access the transaction
          final isInTransaction =
              statusName != null &&
              statusName!.toLowerCase() == 'in_transaction';

          // Check if deal_failed status - buyer cancelled or deal fell through
          final isDealFailed =
              statusName != null && statusName!.toLowerCase() == 'deal_failed';

          print(
            '[UserBidsSupabaseDataSource]   isAuctionEnded: $isAuctionEnded',
          );
          print(
            '[UserBidsSupabaseDataSource]   isInTransaction: $isInTransaction',
          );
          print('[UserBidsSupabaseDataSource]   isDealFailed: $isDealFailed');

          // Get highest bidder
          String? highestBidderId;
          try {
            final rpcResult = await _supabase.rpc(
              'get_highest_bid',
              params: {'auction_id_param': auctionId},
            );
            if (rpcResult is List && rpcResult.isNotEmpty) {
              highestBidderId =
                  (rpcResult.first as Map<String, dynamic>)['bidder_id']
                      as String?;
            } else if (rpcResult is Map) {
              highestBidderId = rpcResult['bidder_id'] as String?;
            }
          } catch (_) {
            highestBidderId = null;
          }

          final isUserHighestBidder =
              highestBidderId != null && highestBidderId == userId;

          print(
            '[UserBidsSupabaseDataSource]   highestBidderId: $highestBidderId',
          );
          print(
            '[UserBidsSupabaseDataSource]   isUserHighestBidder: $isUserHighestBidder',
          );

          // Categorize bid
          if (!isAuctionEnded) {
            print('[UserBidsSupabaseDataSource]   -> ACTIVE BID');
            // ACTIVE BID
            activeBids.add(
              UserBidEntity(
                id: bidsForThisAuction.first['id'] as String? ?? '',
                auctionId: auctionId,
                carImageUrl: coverPhotoUrl ?? '',
                year: vehicleYear,
                make: vehicleDisplay.split(' ').first,
                model: vehicleDisplay.contains(' ')
                    ? vehicleDisplay.split(' ').last
                    : vehicleDisplay,
                userBidAmount: userMaxBid,
                currentHighestBid: currentPrice,
                endTime: endTime ?? DateTime.now(),
                status: UserBidStatus.active,
                hasDeposited: false,
                isHighestBidder: isUserHighestBidder,
                userBidCount: bidsForThisAuction.length,
                canAccess: false,
                sellerId: sellerId,
              ),
            );
          } else {
            // Auction ended
            if (isUserHighestBidder) {
              // Check if deal was cancelled/failed
              if (isDealFailed) {
                print(
                  '[UserBidsSupabaseDataSource]   -> CANCELLED BID (deal_failed)',
                );
                // CANCELLED - buyer cancelled the deal
                cancelledBids.add(
                  UserBidEntity(
                    id: bidsForThisAuction.first['id'] as String? ?? '',
                    auctionId: auctionId,
                    carImageUrl: coverPhotoUrl ?? '',
                    year: vehicleYear,
                    make: vehicleDisplay.split(' ').first,
                    model: vehicleDisplay.contains(' ')
                        ? vehicleDisplay.split(' ').last
                        : vehicleDisplay,
                    userBidAmount: userMaxBid,
                    currentHighestBid: currentPrice,
                    endTime: endTime ?? DateTime.now(),
                    status: UserBidStatus.cancelled,
                    hasDeposited: false,
                    isHighestBidder: true,
                    userBidCount: bidsForThisAuction.length,
                    canAccess: false,
                    sellerId: sellerId,
                  ),
                );
              } else {
                print(
                  '[UserBidsSupabaseDataSource]   -> WON BID (canAccess: $isInTransaction)',
                );
                // WON
                wonBids.add(
                  UserBidEntity(
                    id: bidsForThisAuction.first['id'] as String? ?? '',
                    auctionId: auctionId,
                    carImageUrl: coverPhotoUrl ?? '',
                    year: vehicleYear,
                    make: vehicleDisplay.split(' ').first,
                    model: vehicleDisplay.contains(' ')
                        ? vehicleDisplay.split(' ').last
                        : vehicleDisplay,
                    userBidAmount: userMaxBid,
                    currentHighestBid: currentPrice,
                    endTime: endTime ?? DateTime.now(),
                    status: UserBidStatus.won,
                    hasDeposited: false,
                    isHighestBidder: true,
                    userBidCount: bidsForThisAuction.length,
                    canAccess:
                        isInTransaction, // true when seller has proceeded
                    sellerId: sellerId,
                  ),
                );
              }
            } else {
              print('[UserBidsSupabaseDataSource]   -> LOST BID');
              // LOST
              lostBids.add(
                UserBidEntity(
                  id: bidsForThisAuction.first['id'] as String? ?? '',
                  auctionId: auctionId,
                  carImageUrl: coverPhotoUrl ?? '',
                  year: vehicleYear,
                  make: vehicleDisplay.split(' ').first,
                  model: vehicleDisplay.contains(' ')
                      ? vehicleDisplay.split(' ').last
                      : vehicleDisplay,
                  userBidAmount: userMaxBid,
                  currentHighestBid: currentPrice,
                  endTime: endTime ?? DateTime.now(),
                  status: UserBidStatus.lost,
                  hasDeposited: false,
                  isHighestBidder: false,
                  userBidCount: bidsForThisAuction.length,
                  canAccess: false,
                  sellerId: sellerId,
                ),
              );
            }
          }
        } catch (e, st) {
          print(
            '[UserBidsSupabaseDataSource] Error processing auction $auctionId: $e\n$st',
          );
          continue;
        }
      }

      print(
        '[UserBidsSupabaseDataSource] SUMMARY: active=${activeBids.length}, won=${wonBids.length}, lost=${lostBids.length}, cancelled=${cancelledBids.length}',
      );
      return {
        'active': activeBids,
        'won': wonBids,
        'lost': lostBids,
        'cancelled': cancelledBids,
      };
    } catch (e, st) {
      print('[UserBidsSupabaseDataSource] Failed to load bids: $e\n$st');
      throw Exception('Failed to load bids: $e');
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
