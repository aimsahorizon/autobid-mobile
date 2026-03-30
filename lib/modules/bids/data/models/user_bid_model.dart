import '../../domain/entities/user_bid_entity.dart';

/// Data model for user bid that handles JSON serialization
/// Maps between Supabase data and domain entity
class UserBidModel extends UserBidEntity {
  const UserBidModel({
    required super.id,
    required super.auctionId,
    required super.carImageUrl,
    required super.year,
    required super.make,
    required super.model,
    super.variant,
    required super.userBidAmount,
    required super.currentHighestBid,
    required super.endTime,
    required super.status,
    required super.hasDeposited,
    required super.isHighestBidder,
    required super.userBidCount,
    required super.canAccess,
    super.transactionStatus,
    super.sellerId,
    super.standbyNote,
  });

  /// Create model from JSON (Supabase response)
  /// Combines data from bids and listings tables
  factory UserBidModel.fromComposite({
    required Map<String, dynamic> auction,
    required double userMaxBid,
    required int userBidCount,
    required bool isHighestBidder,
    required bool hasEnded,
    required bool hasTransaction,
    String? transactionStatus,
    String? sellerId,
  }) {
    final status = !hasEnded
        ? UserBidStatus.active
        : (isHighestBidder ? UserBidStatus.won : UserBidStatus.lost);

    return UserBidModel(
      id: auction['id'] as String? ?? '',
      auctionId: auction['id'] as String? ?? '',
      carImageUrl: auction['cover_photo_url'] as String? ?? '',
      year: auction['year'] as int? ?? 0,
      make: auction['brand'] as String? ?? '',
      model: auction['model'] as String? ?? '',
      variant: auction['variant'] as String?,
      userBidAmount: userMaxBid,
      currentHighestBid: (auction['current_bid'] as num?)?.toDouble() ?? 0.0,
      endTime: DateTime.parse(auction['auction_end_time'] as String),
      status: status,
      hasDeposited: true,
      isHighestBidder: isHighestBidder,
      userBidCount: userBidCount,
      canAccess: status != UserBidStatus.won || hasTransaction,
      transactionStatus: transactionStatus,
      sellerId: sellerId,
    );
  }

  /// Create a standby bid model from standby queue data + auction data
  factory UserBidModel.fromStandby({
    required Map<String, dynamic> auction,
    required Map<String, dynamic> standby,
  }) {
    return UserBidModel(
      id: standby['id'] as String? ?? '',
      auctionId: auction['id'] as String? ?? '',
      carImageUrl: auction['cover_photo_url'] as String? ?? '',
      year: auction['year'] as int? ?? 0,
      make: auction['brand'] as String? ?? '',
      model: auction['model'] as String? ?? '',
      variant: auction['variant'] as String?,
      userBidAmount: (standby['bid_amount'] as num?)?.toDouble() ?? 0.0,
      currentHighestBid: (auction['current_bid'] as num?)?.toDouble() ?? 0.0,
      endTime: DateTime.parse(auction['auction_end_time'] as String),
      status: UserBidStatus.standby,
      hasDeposited: true,
      isHighestBidder: false,
      userBidCount: 0,
      canAccess: false,
      sellerId: auction['seller_id'] as String?,
      standbyNote: standby['note'] as String?,
    );
  }

  /// Convert model to JSON (for Supabase operations)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'auction_id': auctionId,
      'bid_amount': userBidAmount,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  /// Convert entity to model
  factory UserBidModel.fromEntity(UserBidEntity entity) {
    return UserBidModel(
      id: entity.id,
      auctionId: entity.auctionId,
      carImageUrl: entity.carImageUrl,
      year: entity.year,
      make: entity.make,
      model: entity.model,
      variant: entity.variant,
      userBidAmount: entity.userBidAmount,
      currentHighestBid: entity.currentHighestBid,
      endTime: entity.endTime,
      status: entity.status,
      hasDeposited: entity.hasDeposited,
      isHighestBidder: entity.isHighestBidder,
      userBidCount: entity.userBidCount,
      canAccess: entity.canAccess,
      transactionStatus: entity.transactionStatus,
      sellerId: entity.sellerId,
      standbyNote: entity.standbyNote,
    );
  }
}
