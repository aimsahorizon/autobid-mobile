/// Represents an auction in the domain layer
class AuctionEntity {
  final String id;
  final String carImageUrl;
  final int year;
  final String make;
  final String model;
  final double currentBid;
  final int watchersCount;
  final int biddersCount;
  final DateTime endTime;
  final String sellerId;

  const AuctionEntity({
    required this.id,
    required this.carImageUrl,
    required this.year,
    required this.make,
    required this.model,
    required this.currentBid,
    required this.watchersCount,
    required this.biddersCount,
    required this.endTime,
    required this.sellerId,
  });

  /// Calculate time remaining in minutes
  int get timeRemainingMinutes {
    final now = DateTime.now();
    final difference = endTime.difference(now);
    return difference.inMinutes;
  }

  /// Check if auction has ended
  bool get hasEnded {
    return DateTime.now().isAfter(endTime);
  }

  /// Get formatted car name with graceful fallbacks
  String get carName {
    final hasYear = year > 0;
    final hasMake = make.isNotEmpty;
    final hasModel = model.isNotEmpty;

    if (hasYear && (hasMake || hasModel)) {
      return '$year $make $model'.trim();
    }

    if (hasMake || hasModel) {
      return '$make $model'.trim();
    }

    return 'Vehicle listing';
  }
}
