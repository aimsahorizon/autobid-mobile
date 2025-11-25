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

  // Step 7: Photos (56 categories)
  final Map<String, List<String>>? photoUrls; // category -> list of URLs

  // Step 8: Final Details & Pricing
  final String? description;
  final String? knownIssues;
  final List<String>? features;
  final double? startingPrice;
  final double? reservePrice;
  final DateTime? auctionEndDate;

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
    this.description,
    this.knownIssues,
    this.features,
    this.startingPrice,
    this.reservePrice,
    this.auctionEndDate,
  });

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

  /// Check if step is completed
  bool isStepComplete(int step) {
    switch (step) {
      case 1:
        return brand != null && model != null && variant != null && year != null;
      case 2:
        return engineType != null && transmission != null && fuelType != null;
      case 3:
        return length != null && width != null && height != null;
      case 4:
        return exteriorColor != null && paintType != null;
      case 5:
        return condition != null && mileage != null && previousOwners != null;
      case 6:
        return plateNumber != null && orcrStatus != null && province != null;
      case 7:
        return photoUrls != null && photoUrls!.isNotEmpty;
      case 8:
        return description != null && description!.length >= 50 &&
               startingPrice != null && auctionEndDate != null;
      case 9:
        return true; // Summary step - always complete if reached
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
