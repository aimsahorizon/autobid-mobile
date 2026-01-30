/// Represents a car listing draft that can be saved at any step
/// Supports the 9-step create listing flow with partial data
class ListingDraftEntity {
  final String id;
  final String sellerId;
  final int currentStep; // 1-9
  final DateTime lastSaved;
  final bool isComplete;

  // Step 1: Basic Information
  final String? brand;
  final String? model;
  final String? variant;
  final int? year;

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

  // Step 7: Photos (56 categories) & Documents
  final Map<String, List<String>>? photoUrls; // category -> list of URLs
  final List<String>? tags; // AI-generated tags for search/filter
  final String? deedOfSaleUrl; // Deed of sale document URL (PDF/image)

  // Step 8: Final Details, Pricing & Bidding Configuration
  final String? description;
  final String? knownIssues;
  final List<String>? features;
  final double? startingPrice;
  final double? reservePrice;
  final DateTime? auctionEndDate;
  // Bidding Configuration (Step 8)
  final String? biddingType; // 'public' or 'private'
  final double? bidIncrement; // Minimum increment for bids
  final double? minBidIncrement; // Alias for bidIncrement for clarity
  final double? depositAmount; // Required deposit to bid
  final bool? enableIncrementalBidding; // Allow price-based increments

  const ListingDraftEntity({
    required this.id,
    required this.sellerId,
    required this.currentStep,
    required this.lastSaved,
    this.isComplete = false,
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
    this.tags,
    this.deedOfSaleUrl,
    this.description,
    this.knownIssues,
    this.features,
    this.startingPrice,
    this.reservePrice,
    this.auctionEndDate,
    this.biddingType,
    this.bidIncrement,
    this.minBidIncrement,
    this.depositAmount,
    this.enableIncrementalBidding,
  });

  /// Create a copy of this entity with updated fields
  ListingDraftEntity copyWith({
    String? id,
    String? sellerId,
    int? currentStep,
    DateTime? lastSaved,
    bool? isComplete,
    String? brand,
    String? model,
    String? variant,
    int? year,
    String? engineType,
    double? engineDisplacement,
    int? cylinderCount,
    int? horsepower,
    int? torque,
    String? transmission,
    String? fuelType,
    String? driveType,
    double? length,
    double? width,
    double? height,
    double? wheelbase,
    double? groundClearance,
    int? seatingCapacity,
    int? doorCount,
    double? fuelTankCapacity,
    double? curbWeight,
    double? grossWeight,
    String? exteriorColor,
    String? paintType,
    String? rimType,
    String? rimSize,
    String? tireSize,
    String? tireBrand,
    String? condition,
    int? mileage,
    int? previousOwners,
    bool? hasModifications,
    String? modificationsDetails,
    bool? hasWarranty,
    String? warrantyDetails,
    String? usageType,
    String? plateNumber,
    String? orcrStatus,
    String? registrationStatus,
    DateTime? registrationExpiry,
    String? province,
    String? cityMunicipality,
    Map<String, List<String>>? photoUrls,
    List<String>? tags,
    String? deedOfSaleUrl,
    String? description,
    String? knownIssues,
    List<String>? features,
    double? startingPrice,
    double? reservePrice,
    DateTime? auctionEndDate,
    String? biddingType,
    double? bidIncrement,
    double? minBidIncrement,
    double? depositAmount,
    bool? enableIncrementalBidding,
  }) {
    return ListingDraftEntity(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      currentStep: currentStep ?? this.currentStep,
      lastSaved: lastSaved ?? this.lastSaved,
      isComplete: isComplete ?? this.isComplete,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      year: year ?? this.year,
      engineType: engineType ?? this.engineType,
      engineDisplacement: engineDisplacement ?? this.engineDisplacement,
      cylinderCount: cylinderCount ?? this.cylinderCount,
      horsepower: horsepower ?? this.horsepower,
      torque: torque ?? this.torque,
      transmission: transmission ?? this.transmission,
      fuelType: fuelType ?? this.fuelType,
      driveType: driveType ?? this.driveType,
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      wheelbase: wheelbase ?? this.wheelbase,
      groundClearance: groundClearance ?? this.groundClearance,
      seatingCapacity: seatingCapacity ?? this.seatingCapacity,
      doorCount: doorCount ?? this.doorCount,
      fuelTankCapacity: fuelTankCapacity ?? this.fuelTankCapacity,
      curbWeight: curbWeight ?? this.curbWeight,
      grossWeight: grossWeight ?? this.grossWeight,
      exteriorColor: exteriorColor ?? this.exteriorColor,
      paintType: paintType ?? this.paintType,
      rimType: rimType ?? this.rimType,
      rimSize: rimSize ?? this.rimSize,
      tireSize: tireSize ?? this.tireSize,
      tireBrand: tireBrand ?? this.tireBrand,
      condition: condition ?? this.condition,
      mileage: mileage ?? this.mileage,
      previousOwners: previousOwners ?? this.previousOwners,
      hasModifications: hasModifications ?? this.hasModifications,
      modificationsDetails: modificationsDetails ?? this.modificationsDetails,
      hasWarranty: hasWarranty ?? this.hasWarranty,
      warrantyDetails: warrantyDetails ?? this.warrantyDetails,
      usageType: usageType ?? this.usageType,
      plateNumber: plateNumber ?? this.plateNumber,
      orcrStatus: orcrStatus ?? this.orcrStatus,
      registrationStatus: registrationStatus ?? this.registrationStatus,
      registrationExpiry: registrationExpiry ?? this.registrationExpiry,
      province: province ?? this.province,
      cityMunicipality: cityMunicipality ?? this.cityMunicipality,
      photoUrls: photoUrls ?? this.photoUrls,
      tags: tags ?? this.tags,
      deedOfSaleUrl: deedOfSaleUrl ?? this.deedOfSaleUrl,
      description: description ?? this.description,
      knownIssues: knownIssues ?? this.knownIssues,
      features: features ?? this.features,
      startingPrice: startingPrice ?? this.startingPrice,
      reservePrice: reservePrice ?? this.reservePrice,
      auctionEndDate: auctionEndDate ?? this.auctionEndDate,
      biddingType: biddingType ?? this.biddingType,
      bidIncrement: bidIncrement ?? this.bidIncrement,
      minBidIncrement: minBidIncrement ?? this.minBidIncrement,
      depositAmount: depositAmount ?? this.depositAmount,
      enableIncrementalBidding: enableIncrementalBidding ?? this.enableIncrementalBidding,
    );
  }

  /// Get car name from basic info
  String get carName {
    final parts = [
      if (year != null) year.toString(),
      brand,
      model,
      variant,
    ].where((p) => p != null).toList();
    return parts.isEmpty ? 'Untitled Listing' : parts.join(' ');
  }

  /// Check if step is completed (NEW ORDER)
  bool isStepComplete(int step) {
    switch (step) {
      case 1:
        // Step 1: Photos (at least 1 photo required to proceed)
        return photoUrls != null && photoUrls!.isNotEmpty;
      case 2:
        // Step 2: Basic Info (AI-prefilled from photos)
        return brand != null &&
            model != null &&
            variant != null &&
            year != null;
      case 3:
        // Step 3: Mechanical Specification
        return engineType != null && transmission != null && fuelType != null;
      case 4:
        // Step 4: Dimensions & Capacity
        return length != null && width != null && height != null;
      case 5:
        // Step 5: Exterior Details
        return exteriorColor != null && paintType != null;
      case 6:
        // Step 6: Condition & History
        return condition != null && mileage != null && previousOwners != null;
      case 7:
        // Step 7: Documentation & Location
        return plateNumber != null && orcrStatus != null && province != null;
      case 8:
        // Step 8: Final Details, Pricing & Bidding
        return description != null &&
            description!.length >= 50 &&
            startingPrice != null &&
            auctionEndDate != null &&
            bidIncrement != null &&
            depositAmount != null &&
            biddingType != null;
      case 9:
        // Step 9: Summary - always complete if reached
        return true;
      default:
        return false;
    }
  }

  /// Get completion percentage
  double get completionPercentage {
    int completed = 0;
    for (int i = 1; i <= 9; i++) {
      if (isStepComplete(i)) completed++;
    }
    return (completed / 9) * 100;
  }
}

/// Photo categories for the 56 required images
class PhotoCategories {
  static const List<String> all = [
    // Exterior (20)
    'Front View',
    'Rear View',
    'Left Side',
    'Right Side',
    'Front Left Angle',
    'Front Right Angle',
    'Rear Left Angle',
    'Rear Right Angle',
    'Roof',
    'Undercarriage',
    'Front Bumper',
    'Rear Bumper',
    'Left Fender',
    'Right Fender',
    'Hood',
    'Trunk/Tailgate',
    'Fuel Door',
    'Side Mirrors',
    'Door Handles',
    'Exterior Lights',

    // Interior (15)
    'Dashboard',
    'Steering Wheel',
    'Center Console',
    'Front Seats',
    'Rear Seats',
    'Headliner',
    'Door Panels',
    'Carpet/Floor Mats',
    'Trunk Interior',
    'Glove Box',
    'Sun Visors',
    'Instrument Cluster',
    'Infotainment Screen',
    'Climate Controls',
    'Interior Lights',

    // Engine & Mechanical (12)
    'Engine Bay Overview',
    'Engine Block',
    'Battery',
    'Fluid Reservoirs',
    'Air Filter',
    'Alternator',
    'Belts & Hoses',
    'Suspension',
    'Brakes Front',
    'Brakes Rear',
    'Exhaust System',
    'Transmission',

    // Wheels & Tires (4)
    'Front Left Wheel',
    'Front Right Wheel',
    'Rear Left Wheel',
    'Rear Right Wheel',

    // Documents (5)
    'OR/CR',
    'Registration Papers',
    'Insurance',
    'Maintenance Records',
    'Inspection Report',
  ];

  static const Map<String, int> categoryGroups = {
    'Exterior': 20,
    'Interior': 15,
    'Engine & Mechanical': 12,
    'Wheels & Tires': 4,
    'Documents': 5,
  };
}
