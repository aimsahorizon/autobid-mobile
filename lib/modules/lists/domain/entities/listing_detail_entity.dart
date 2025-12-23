import 'listing_draft_entity.dart';
import 'seller_listing_entity.dart';

/// Complete listing details combining seller listing status with full car specifications
/// This entity is used when viewing detailed information about any listing
/// Merges data from SellerListingEntity (status, bids) + ListingDraftEntity (car specs)
class ListingDetailEntity {
  // From SellerListingEntity - Auction/Status Info
  final String id;
  final ListingStatus status;
  final double startingPrice;
  final DateTime? startTime;
  final double? currentBid;
  final double? reservePrice;
  final int totalBids;
  final int watchersCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime? endTime;
  final String? winnerName;
  final double? soldPrice;

  // From ListingDraftEntity - Step 1: Basic Information
  final String? brand;
  final String? model;
  final String? variant;
  final int? year;

  // Step 2: Mechanical Specification
  final String? engineType;
  final double? engineDisplacement;
  final int? cylinderCount;
  final int? horsepower;
  final int? torque;
  final String? transmission;
  final String? fuelType;
  final String? driveType;

  // Step 3: Dimensions & Capacity
  final double? length;
  final double? width;
  final double? height;
  final double? wheelbase;
  final double? groundClearance;
  final int? seatingCapacity;
  final int? doorCount;
  final double? fuelTankCapacity;
  final double? curbWeight;
  final double? grossWeight;

  // Step 4: Exterior Details
  final String? exteriorColor;
  final String? paintType;
  final String? rimType;
  final String? rimSize;
  final String? tireSize;
  final String? tireBrand;

  // Step 5: Condition & History
  final String? condition;
  final int? mileage;
  final int? previousOwners;
  final bool? hasModifications;
  final String? modificationsDetails;
  final bool? hasWarranty;
  final String? warrantyDetails;
  final String? usageType;

  // Step 6: Documentation & Location
  final String? plateNumber;
  final String? orcrStatus;
  final String? registrationStatus;
  final DateTime? registrationExpiry;
  final String? province;
  final String? cityMunicipality;

  // Step 7: Photos
  final Map<String, List<String>>? photoUrls;

  // Step 8: Final Details
  final String? description;
  final String? knownIssues;
  final List<String>? features;
  final DateTime? auctionEndDate;

  const ListingDetailEntity({
    required this.id,
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
    this.brand,
    this.model,
    this.variant,
    this.year,
    this.engineType,
    this.engineDisplacement,
    this.cylinderCount,
    this.horsepower,
    this.torque,
    this.transmission,
    this.fuelType,
    this.driveType,
    this.length,
    this.width,
    this.height,
    this.wheelbase,
    this.groundClearance,
    this.seatingCapacity,
    this.doorCount,
    this.fuelTankCapacity,
    this.curbWeight,
    this.grossWeight,
    this.exteriorColor,
    this.paintType,
    this.rimType,
    this.rimSize,
    this.tireSize,
    this.tireBrand,
    this.condition,
    this.mileage,
    this.previousOwners,
    this.hasModifications,
    this.modificationsDetails,
    this.hasWarranty,
    this.warrantyDetails,
    this.usageType,
    this.plateNumber,
    this.orcrStatus,
    this.registrationStatus,
    this.registrationExpiry,
    this.province,
    this.cityMunicipality,
    this.photoUrls,
    this.description,
    this.knownIssues,
    this.features,
    this.auctionEndDate,
  });

  /// Get formatted car name
  String get carName => '$year $brand $model';

  /// Get cover photo URL (first photo from any category)
  String? get coverPhotoUrl {
    if (photoUrls == null || photoUrls!.isEmpty) return null;
    for (final urls in photoUrls!.values) {
      if (urls.isNotEmpty) return urls.first;
    }
    return null;
  }

  /// Check if reserve price has been met
  bool get isReserveMet =>
      reservePrice != null && currentBid != null && currentBid! >= reservePrice!;

  /// Get time remaining (for active listings)
  Duration? get timeRemaining =>
      endTime != null ? endTime!.difference(DateTime.now()) : null;

    /// Time until auction starts (for scheduled listings)
    Duration? get timeUntilStart =>
      startTime != null ? startTime!.difference(DateTime.now()) : null;

  /// Check if auction has ended
  bool get hasEnded => endTime != null && DateTime.now().isAfter(endTime!);
}
