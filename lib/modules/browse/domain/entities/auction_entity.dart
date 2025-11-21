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

  /// Get formatted car name (Year Make Model)
  String get carName => '$year $make $model';
}
