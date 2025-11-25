import '../../domain/entities/auction_detail_entity.dart';

/// Data model for auction detail that handles JSON serialization
class AuctionDetailModel extends AuctionDetailEntity {
  const AuctionDetailModel({
    required super.id,
    required super.carImageUrl,
    required super.currentBid,
    required super.minimumBid,
    super.reservePrice,
    required super.isReserveMet,
    required super.showReservePrice,
    required super.watchersCount,
    required super.biddersCount,
    required super.totalBids,
    required super.endTime,
    required super.status,
    required super.photos,
    required super.hasUserDeposited,
    required super.brand,
    required super.model,
    super.variant,
    required super.year,
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
    super.description,
    super.knownIssues,
    super.features,
  });

  /// Create model from JSON (Supabase response)
  factory AuctionDetailModel.fromJson(Map<String, dynamic> json) {
    return AuctionDetailModel(
      id: json['id'] as String,
      carImageUrl: json['car_image_url'] as String? ?? '',
      currentBid: (json['current_bid'] as num).toDouble(),
      minimumBid: (json['minimum_bid'] as num).toDouble(),
      reservePrice: json['reserve_price'] != null
          ? (json['reserve_price'] as num).toDouble()
          : null,
      isReserveMet: json['is_reserve_met'] as bool? ?? false,
      showReservePrice: json['show_reserve_price'] as bool? ?? false,
      watchersCount: json['watchers_count'] as int? ?? 0,
      biddersCount: json['bidders_count'] as int? ?? 0,
      totalBids: json['total_bids'] as int? ?? 0,
      endTime: DateTime.parse(json['end_time'] as String),
      status: json['status'] as String? ?? 'active',
      photos: CarPhotosModel.fromJson(json['photos'] as Map<String, dynamic>? ?? {}),
      hasUserDeposited: json['has_user_deposited'] as bool? ?? false,
      brand: json['brand'] as String? ?? json['make'] as String,
      model: json['model'] as String,
      variant: json['variant'] as String?,
      year: json['year'] as int,
      engineType: json['engine_type'] as String?,
      engineDisplacement: json['engine_displacement'] != null
          ? (json['engine_displacement'] as num).toDouble()
          : null,
      cylinderCount: json['cylinder_count'] as int?,
      horsepower: json['horsepower'] as int?,
      torque: json['torque'] as int?,
      transmission: json['transmission'] as String?,
      fuelType: json['fuel_type'] as String?,
      driveType: json['drive_type'] as String?,
      length: json['length'] != null ? (json['length'] as num).toDouble() : null,
      width: json['width'] != null ? (json['width'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      wheelbase: json['wheelbase'] != null ? (json['wheelbase'] as num).toDouble() : null,
      groundClearance: json['ground_clearance'] != null
          ? (json['ground_clearance'] as num).toDouble()
          : null,
      seatingCapacity: json['seating_capacity'] as int?,
      doorCount: json['door_count'] as int?,
      fuelTankCapacity: json['fuel_tank_capacity'] != null
          ? (json['fuel_tank_capacity'] as num).toDouble()
          : null,
      curbWeight: json['curb_weight'] != null
          ? (json['curb_weight'] as num).toDouble()
          : null,
      grossWeight: json['gross_weight'] != null
          ? (json['gross_weight'] as num).toDouble()
          : null,
      exteriorColor: json['exterior_color'] as String?,
      paintType: json['paint_type'] as String?,
      rimType: json['rim_type'] as String?,
      rimSize: json['rim_size'] as String?,
      tireSize: json['tire_size'] as String?,
      tireBrand: json['tire_brand'] as String?,
      condition: json['condition'] as String?,
      mileage: json['mileage'] as int?,
      previousOwners: json['previous_owners'] as int?,
      hasModifications: json['has_modifications'] as bool?,
      modificationsDetails: json['modifications_details'] as String?,
      hasWarranty: json['has_warranty'] as bool?,
      warrantyDetails: json['warranty_details'] as String?,
      usageType: json['usage_type'] as String?,
      plateNumber: json['plate_number'] as String?,
      orcrStatus: json['orcr_status'] as String?,
      registrationStatus: json['registration_status'] as String?,
      registrationExpiry: json['registration_expiry'] != null
          ? DateTime.parse(json['registration_expiry'] as String)
          : null,
      province: json['province'] as String?,
      cityMunicipality: json['city_municipality'] as String?,
      description: json['description'] as String?,
      knownIssues: json['known_issues'] as String?,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_image_url': carImageUrl,
      'current_bid': currentBid,
      'minimum_bid': minimumBid,
      'reserve_price': reservePrice,
      'is_reserve_met': isReserveMet,
      'show_reserve_price': showReservePrice,
      'watchers_count': watchersCount,
      'bidders_count': biddersCount,
      'total_bids': totalBids,
      'end_time': endTime.toIso8601String(),
      'status': status,
      'photos': (photos as CarPhotosModel).toJson(),
      'has_user_deposited': hasUserDeposited,
      'brand': brand,
      'make': brand, // backwards compatibility
      'model': model,
      'variant': variant,
      'year': year,
      'engine_type': engineType,
      'engine_displacement': engineDisplacement,
      'cylinder_count': cylinderCount,
      'horsepower': horsepower,
      'torque': torque,
      'transmission': transmission,
      'fuel_type': fuelType,
      'drive_type': driveType,
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
      'exterior_color': exteriorColor,
      'paint_type': paintType,
      'rim_type': rimType,
      'rim_size': rimSize,
      'tire_size': tireSize,
      'tire_brand': tireBrand,
      'condition': condition,
      'mileage': mileage,
      'previous_owners': previousOwners,
      'has_modifications': hasModifications,
      'modifications_details': modificationsDetails,
      'has_warranty': hasWarranty,
      'warranty_details': warrantyDetails,
      'usage_type': usageType,
      'plate_number': plateNumber,
      'orcr_status': orcrStatus,
      'registration_status': registrationStatus,
      'registration_expiry': registrationExpiry?.toIso8601String(),
      'province': province,
      'city_municipality': cityMunicipality,
      'description': description,
      'known_issues': knownIssues,
      'features': features,
    };
  }
}

/// Data model for car photos
class CarPhotosModel extends CarPhotosEntity {
  const CarPhotosModel({
    required super.exterior,
    required super.interior,
    required super.engine,
    required super.details,
    required super.documents,
  });

  factory CarPhotosModel.fromJson(Map<String, dynamic> json) {
    return CarPhotosModel(
      exterior: List<String>.from(json['exterior'] ?? []),
      interior: List<String>.from(json['interior'] ?? []),
      engine: List<String>.from(json['engine'] ?? []),
      details: List<String>.from(json['details'] ?? []),
      documents: List<String>.from(json['documents'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exterior': exterior,
      'interior': interior,
      'engine': engine,
      'details': details,
      'documents': documents,
    };
  }
}
