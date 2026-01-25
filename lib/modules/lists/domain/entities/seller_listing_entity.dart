/// Represents a seller's car listing in the auction platform
/// Used across all listing tabs (Active, Pending, In Transaction, etc.)
class SellerListingEntity {
  /// Unique identifier for the listing
  final String id;

  /// Main image URL of the car
  final String imageUrl;

  /// Year of manufacture
  final int year;

  /// Car manufacturer (e.g., Toyota, BMW)
  final String make;

  /// Car model (e.g., Supra, M4)
  final String model;

  /// Current status of the listing
  final ListingStatus status;

  /// Starting price set by seller
  final double startingPrice;

  /// Scheduled start time (for scheduled listings)
  final DateTime? startTime;

  /// Current highest bid (null if no bids yet)
  final double? currentBid;

  /// Reserve price (minimum acceptable price)
  final double? reservePrice;

  /// Total number of bids received
  final int totalBids;

  /// Number of users watching this listing
  final int watchersCount;

  /// Number of views on this listing
  final int viewsCount;

  /// When the listing was created
  final DateTime createdAt;

  /// When the auction ends (null for drafts)
  final DateTime? endTime;

  /// Winning bidder name (for In Transaction/Sold status)
  final String? winnerName;

  /// Transaction amount (for Sold status)
  final double? soldPrice;

  /// Seller ID (owner of the listing)
  final String? sellerId;

  /// Transaction ID if this listing has an associated transaction
  /// Used for cancelled listings that came from failed transactions
  final String? transactionId;

  const SellerListingEntity({
    required this.id,
    required this.imageUrl,
    required this.year,
    required this.make,
    required this.model,
    required this.status,
    required this.startingPrice,
    this.startTime,
    this.currentBid,
    this.reservePrice,
    this.totalBids = 0,
    this.watchersCount = 0,
    this.viewsCount = 0,
    required this.createdAt,
    this.endTime,
    this.winnerName,
    this.soldPrice,
    this.sellerId,
    this.transactionId,
  });

  /// Get formatted car name
  String get carName => '$year $make $model';

  /// Check if reserve price has been met
  bool get isReserveMet =>
      reservePrice != null &&
      currentBid != null &&
      currentBid! >= reservePrice!;

  /// Get time remaining (for active listings)
  Duration? get timeRemaining =>
      endTime?.difference(DateTime.now());

  /// Time until auction starts (for scheduled listings)
  Duration? get timeUntilStart =>
      startTime?.difference(DateTime.now());

  /// Check if auction has ended
  bool get hasEnded => endTime != null && DateTime.now().isAfter(endTime!);
}

/// Enum representing all possible listing statuses
enum ListingStatus {
  /// Listing is live and accepting bids
  active,

  /// Listing is awaiting admin approval
  pending,

  /// Listing approved by admin, waiting for seller to make live
  approved,

  /// Listing scheduled to go live at a specific time
  scheduled,

  /// Auction ended, awaiting seller decision (proceed or cancel)
  ended,

  /// Listing saved but not submitted
  draft,

  /// Listing was cancelled by seller or admin (pre-auction or post-auction)
  cancelled,

  /// Auction in active transaction phase (seller negotiating with buyer)
  inTransaction,

  /// Auction sold and completed
  sold,

  /// Transaction failed after auction ended
  dealFailed,
}

/// Extension to get display properties for each status
extension ListingStatusExtension on ListingStatus {
  /// Get human-readable label
  String get label {
    switch (this) {
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.pending:
        return 'Pending';
      case ListingStatus.approved:
        return 'Approved';
      case ListingStatus.scheduled:
        return 'Scheduled';
      case ListingStatus.ended:
        return 'Ended';
      case ListingStatus.draft:
        return 'Draft';
      case ListingStatus.cancelled:
        return 'Cancelled';
      case ListingStatus.inTransaction:
        return 'In Transaction';
      case ListingStatus.sold:
        return 'Sold';
      case ListingStatus.dealFailed:
        return 'Deal Failed';
    }
  }

  /// Get short tab label
  String get tabLabel {
    switch (this) {
      case ListingStatus.active:
        return 'Active';
      case ListingStatus.pending:
        return 'Pending';
      case ListingStatus.approved:
        return 'Approved';
      case ListingStatus.scheduled:
        return 'Scheduled';
      case ListingStatus.ended:
        return 'Ended';
      case ListingStatus.draft:
        return 'Drafts';
      case ListingStatus.cancelled:
        return 'Cancelled';
      case ListingStatus.inTransaction:
        return 'In Transaction';
      case ListingStatus.sold:
        return 'Sold';
      case ListingStatus.dealFailed:
        return 'Failed';
    }
  }
}
