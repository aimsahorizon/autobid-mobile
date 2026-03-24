import 'package:flutter/foundation.dart';
import 'package:async/async.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_bid_entity.dart';
import 'bids_remote_datasource.dart';

/// Supabase datasource for user's bid history
/// Fetches user's active, won, lost, and cancelled bids from database
class UserBidsSupabaseDataSource implements BidsRemoteDataSource {
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
      debugPrint('[UserBidsSupabaseDataSource] getUserBids: userId is null');
      return {
        'active': [],
        'won': [],
        'lost': [],
        'cancelled': [],
        'standby': [],
      };
    }

    debugPrint(
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

      debugPrint(
        '[UserBidsSupabaseDataSource] Query response type: ${response.runtimeType}',
      );
      debugPrint('[UserBidsSupabaseDataSource] Query response: $response');

      final bidsList = List<Map<String, dynamic>>.from(response);

      debugPrint(
        '[UserBidsSupabaseDataSource] Parsed bidsList length: ${bidsList.length}',
      );

      if (bidsList.isEmpty) {
        debugPrint('[UserBidsSupabaseDataSource] No bids found for user');
        return {'active': [], 'won': [], 'lost': [], 'standby': []};
      }

      // Group bids by auction_id to get max bid per auction
      final Map<String, List<Map<String, dynamic>>> bidsByAuctionId = {};
      for (final bid in bidsList) {
        final auctionId = bid['auction_id'] as String;
        bidsByAuctionId.putIfAbsent(auctionId, () => []).add(bid);
      }

      debugPrint(
        '[UserBidsSupabaseDataSource] Grouped bids by auctionId. Count: ${bidsByAuctionId.length}',
      );

      // Process each auction
      for (final auctionId in bidsByAuctionId.keys) {
        debugPrint(
          '[UserBidsSupabaseDataSource] Processing auctionId: $auctionId',
        );
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

            debugPrint(
              '[UserBidsSupabaseDataSource]   Direct auction query result: $auctionResponse',
            );

            if (auctionResponse != null) {
              auction = auctionResponse;
            }
          } catch (e) {
            debugPrint(
              '[UserBidsSupabaseDataSource]   Direct auction query error: $e',
            );
          }

          if (auction == null) {
            debugPrint(
              '[UserBidsSupabaseDataSource]   Auction $auctionId not accessible, skipping',
            );
            continue;
          }

          // Skip if the current user is the seller; prevents showing seller-owned
          // listings in the buyer tab when the auction enters transaction state.
          final sellerId = auction['seller_id'] as String?;
          if (sellerId != null && sellerId == userId) {
            debugPrint(
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
          String brand = '';
          String model = '';
          String? variant;
          int vehicleYear = 0;
          try {
            final vehicleResponse = await _supabase
                .from('auction_vehicles')
                .select('brand, model, variant, year')
                .eq('auction_id', auctionId)
                .limit(1);
            if (vehicleResponse.isNotEmpty) {
              final v = vehicleResponse.first;
              brand = v['brand'] as String? ?? '';
              model = v['model'] as String? ?? '';
              variant = v['variant'] as String?;
              vehicleYear = (v['year'] as num?)?.toInt() ?? 0;
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
            if (photoResponse.isNotEmpty) {
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
          final endTimeStr = auction['end_time'] as String?;
          final endTime = endTimeStr != null
              ? DateTime.tryParse(endTimeStr)
              : null;

          debugPrint('[UserBidsSupabaseDataSource]   title: $title');
          debugPrint('[UserBidsSupabaseDataSource]   statusName: $statusName');
          debugPrint(
            '[UserBidsSupabaseDataSource]   vehicle: $vehicleYear $brand $model $variant',
          );
          debugPrint('[UserBidsSupabaseDataSource]   endTime: $endTime');

          // Check if auction ended: consider both end_time and explicit status
          final hasExplicitEndedStatus =
              statusName != null && statusName.toLowerCase() != 'live';
          final isTimeElapsed =
              endTime != null && DateTime.now().isAfter(endTime);
          final isAuctionEnded = hasExplicitEndedStatus || isTimeElapsed;

          // Check if in_transaction status - buyer can access the transaction
          final isInTransaction =
              statusName != null &&
              statusName.toLowerCase() == 'in_transaction';

          // Check if deal_failed status - buyer cancelled or deal fell through
          final isDealFailed =
              statusName != null && statusName.toLowerCase() == 'deal_failed';

          debugPrint(
            '[UserBidsSupabaseDataSource]   isAuctionEnded: $isAuctionEnded',
          );
          debugPrint(
            '[UserBidsSupabaseDataSource]   isInTransaction: $isInTransaction',
          );
          debugPrint(
            '[UserBidsSupabaseDataSource]   isDealFailed: $isDealFailed',
          );

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

          debugPrint(
            '[UserBidsSupabaseDataSource]   highestBidderId: $highestBidderId',
          );
          debugPrint(
            '[UserBidsSupabaseDataSource]   isUserHighestBidder: $isUserHighestBidder',
          );

          // Categorize bid
          if (!isAuctionEnded) {
            debugPrint('[UserBidsSupabaseDataSource]   -> ACTIVE BID');
            // ACTIVE BID
            activeBids.add(
              UserBidEntity(
                id: bidsForThisAuction.first['id'] as String? ?? '',
                auctionId: auctionId,
                carImageUrl: coverPhotoUrl ?? '',
                year: vehicleYear,
                make: brand,
                model: model,
                variant: variant,
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
                debugPrint(
                  '[UserBidsSupabaseDataSource]   -> CANCELLED BID (deal_failed)',
                );
                // CANCELLED - buyer cancelled the deal
                cancelledBids.add(
                  UserBidEntity(
                    id: bidsForThisAuction.first['id'] as String? ?? '',
                    auctionId: auctionId,
                    carImageUrl: coverPhotoUrl ?? '',
                    year: vehicleYear,
                    make: brand,
                    model: model,
                    variant: variant,
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
                debugPrint(
                  '[UserBidsSupabaseDataSource]   -> WON BID (canAccess: $isInTransaction)',
                );
                // WON
                wonBids.add(
                  UserBidEntity(
                    id: bidsForThisAuction.first['id'] as String? ?? '',
                    auctionId: auctionId,
                    carImageUrl: coverPhotoUrl ?? '',
                    year: vehicleYear,
                    make: brand,
                    model: model,
                    variant: variant,
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
              debugPrint('[UserBidsSupabaseDataSource]   -> LOST BID');
              // LOST
              lostBids.add(
                UserBidEntity(
                  id: bidsForThisAuction.first['id'] as String? ?? '',
                  auctionId: auctionId,
                  carImageUrl: coverPhotoUrl ?? '',
                  year: vehicleYear,
                  make: brand,
                  model: model,
                  variant: variant,
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
          debugPrint(
            '[UserBidsSupabaseDataSource] Error processing auction $auctionId: $e\n$st',
          );
          continue;
        }
      }

      debugPrint(
        '[UserBidsSupabaseDataSource] SUMMARY: active=${activeBids.length}, won=${wonBids.length}, lost=${lostBids.length}, cancelled=${cancelledBids.length}',
      );

      // Fetch standby queue entries for this user
      final List<UserBidEntity> standbyBids = [];
      try {
        final standbyResponse = await _supabase
            .from('auction_standby')
            .select('*')
            .eq('user_id', userId)
            .eq('status', 'waiting');

        final standbyList = List<Map<String, dynamic>>.from(standbyResponse);
        final standbyAuctionIds = standbyList
            .map((s) => s['auction_id'] as String)
            .toSet();

        // Remove lost bids that are in standby (they graduate to standby tab)
        lostBids.removeWhere((b) => standbyAuctionIds.contains(b.auctionId));

        for (final standby in standbyList) {
          final aId = standby['auction_id'] as String;
          try {
            final auctionResp = await _supabase
                .from('auctions')
                .select('*')
                .eq('id', aId)
                .maybeSingle();

            if (auctionResp == null) continue;

            String? coverUrl;
            try {
              final photoResp = await _supabase
                  .from('auction_photos')
                  .select('photo_url')
                  .eq('auction_id', aId)
                  .eq('is_primary', true)
                  .limit(1);
              if (photoResp.isNotEmpty) {
                coverUrl = photoResp.first['photo_url'] as String?;
              }
            } catch (_) {}

            String brand = '';
            String model = '';
            String? variant;
            int year = 0;
            try {
              final vResp = await _supabase
                  .from('auction_vehicles')
                  .select('brand, model, variant, year')
                  .eq('auction_id', aId)
                  .limit(1);
              if (vResp.isNotEmpty) {
                brand = vResp.first['brand'] as String? ?? '';
                model = vResp.first['model'] as String? ?? '';
                variant = vResp.first['variant'] as String?;
                year = (vResp.first['year'] as num?)?.toInt() ?? 0;
              }
            } catch (_) {}

            standbyBids.add(
              UserBidEntity(
                id: standby['id'] as String? ?? '',
                auctionId: aId,
                carImageUrl: coverUrl ?? '',
                year: year,
                make: brand,
                model: model,
                variant: variant,
                userBidAmount:
                    (standby['bid_amount'] as num?)?.toDouble() ?? 0.0,
                currentHighestBid:
                    (auctionResp['current_price'] as num?)?.toDouble() ?? 0.0,
                endTime:
                    DateTime.tryParse(
                      auctionResp['end_time'] as String? ?? '',
                    ) ??
                    DateTime.now(),
                status: UserBidStatus.standby,
                hasDeposited: true,
                isHighestBidder: false,
                userBidCount: 0,
                canAccess: false,
                sellerId: auctionResp['seller_id'] as String?,
                standbyNote: standby['note'] as String?,
              ),
            );
          } catch (e) {
            debugPrint(
              '[UserBidsSupabaseDataSource] Error loading standby auction $aId: $e',
            );
          }
        }
      } catch (e) {
        debugPrint('[UserBidsSupabaseDataSource] Error loading standby: $e');
      }

      return {
        'active': activeBids,
        'won': wonBids,
        'lost': lostBids,
        'cancelled': cancelledBids,
        'standby': standbyBids,
      };
    } catch (e, st) {
      debugPrint('[UserBidsSupabaseDataSource] Failed to load bids: $e\n$st');
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

  /// Stream user's bid updates and auction updates
  /// Listens to changes in 'bids' (for own status) and 'auctions' (for price/status changes)
  @override
  Stream<List<Map<String, dynamic>>> streamUserBids(String userId) {
    // Stream user's own bids (for direct status updates)
    final myBidsStream = _supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('bidder_id', userId);

    // Stream auctions (for outbid detection via current_price/total_bids updates)
    // Note: Streaming all auctions is a trade-off for realtime updates without complex backend sockets
    final auctionsStream = _supabase
        .from('auctions')
        .stream(primaryKey: ['id']);

    return StreamGroup.merge([myBidsStream, auctionsStream]);
  }

  /// Join the standby queue for an auction
  Future<bool> joinStandbyQueue(String auctionId) async {
    try {
      final result = await _supabase.rpc(
        'join_standby_queue',
        params: {'p_auction_id': auctionId},
      );
      return result == true;
    } catch (e) {
      debugPrint('[UserBidsSupabaseDataSource] Error joining standby: $e');
      return false;
    }
  }
}
