/// Entity representing mystery bid status for a user on an auction
class MysteryBidStatusEntity {
  final bool auctionEnded;
  final bool hasBid;
  final double? userBidAmount;
  final int bidCount;
  final bool isSeller;
  final List<MysteryBidEntry> allBids;
  final MysteryTiebreakerEntity? tiebreaker;
  final String? winnerId;

  const MysteryBidStatusEntity({
    required this.auctionEnded,
    required this.hasBid,
    this.userBidAmount,
    required this.bidCount,
    required this.isSeller,
    this.allBids = const [],
    this.tiebreaker,
    this.winnerId,
  });

  factory MysteryBidStatusEntity.fromJson(Map<String, dynamic> json) {
    final allBidsRaw = json['all_bids'];
    final sellerBidsRaw = json['seller_bids'];
    final bidsJson = allBidsRaw ?? sellerBidsRaw;

    List<MysteryBidEntry> bids = [];
    if (bidsJson != null && bidsJson is List) {
      bids = bidsJson
          .map((b) => MysteryBidEntry.fromJson(b as Map<String, dynamic>))
          .toList();
    }

    MysteryTiebreakerEntity? tiebreaker;
    if (json['tiebreaker'] != null && json['tiebreaker'] is Map) {
      tiebreaker = MysteryTiebreakerEntity.fromJson(
        json['tiebreaker'] as Map<String, dynamic>,
      );
    }

    return MysteryBidStatusEntity(
      auctionEnded: json['auction_ended'] as bool? ?? false,
      hasBid: json['has_bid'] as bool? ?? false,
      userBidAmount: (json['user_bid_amount'] as num?)?.toDouble(),
      bidCount: json['bid_count'] as int? ?? 0,
      isSeller: json['is_seller'] as bool? ?? false,
      allBids: bids,
      tiebreaker: tiebreaker,
      winnerId: json['winner_id'] as String?,
    );
  }
}

/// A single bid entry revealed after auction ends (or to seller during)
class MysteryBidEntry {
  final String id;
  final String bidderId;
  final double bidAmount;
  final DateTime createdAt;
  final String? bidStatus; // 'won', 'lost', null

  const MysteryBidEntry({
    required this.id,
    required this.bidderId,
    required this.bidAmount,
    required this.createdAt,
    this.bidStatus,
  });

  factory MysteryBidEntry.fromJson(Map<String, dynamic> json) {
    return MysteryBidEntry(
      id: json['id'] as String,
      bidderId: json['bidder_id'] as String,
      bidAmount: (json['bid_amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      bidStatus: json['bid_status'] as String?,
    );
  }
}

/// Tiebreaker result for mystery auctions
class MysteryTiebreakerEntity {
  final String? id;
  final String? auctionId;
  final double? tiedAmount;
  final List<String> tiedBidderIds;
  final String winnerId;
  final String tiebreakerType; // 'coin_flip' or 'lottery'
  final String resultSeed;

  const MysteryTiebreakerEntity({
    this.id,
    this.auctionId,
    this.tiedAmount,
    required this.tiedBidderIds,
    required this.winnerId,
    required this.tiebreakerType,
    required this.resultSeed,
  });

  bool get isCoinFlip => tiebreakerType == 'coin_flip';
  bool get isLottery => tiebreakerType == 'lottery';

  factory MysteryTiebreakerEntity.fromJson(Map<String, dynamic> json) {
    List<String> bidderIds = [];
    if (json['tied_bidder_ids'] != null) {
      bidderIds = (json['tied_bidder_ids'] as List)
          .map((e) => e.toString())
          .toList();
    }

    return MysteryTiebreakerEntity(
      id: json['id'] as String?,
      auctionId: json['auction_id'] as String?,
      tiedAmount: (json['tied_amount'] as num?)?.toDouble(),
      tiedBidderIds: bidderIds,
      winnerId: json['winner_id'] as String,
      tiebreakerType:
          json['tiebreaker_type'] as String? ??
          json['type'] as String? ??
          'lottery',
      resultSeed: json['result_seed'] as String? ?? '1',
    );
  }
}
