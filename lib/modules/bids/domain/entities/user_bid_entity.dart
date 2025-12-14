/// Represents a user's bid participation in an auction
/// Used to track active, won, and lost bids across auctions
/// This entity belongs to the Bids module, which manages user's bidding history
class UserBidEntity {
  /// Unique identifier for this bid record
  final String id;

  /// ID of the auction this bid belongs to
  final String auctionId;

  /// Car image URL for display in bid cards
  final String carImageUrl;

  /// Year of the car being auctioned
  final int year;

  /// Car make (manufacturer, e.g., Toyota, Honda)
  final String make;

  /// Car model (e.g., Supra, Civic)
  final String model;

  /// User's highest bid amount on this auction
  final double userBidAmount;

  /// Current highest bid in the auction (may be from another bidder)
  final double currentHighestBid;

  /// When the auction ends (or ended)
  final DateTime endTime;

  /// Current status of the bid: active, won, or lost
  final UserBidStatus status;

  /// Whether user has paid the deposit for this auction
  final bool hasDeposited;

  /// Whether user is currently the highest bidder (for active auctions)
  final bool isHighestBidder;

  /// Total number of bids user placed on this auction
  final int userBidCount;

  /// Whether the bidder can access post-auction details (requires seller to proceed)
  final bool canAccess;

  /// Transaction status if seller has proceeded (e.g., in_transaction, sold)
  final String? transactionStatus;

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
    required this.canAccess,
    this.transactionStatus,
  });

  /// Get formatted car name (e.g., "2020 Toyota Supra")
  String get carName => '$year $make $model';

  /// Check if auction has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Get time remaining as Duration (returns zero if ended)
  Duration get timeRemaining => endTime.difference(DateTime.now());

  /// True when user won but awaits seller action to proceed
  bool get awaitingSellerDecision => status == UserBidStatus.won && !canAccess;
}

/// Enum representing the status of user's bid participation in an auction
enum UserBidStatus {
  /// Auction is still active and user has placed at least one bid
  active,

  /// Auction ended and user won (was the highest bidder)
  won,

  /// Auction ended and user lost (was not the highest bidder)
  lost,
}
