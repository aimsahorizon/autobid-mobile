/// Admin view of a listing for review and management
class AdminListingEntity {
  final String id;
  final String title;
  final String sellerId;
  final String sellerName;
  final String sellerEmail;
  final String status;
  final double startingPrice;
  final double? reservePrice;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final String? coverPhotoUrl;

  // Vehicle details
  final int year;
  final String brand;
  final String model;
  final String? variant;
  final int mileage;
  final String condition;

  // Admin metadata
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  const AdminListingEntity({
    required this.id,
    required this.title,
    required this.sellerId,
    required this.sellerName,
    required this.sellerEmail,
    required this.status,
    required this.startingPrice,
    this.reservePrice,
    required this.createdAt,
    this.submittedAt,
    this.coverPhotoUrl,
    required this.year,
    required this.brand,
    required this.model,
    this.variant,
    required this.mileage,
    required this.condition,
    this.reviewNotes,
    this.reviewedAt,
    this.reviewedBy,
  });

  String get carName => '$year $brand $model${variant != null ? ' $variant' : ''}';
}

/// Admin statistics entity
class AdminStatsEntity {
  final int pendingListings;
  final int activeListings;
  final int totalUsers;
  final int totalListings;
  final int todaySubmissions;

  const AdminStatsEntity({
    required this.pendingListings,
    required this.activeListings,
    required this.totalUsers,
    required this.totalListings,
    required this.todaySubmissions,
  });
}
