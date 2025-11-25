/// Represents detailed auction info for auction detail page
class AuctionDetailEntity {
  final String id;
  final String carImageUrl;

  // Auction-specific fields
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

  // Step 1: Basic Information
  final String brand;
  final String model;
  final String? variant;
  final int year;

  // Step 2: Mechanical Specification
  final String? engineType;
  final double? engineDisplacement; // in liters
  final int? cylinderCount;
  final int? horsepower;
  final int? torque;
  final String? transmission;
  final String? fuelType;
  final String? driveType;

  // Step 3: Dimensions & Capacity
  final double? length; // in mm
  final double? width;
  final double? height;
  final double? wheelbase;
  final double? groundClearance;
  final int? seatingCapacity;
  final int? doorCount;
  final double? fuelTankCapacity; // in liters
  final double? curbWeight; // in kg
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
  final int? mileage; // in km
  final int? previousOwners;
  final bool? hasModifications;
  final String? modificationsDetails;
  final bool? hasWarranty;
  final String? warrantyDetails;
  final String? usageType; // private, commercial, taxi

  // Step 6: Documentation & Location
  final String? plateNumber;
  final String? orcrStatus;
  final String? registrationStatus;
  final DateTime? registrationExpiry;
  final String? province;
  final String? cityMunicipality;

  // Step 8: Final Details
  final String? description;
  final String? knownIssues;
  final List<String>? features;

  const AuctionDetailEntity({
    required this.id,
    required this.carImageUrl,
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
    required this.brand,
    required this.model,
    this.variant,
    required this.year,
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
    this.description,
    this.knownIssues,
    this.features,
  });

  /// Get time remaining as Duration
  Duration get timeRemaining => endTime.difference(DateTime.now());

  /// Check if auction has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Get formatted car name (basic)
  String get carName => '$year $brand $model';

  /// Get full car name including variant
  String get fullCarName {
    final parts = [
      year.toString(),
      brand,
      model,
      if (variant != null) variant,
    ];
    return parts.join(' ');
  }

  /// Backwards compatibility getter
  String get make => brand;
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
