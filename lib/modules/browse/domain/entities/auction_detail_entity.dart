/// Represents detailed auction info for auction detail page
class AuctionDetailEntity {
  final String id;
  final String carImageUrl;
  final int year;
  final String make;
  final String model;
  final double currentBid;
  final double minimumBid;
  final double? reservePrice;
  final bool isReserveMet;
  final bool showReservePrice;
  final int watchersCount;
  final int biddersCount;
  final int totalBids;
  final DateTime endTime;
  final String status; // 'active', 'ended', 'sold'
  final CarPhotosEntity photos;
  final bool hasUserDeposited;

  const AuctionDetailEntity({
    required this.id,
    required this.carImageUrl,
    required this.year,
    required this.make,
    required this.model,
    required this.currentBid,
    required this.minimumBid,
    this.reservePrice,
    required this.isReserveMet,
    required this.showReservePrice,
    required this.watchersCount,
    required this.biddersCount,
    required this.totalBids,
    required this.endTime,
    required this.status,
    required this.photos,
    required this.hasUserDeposited,
  });

  /// Get time remaining as Duration
  Duration get timeRemaining => endTime.difference(DateTime.now());

  /// Check if auction has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Get formatted car name
  String get carName => '$year $make $model';
}

/// Holds categorized car photos
class CarPhotosEntity {
  final List<String> exterior;
  final List<String> interior;
  final List<String> engine;
  final List<String> details;
  final List<String> documents;

  const CarPhotosEntity({
    required this.exterior,
    required this.interior,
    required this.engine,
    required this.details,
    required this.documents,
  });

  /// Get photos by category name
  List<String> getByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'exterior':
        return exterior;
      case 'interior':
        return interior;
      case 'engine':
        return engine;
      case 'details':
        return details;
      case 'documents':
        return documents;
      default:
        return exterior;
    }
  }
}
