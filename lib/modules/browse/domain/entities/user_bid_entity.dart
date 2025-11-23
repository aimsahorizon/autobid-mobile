/// Represents a user's bid participation in an auction
/// Used to track active, won, and lost bids across auctions
class UserBidEntity {
  /// Unique identifier for this bid record
  final String id;

  /// ID of the auction
  final String auctionId;

  /// Car image URL for display
  final String carImageUrl;

  /// Year of the car
  final int year;

  /// Car make (e.g., Toyota)
  final String make;

  /// Car model (e.g., Supra)
  final String model;

  /// User's highest bid amount
  final double userBidAmount;

  /// Current highest bid in the auction
  final double currentHighestBid;

  /// When the auction ends
  final DateTime endTime;

  /// Status: 'active', 'won', 'lost'
  final UserBidStatus status;

  /// Whether user has deposited for this auction
  final bool hasDeposited;

  /// Whether user is currently the highest bidder
  final bool isHighestBidder;

  /// Total number of bids user placed on this auction
  final int userBidCount;

  const UserBidEntity({
    required this.id,
    required this.auctionId,
    required this.carImageUrl,
    required this.year,
    required this.make,
    required this.model,
    required this.userBidAmount,
    required this.currentHighestBid,
    required this.endTime,
    required this.status,
    required this.hasDeposited,
    required this.isHighestBidder,
    required this.userBidCount,
  });

  /// Get formatted car name
  String get carName => '$year $make $model';

  /// Check if auction has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Get time remaining as Duration
  Duration get timeRemaining => endTime.difference(DateTime.now());
}

/// Enum representing the status of user's bid participation
enum UserBidStatus {
  /// Auction is still active and user has deposited
  active,

  /// Auction ended and user won (was highest bidder)
  won,

  /// Auction ended and user lost (was not highest bidder)
  lost,
}
