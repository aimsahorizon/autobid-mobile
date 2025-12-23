/// Entity representing a monitored auction with real-time bid activity
class AuctionMonitorEntity {
  final String id;
  final String title;
  final String? primaryImageUrl;

  // Auction details
  final String vehicleMake;
  final String vehicleModel;
  final int vehicleYear;
  final String sellerId;
  final String sellerName;

  // Bidding info
  final double startingPrice;
  final double currentPrice;
  final int totalBids;
  final DateTime endTime;
  final String status;

  // Latest bid info
  final String? latestBidderId;
  final String? latestBidderName;
  final double? latestBidAmount;
  final DateTime? latestBidTime;

  // Monitoring flags
  final bool isFinalTwoMinutes;
  final bool hasHighActivity;

  const AuctionMonitorEntity({
    required this.id,
    required this.title,
    this.primaryImageUrl,
    required this.vehicleMake,
    required this.vehicleModel,
    required this.vehicleYear,
    required this.sellerId,
    required this.sellerName,
    required this.startingPrice,
    required this.currentPrice,
    required this.totalBids,
    required this.endTime,
    required this.status,
    this.latestBidderId,
    this.latestBidderName,
    this.latestBidAmount,
    this.latestBidTime,
    this.isFinalTwoMinutes = false,
    this.hasHighActivity = false,
  });

  /// Get time remaining in minutes
  int get minutesRemaining {
    final now = DateTime.now();
    if (endTime.isBefore(now)) return 0;
    return endTime.difference(now).inMinutes;
  }

  /// Check if auction is active
  bool get isActive => status == 'live' && endTime.isAfter(DateTime.now());

  /// Get activity level based on bids per hour
  String get activityLevel {
    if (totalBids == 0) return 'No Activity';
    final hoursSinceStart = DateTime.now()
        .difference(endTime.subtract(const Duration(days: 7)))
        .inHours;
    if (hoursSinceStart == 0) return 'New';
    final bidsPerHour = totalBids / hoursSinceStart;
    if (bidsPerHour > 10) return 'Very High';
    if (bidsPerHour > 5) return 'High';
    if (bidsPerHour > 2) return 'Moderate';
    return 'Low';
  }
}

/// Entity representing a single bid in monitoring view
class BidMonitorEntity {
  final String id;
  final String auctionId;
  final String bidderId;
  final String bidderName;
  final double amount;
  final DateTime timestamp;
  final bool isAutoBid;

  const BidMonitorEntity({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.bidderName,
    required this.amount,
    required this.timestamp,
    this.isAutoBid = false,
  });
}
