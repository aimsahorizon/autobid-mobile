import '../../domain/entities/listing_draft_entity.dart';

/// Data model for listing drafts with JSON serialization
/// Converts between database JSON and domain entity
class ListingDraftModel extends ListingDraftEntity {
  const ListingDraftModel({
    required super.id,
    required super.sellerId,
    required super.currentStep,
    required super.lastSaved,
    super.isComplete,
    super.brand,
    super.model,
    super.variant,
    super.year,
    super.engineType,
    super.engineDisplacement,
    super.cylinderCount,
    super.horsepower,
    super.torque,
    super.transmission,
    super.fuelType,
    super.driveType,
    super.length,
    super.width,
    super.height,
    super.wheelbase,
    super.groundClearance,
    super.seatingCapacity,
    super.doorCount,
    super.fuelTankCapacity,
    super.curbWeight,
    super.grossWeight,
    super.exteriorColor,
    super.paintType,
    super.rimType,
    super.rimSize,
    super.tireSize,
    super.tireBrand,
    super.condition,
    super.mileage,
    super.previousOwners,
    super.hasModifications,
    super.modificationsDetails,
    super.hasWarranty,
    super.warrantyDetails,
    super.usageType,
    super.plateNumber,
    super.orcrStatus,
    super.registrationStatus,
    super.registrationExpiry,
    super.province,
    super.cityMunicipality,
    super.photoUrls,
    super.description,
    super.knownIssues,
    super.features,
    super.startingPrice,
    super.reservePrice,
    super.auctionEndDate,
    super.biddingType,
    super.bidIncrement,
    super.minBidIncrement,
    super.depositAmount,
    super.enableIncrementalBidding,
  });

  /// Convert database row to model
  factory ListingDraftModel.fromJson(Map<String, dynamic> json) {
    return ListingDraftModel(
      id: json['id'] as String,
      sellerId: json['seller_id'] as String,
      currentStep: json['current_step'] as int,
      lastSaved: DateTime.parse(json['last_saved'] as String),
      isComplete: json['is_complete'] as bool? ?? false,
      // Step 1: Basic Information
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      variant: json['variant'] as String?,
      year: json['year'] as int?,
      // Step 2: Mechanical
      engineType: json['engine_type'] as String?,
      engineDisplacement: _toDouble(json['engine_displacement']),
      cylinderCount: json['cylinder_count'] as int?,
      horsepower: json['horsepower'] as int?,
      torque: json['torque'] as int?,
      transmission: json['transmission'] as String?,
      fuelType: json['fuel_type'] as String?,
      driveType: json['drive_type'] as String?,
      // Step 3: Dimensions
      length: _toDouble(json['length']),
      width: _toDouble(json['width']),
      height: _toDouble(json['height']),
      wheelbase: _toDouble(json['wheelbase']),
      groundClearance: _toDouble(json['ground_clearance']),
      seatingCapacity: json['seating_capacity'] as int?,
      doorCount: json['door_count'] as int?,
      fuelTankCapacity: _toDouble(json['fuel_tank_capacity']),
      curbWeight: _toDouble(json['curb_weight']),
      grossWeight: _toDouble(json['gross_weight']),
      // Step 4: Exterior
      exteriorColor: json['exterior_color'] as String?,
      paintType: json['paint_type'] as String?,
      rimType: json['rim_type'] as String?,
      rimSize: json['rim_size'] as String?,
      tireSize: json['tire_size'] as String?,
      tireBrand: json['tire_brand'] as String?,
      // Step 5: Condition
      condition: json['condition'] as String?,
      mileage: json['mileage'] as int?,
      previousOwners: json['previous_owners'] as int?,
      hasModifications: json['has_modifications'] as bool?,
      modificationsDetails: json['modifications_details'] as String?,
      hasWarranty: json['has_warranty'] as bool?,
      warrantyDetails: json['warranty_details'] as String?,
      usageType: json['usage_type'] as String?,
      // Step 6: Documentation
      plateNumber: json['plate_number'] as String?,
      orcrStatus: json['orcr_status'] as String?,
      registrationStatus: json['registration_status'] as String?,
      registrationExpiry: json['registration_expiry'] != null
          ? DateTime.parse(json['registration_expiry'] as String)
          : null,
      province: json['province'] as String?,
      cityMunicipality: json['city_municipality'] as String?,
      // Step 7: Photos (JSONB)
      photoUrls: json['photo_urls'] != null
          ? _parsePhotoUrls(json['photo_urls'] as Map<String, dynamic>)
          : null,
      // Step 8: Final Details
      description: json['description'] as String?,
      knownIssues: json['known_issues'] as String?,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
      startingPrice: _toDouble(json['starting_price']),
      reservePrice: _toDouble(json['reserve_price']),
      auctionEndDate: json['auction_end_date'] != null
          ? DateTime.parse(json['auction_end_date'] as String)
          : null,
      // Step 8: Bidding Configuration
      biddingType: json['bidding_type'] as String? ?? 'public',
      bidIncrement: _toDouble(json['bid_increment']),
      minBidIncrement: _toDouble(json['min_bid_increment']),
      depositAmount: _toDouble(json['deposit_amount']),
      enableIncrementalBidding:
          json['enable_incremental_bidding'] as bool? ?? true,
    );
  }

  /// Convert model to database JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'current_step': currentStep,
      'last_saved': lastSaved.toIso8601String(),
      'is_complete': isComplete,
      // Step 1
      'brand': brand,
      'model': model,
      'variant': variant,
      'year': year,
      // Step 2
      'engine_type': engineType,
      'engine_displacement': engineDisplacement,
      'cylinder_count': cylinderCount,
      'horsepower': horsepower,
      'torque': torque,
      'transmission': transmission,
      'fuel_type': fuelType,
      'drive_type': driveType,
      // Step 3
      'length': length,
      'width': width,
      'height': height,
      'wheelbase': wheelbase,
      'ground_clearance': groundClearance,
      'seating_capacity': seatingCapacity,
      'door_count': doorCount,
      'fuel_tank_capacity': fuelTankCapacity,
      'curb_weight': curbWeight,
      'gross_weight': grossWeight,
      // Step 4
      'exterior_color': exteriorColor,
      'paint_type': paintType,
      'rim_type': rimType,
      'rim_size': rimSize,
      'tire_size': tireSize,
      'tire_brand': tireBrand,
      // Step 5
      'condition': condition,
      'mileage': mileage,
      'previous_owners': previousOwners,
      'has_modifications': hasModifications,
      'modifications_details': modificationsDetails,
      'has_warranty': hasWarranty,
      'warranty_details': warrantyDetails,
      'usage_type': usageType,
      // Step 6
      'plate_number': plateNumber,
      'orcr_status': orcrStatus,
      'registration_status': registrationStatus,
      'registration_expiry': registrationExpiry?.toIso8601String(),
      'province': province,
      'city_municipality': cityMunicipality,
      // Step 7 (JSONB)
      'photo_urls': photoUrls,
      // Step 8
      'description': description,
      'known_issues': knownIssues,
      'features': features,
      'starting_price': (startingPrice != null && startingPrice! > 0)
          ? startingPrice
          : null,
      'reserve_price': (reservePrice != null && reservePrice! > 0)
          ? reservePrice
          : null,
      'auction_end_date': auctionEndDate?.toIso8601String(),
      // Step 8: Bidding Configuration
      'bidding_type': biddingType,
      'bid_increment': bidIncrement,
      'min_bid_increment': minBidIncrement,
      'deposit_amount': depositAmount,
      'enable_incremental_bidding': enableIncrementalBidding,
    };
  }

  /// Helper: Parse photo URLs from JSONB
  static Map<String, List<String>>? _parsePhotoUrls(Map<String, dynamic> json) {
    final Map<String, List<String>> result = {};
    json.forEach((key, value) {
      if (value is List) {
        result[key] = List<String>.from(value);
      }
    });
    return result.isEmpty ? null : result;
  }

  /// Helper: Safely convert to double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
