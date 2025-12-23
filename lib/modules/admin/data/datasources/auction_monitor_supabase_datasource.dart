import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/auction_monitor_entity.dart';

/// Supabase datasource for admin auction monitoring
/// Provides real-time bid tracking and auction activity monitoring
class AuctionMonitorSupabaseDataSource {
  final SupabaseClient _supabase;

  AuctionMonitorSupabaseDataSource(this._supabase);

  /// Get all active auctions for monitoring
  Future<List<AuctionMonitorEntity>> getActiveAuctions() async {
    try {
      print(
        '[AuctionMonitorDataSource] Querying auction_browse_listings view...',
      );

      // Query the same view that browse page uses
      // This view already filters for live auctions and valid end_time
      final response = await _supabase
          .from('auction_browse_listings')
          .select('''
            id, title, starting_price, current_price, end_time,
            total_bids, seller_id, created_at, status_id,
            vehicle_year, vehicle_make, vehicle_model,
            primary_image_url, watchers_count
          ''')
          .order('end_time', ascending: true)
          .limit(100);

      print(
        '[AuctionMonitorDataSource] Found ${(response as List).length} auctions from view',
      );
      final auctions = <AuctionMonitorEntity>[];

      for (final json in (response as List)) {
        // Get latest bid for this auction
        final latestBid = await _getLatestBid(json['id'] as String);

        // Get seller info
        final sellerInfo = await _getSellerInfo(json['seller_id'] as String);

        auctions.add(_parseAuctionMonitorFromView(json, latestBid, sellerInfo));
      }

      print(
        '[AuctionMonitorDataSource] Parsed ${auctions.length} auction entities',
      );
      return auctions;
    } catch (e, stackTrace) {
      print('[AuctionMonitorDataSource] Error fetching auctions: $e');
      print('[AuctionMonitorDataSource] Stack trace: $stackTrace');
      return [];
    }
  }

  /// Stream active auctions with real-time updates
  Stream<List<AuctionMonitorEntity>> streamActiveAuctions() {
    final controller = StreamController<List<AuctionMonitorEntity>>();
    final channel = _supabase.channel('admin-auction-monitor');

    // Subscribe to auction updates
    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'auctions',
        callback: (_) => _emitSnapshot(controller),
      )
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'bids',
        callback: (_) => _emitSnapshot(controller),
      )
      ..subscribe();

    // Initial load
    _emitSnapshot(controller);

    controller.onCancel = () async {
      try {
        await _supabase.removeChannel(channel);
      } catch (e) {
        print('[AuctionMonitorDataSource] Error removing channel: $e');
      }
    };

    return controller.stream;
  }

  /// Get bid history for a specific auction
  Future<List<BidMonitorEntity>> getAuctionBids(String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('''
            id, auction_id, bid_amount, is_auto_bid, created_at, bidder_id,
            bidder:users!bidder_id(display_name, full_name, username)
          ''')
          .eq('auction_id', auctionId)
          .order('created_at', ascending: false)
          .limit(50);

      return (response as List).map((json) {
        final bidder = json['bidder'] as Map<String, dynamic>?;
        String bidderName = 'Unknown';
        if (bidder != null) {
          bidderName =
              (bidder['display_name'] as String?) ??
              (bidder['full_name'] as String?) ??
              (bidder['username'] as String?) ??
              'Unknown';
        }

        return BidMonitorEntity(
          id: json['id'] as String,
          auctionId: json['auction_id'] as String,
          bidderId: json['bidder_id'] as String,
          bidderName: bidderName,
          amount: (json['bid_amount'] as num).toDouble(),
          timestamp: DateTime.parse(json['created_at'] as String),
          isAutoBid: json['is_auto_bid'] as bool? ?? false,
        );
      }).toList();
    } catch (e) {
      print('[AuctionMonitorDataSource] Error fetching bids: $e');
      return [];
    }
  }

  /// Stream bid history for a specific auction
  Stream<List<BidMonitorEntity>> streamAuctionBids(String auctionId) {
    final controller = StreamController<List<BidMonitorEntity>>();
    final channel = _supabase.channel('auction-bids-$auctionId');

    channel
      ..onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'bids',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'auction_id',
          value: auctionId,
        ),
        callback: (_) async {
          final bids = await getAuctionBids(auctionId);
          if (!controller.isClosed) {
            controller.add(bids);
          }
        },
      )
      ..subscribe();

    // Initial load
    getAuctionBids(auctionId).then((bids) {
      if (!controller.isClosed) {
        controller.add(bids);
      }
    });

    controller.onCancel = () async {
      try {
        await _supabase.removeChannel(channel);
      } catch (e) {
        print('[AuctionMonitorDataSource] Error removing channel: $e');
      }
    };

    return controller.stream;
  }

  /// Helper: Get latest bid for an auction
  Future<Map<String, dynamic>?> _getLatestBid(String auctionId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select('''
            bid_amount, created_at, bidder_id,
            bidder:users!bidder_id(display_name, full_name)
          ''')
          .eq('auction_id', auctionId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Helper: Get seller information
  Future<Map<String, dynamic>?> _getSellerInfo(String sellerId) async {
    try {
      final response = await _supabase
          .from('users')
          .select('display_name, full_name, username')
          .eq('id', sellerId)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Helper: Emit snapshot of active auctions
  Future<void> _emitSnapshot(
    StreamController<List<AuctionMonitorEntity>> controller,
  ) async {
    try {
      final auctions = await getActiveAuctions();
      if (!controller.isClosed) {
        controller.add(auctions);
      }
    } catch (e) {
      print('[AuctionMonitorDataSource] Error emitting snapshot: $e');
    }
  }

  /// Helper: Parse auction JSON from view to entity
  AuctionMonitorEntity _parseAuctionMonitorFromView(
    Map<String, dynamic> json,
    Map<String, dynamic>? latestBid,
    Map<String, dynamic>? seller,
  ) {
    final endTime = DateTime.parse(json['end_time'] as String);
    final now = DateTime.now();
    final minutesRemaining = endTime.difference(now).inMinutes;

    String? latestBidderName;
    if (latestBid != null) {
      final bidder = latestBid['bidder'] as Map<String, dynamic>?;
      if (bidder != null) {
        latestBidderName =
            (bidder['display_name'] as String?) ??
            (bidder['full_name'] as String?) ??
            'Unknown';
      }
    }

    String sellerName = 'Unknown';
    if (seller != null) {
      sellerName =
          (seller['display_name'] as String?) ??
          (seller['full_name'] as String?) ??
          (seller['username'] as String?) ??
          'Unknown';
    }

    return AuctionMonitorEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      primaryImageUrl:
          (json['primary_image_url'] as String?)?.isNotEmpty == true
          ? json['primary_image_url'] as String?
          : null,
      vehicleMake: json['vehicle_make'] as String? ?? '',
      vehicleModel: json['vehicle_model'] as String? ?? '',
      vehicleYear: json['vehicle_year'] as int? ?? 0,
      sellerId: json['seller_id'] as String,
      sellerName: sellerName,
      startingPrice: (json['starting_price'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      totalBids: json['total_bids'] as int? ?? 0,
      endTime: endTime,
      status: 'live',
      latestBidderId: latestBid?['bidder_id'] as String?,
      latestBidderName: latestBidderName,
      latestBidAmount: latestBid != null
          ? (latestBid['bid_amount'] as num).toDouble()
          : null,
      latestBidTime: latestBid != null
          ? DateTime.parse(latestBid['created_at'] as String)
          : null,
      isFinalTwoMinutes: minutesRemaining <= 2 && minutesRemaining >= 0,
      hasHighActivity: (json['total_bids'] as int? ?? 0) > 10,
    );
  }

  /// Helper: Parse auction JSON to entity (legacy - for table-based queries)
  AuctionMonitorEntity _parseAuctionMonitor(
    Map<String, dynamic> json,
    Map<String, dynamic>? latestBid,
  ) {
    final vehicle = json['auction_vehicles'] as List?;
    final photos = json['auction_photos'] as List?;
    final seller = json['users'] as Map<String, dynamic>?;
    final endTime = DateTime.parse(json['end_time'] as String);
    final now = DateTime.now();
    final minutesRemaining = endTime.difference(now).inMinutes;

    String? latestBidderName;
    if (latestBid != null) {
      final bidder = latestBid['bidder'] as Map<String, dynamic>?;
      if (bidder != null) {
        latestBidderName =
            (bidder['display_name'] as String?) ??
            (bidder['full_name'] as String?) ??
            'Unknown';
      }
    }

    return AuctionMonitorEntity(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled',
      primaryImageUrl: photos?.isNotEmpty == true
          ? (photos!.first['photo_url'] as String?)
          : null,
      vehicleMake: vehicle?.isNotEmpty == true
          ? (vehicle!.first['brand'] as String? ?? '')
          : '',
      vehicleModel: vehicle?.isNotEmpty == true
          ? (vehicle!.first['model'] as String? ?? '')
          : '',
      vehicleYear: vehicle?.isNotEmpty == true
          ? (vehicle!.first['year'] as int? ?? 0)
          : 0,
      sellerId: json['seller_id'] as String,
      sellerName: seller != null
          ? ((seller['display_name'] as String?) ??
                (seller['full_name'] as String?) ??
                'Unknown')
          : 'Unknown',
      startingPrice: (json['starting_price'] as num?)?.toDouble() ?? 0.0,
      currentPrice: (json['current_price'] as num?)?.toDouble() ?? 0.0,
      totalBids: json['total_bids'] as int? ?? 0,
      endTime: endTime,
      status: 'live',
      latestBidderId: latestBid?['bidder_id'] as String?,
      latestBidderName: latestBidderName,
      latestBidAmount: latestBid != null
          ? (latestBid['bid_amount'] as num).toDouble()
          : null,
      latestBidTime: latestBid != null
          ? DateTime.parse(latestBid['created_at'] as String)
          : null,
      isFinalTwoMinutes: minutesRemaining <= 2 && minutesRemaining >= 0,
      hasHighActivity: (json['total_bids'] as int? ?? 0) > 10,
    );
  }
}
