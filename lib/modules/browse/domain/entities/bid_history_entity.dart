/// Represents a single bid record in auction history
/// Used to display bid timeline and track bidding activity
class BidHistoryEntity {
  /// Unique identifier for the bid
  final String id;

  /// ID of the auction this bid belongs to
  final String auctionId;

  /// Display name of the bidder (anonymized for privacy)
  final String bidderName;

  /// The bid amount in currency
  final double amount;

  /// When the bid was placed
  final DateTime timestamp;

  /// Whether this is the current user's bid
  final bool isCurrentUser;

  /// Whether this is the current winning bid
  final bool isWinning;

  const BidHistoryEntity({
    required this.id,
    required this.auctionId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
    this.isCurrentUser = false,
    this.isWinning = false,
  });
}
