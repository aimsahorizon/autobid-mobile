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
    required super.userBidAmount,
    required super.currentHighestBid,
    required super.endTime,
    required super.status,
    required super.hasDeposited,
    required super.isHighestBidder,
    required super.userBidCount,
  });

  /// Create model from JSON (Supabase response)
  /// Combines data from bids and listings tables
  factory UserBidModel.fromJson(Map<String, dynamic> json) {
    // Parse listing data (joined from listings table)
    final listing = json['listings'] as Map<String, dynamic>?;

    // Determine status based on auction end time and bid position
    final endTime = DateTime.parse(
      listing?['auction_end_time'] ??
          listing?['end_time'] ??
          json['auction_end_time'] ??
          json['end_time'] as String,
    );
    final isWinning = json['is_winning'] as bool? ?? false;
    final hasEnded = DateTime.now().isAfter(endTime);

    UserBidStatus status;
    if (!hasEnded) {
      status = UserBidStatus.active;
    } else if (isWinning) {
      status = UserBidStatus.won;
    } else {
      status = UserBidStatus.lost;
    }

    return UserBidModel(
      id: json['bid_id'] as String? ?? json['id'] as String,
      auctionId: json['listing_id'] as String? ?? json['auction_id'] as String,
      carImageUrl:
          listing?['cover_photo_url'] as String? ??
          listing?['car_image_url'] as String? ??
          '',
      year: listing?['year'] as int? ?? 0,
      make: listing?['brand'] as String? ?? listing?['make'] as String? ?? '',
      model: listing?['model'] as String? ?? '',
      userBidAmount: (json['bid_amount'] as num).toDouble(),
      currentHighestBid: (listing?['current_bid'] as num?)?.toDouble() ?? 0.0,
      endTime: endTime,
      status: status,
      hasDeposited: true, // If user has bid, they must have deposited
      isHighestBidder: isWinning,
      userBidCount: 1, // Will be counted from bid history
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
      userBidAmount: entity.userBidAmount,
      currentHighestBid: entity.currentHighestBid,
      endTime: entity.endTime,
      status: entity.status,
      hasDeposited: entity.hasDeposited,
      isHighestBidder: entity.isHighestBidder,
      userBidCount: entity.userBidCount,
    );
  }
}
