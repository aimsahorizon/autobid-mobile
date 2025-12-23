import '../../domain/entities/seller_listing_entity.dart';
import '../../domain/entities/listing_detail_entity.dart';

/// Data model for listings with JSON serialization
/// Converts between database JSON and domain entities
class ListingModel {
  final String id;
  final String sellerId;
  final String status;
  final String adminStatus;
  final String? rejectionReason;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime? madeLiveAt;
  final String brand;
  final String model;
  final String? variant;
  final int year;
  final String? engineType;
  final double? engineDisplacement;
  final int? cylinderCount;
  final int? horsepower;
  final int? torque;
  final String transmission;
  final String fuelType;
  final String? driveType;
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
  final String exteriorColor;
  final String? paintType;
  final String? rimType;
  final String? rimSize;
  final String? tireSize;
  final String? tireBrand;
  final String condition;
  final int mileage;
  final int? previousOwners;
  final bool hasModifications;
  final String? modificationsDetails;
  final bool hasWarranty;
  final String? warrantyDetails;
  final String? usageType;
  final String plateNumber;
  final String orcrStatus;
  final String registrationStatus;
  final DateTime? registrationExpiry;
  final String province;
  final String cityMunicipality;
  final Map<String, List<String>> photoUrls;
  final String? coverPhotoUrl;
  final String description;
  final String? knownIssues;
  final List<String>? features;
  final double startingPrice;
  final double currentBid;
  final double? reservePrice;
  final DateTime? auctionStartTime;
  final DateTime? auctionEndTime;
  final int totalBids;
  final int watchersCount;
  final int viewsCount;
  final String? winnerId;
  final double? soldPrice;
  final DateTime? soldAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Transaction ID for cancelled listings that have an associated failed transaction
  final String? transactionId;

  const ListingModel({
    required this.id,
    required this.sellerId,
    required this.status,
    required this.adminStatus,
    this.rejectionReason,
    this.reviewedAt,
    this.reviewedBy,
    this.madeLiveAt,
    required this.brand,
    required this.model,
    this.variant,
    required this.year,
    this.engineType,
    this.engineDisplacement,
    this.cylinderCount,
    this.horsepower,
    this.torque,
    required this.transmission,
    required this.fuelType,
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
    required this.exteriorColor,
    this.paintType,
    this.rimType,
    this.rimSize,
    this.tireSize,
    this.tireBrand,
    required this.condition,
    required this.mileage,
    this.previousOwners,
    required this.hasModifications,
    this.modificationsDetails,
    required this.hasWarranty,
    this.warrantyDetails,
    this.usageType,
    required this.plateNumber,
    required this.orcrStatus,
    required this.registrationStatus,
    this.registrationExpiry,
    required this.province,
    required this.cityMunicipality,
    required this.photoUrls,
    this.coverPhotoUrl,
    required this.description,
    this.knownIssues,
    this.features,
    required this.startingPrice,
    required this.currentBid,
    this.reservePrice,
    this.auctionStartTime,
    this.auctionEndTime,
    required this.totalBids,
    required this.watchersCount,
    required this.viewsCount,
    this.winnerId,
    this.soldPrice,
    this.soldAt,
    required this.createdAt,
    required this.updatedAt,
    this.transactionId,
  });

  /// Convert database row to model
  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String? ?? '',
      sellerId: json['seller_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      adminStatus: json['admin_status'] as String? ?? 'pending',
      rejectionReason: json['rejection_reason'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      reviewedBy: json['reviewed_by'] as String?,
      madeLiveAt: json['made_live_at'] != null
          ? DateTime.parse(json['made_live_at'] as String)
          : null,
      brand: json['brand'] as String? ?? '',
      model: json['model'] as String? ?? '',
      variant: json['variant'] as String?,
      year: json['year'] as int? ?? 0,
      engineType: json['engine_type'] as String?,
      engineDisplacement: _toDouble(json['engine_displacement']),
      cylinderCount: json['cylinder_count'] as int?,
      horsepower: json['horsepower'] as int?,
      torque: json['torque'] as int?,
      transmission: json['transmission'] as String? ?? '',
      fuelType: json['fuel_type'] as String? ?? '',
      driveType: json['drive_type'] as String?,
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
      exteriorColor: json['exterior_color'] as String? ?? '',
      paintType: json['paint_type'] as String?,
      rimType: json['rim_type'] as String?,
      rimSize: json['rim_size'] as String?,
      tireSize: json['tire_size'] as String?,
      tireBrand: json['tire_brand'] as String?,
      condition: json['condition'] as String? ?? '',
      mileage: json['mileage'] as int? ?? 0,
      previousOwners: json['previous_owners'] as int?,
      hasModifications: json['has_modifications'] as bool? ?? false,
      modificationsDetails: json['modifications_details'] as String?,
      hasWarranty: json['has_warranty'] as bool? ?? false,
      warrantyDetails: json['warranty_details'] as String?,
      usageType: json['usage_type'] as String?,
      plateNumber: json['plate_number'] as String? ?? '',
      orcrStatus: json['orcr_status'] as String? ?? '',
      registrationStatus: json['registration_status'] as String? ?? '',
      registrationExpiry: json['registration_expiry'] != null
          ? DateTime.parse(json['registration_expiry'] as String)
          : null,
      province: json['province'] as String? ?? '',
      cityMunicipality: json['city_municipality'] as String? ?? '',
      photoUrls: json['photo_urls'] != null
          ? _parsePhotoUrls(json['photo_urls'] as Map<String, dynamic>)
          : {},
      coverPhotoUrl: json['cover_photo_url'] as String?,
      description: json['description'] as String? ?? '',
      knownIssues: json['known_issues'] as String?,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
      startingPrice: _toDouble(json['starting_price']) ?? 0,
      currentBid: _toDouble(json['current_bid']) ?? 0,
      reservePrice: _toDouble(json['reserve_price']),
      auctionStartTime: json['auction_start_time'] != null
          ? DateTime.parse(json['auction_start_time'] as String)
          : null,
      auctionEndTime: json['auction_end_time'] != null
          ? DateTime.parse(json['auction_end_time'] as String)
          : null,
      totalBids: json['total_bids'] as int? ?? 0,
      watchersCount: json['watchers_count'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      winnerId: json['winner_id'] as String?,
      soldPrice: _toDouble(json['sold_price']),
      soldAt: json['sold_at'] != null
          ? DateTime.parse(json['sold_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      transactionId: json['transaction_id'] as String?,
    );
  }

  /// Convert to SellerListingEntity (for list views)
  SellerListingEntity toSellerListingEntity() {
    return SellerListingEntity(
      id: id,
      imageUrl: coverPhotoUrl ?? '',
      year: year,
      make: brand,
      model: model,
      status: _parseListingStatus(status),
      startingPrice: startingPrice,
      startTime: auctionStartTime,
      currentBid: currentBid > 0 ? currentBid : null,
      reservePrice: reservePrice,
      totalBids: totalBids,
      watchersCount: watchersCount,
      viewsCount: viewsCount,
      createdAt: createdAt,
      endTime: auctionEndTime,
      winnerName: null, // Will be populated separately if needed
      soldPrice: soldPrice,
      sellerId: sellerId,
      transactionId: transactionId,
    );
  }

  /// Convert to ListingDetailEntity (for detail views)
  ListingDetailEntity toListingDetailEntity() {
    return ListingDetailEntity(
      id: id,
      status: _parseListingStatus(status),
      startingPrice: startingPrice,
      currentBid: currentBid > 0 ? currentBid : null,
      reservePrice: reservePrice,
      totalBids: totalBids,
      watchersCount: watchersCount,
      viewsCount: viewsCount,
      createdAt: createdAt,
      endTime: auctionEndTime,
      winnerName: null,
      soldPrice: soldPrice,
      brand: brand,
      model: model,
      variant: variant,
      year: year,
      engineType: engineType,
      engineDisplacement: engineDisplacement,
      cylinderCount: cylinderCount,
      horsepower: horsepower,
      torque: torque,
      transmission: transmission,
      fuelType: fuelType,
      driveType: driveType,
      length: length,
      width: width,
      height: height,
      wheelbase: wheelbase,
      groundClearance: groundClearance,
      seatingCapacity: seatingCapacity,
      doorCount: doorCount,
      fuelTankCapacity: fuelTankCapacity,
      curbWeight: curbWeight,
      grossWeight: grossWeight,
      exteriorColor: exteriorColor,
      paintType: paintType,
      rimType: rimType,
      rimSize: rimSize,
      tireSize: tireSize,
      tireBrand: tireBrand,
      condition: condition,
      mileage: mileage,
      previousOwners: previousOwners,
      hasModifications: hasModifications,
      modificationsDetails: modificationsDetails,
      hasWarranty: hasWarranty,
      warrantyDetails: warrantyDetails,
      usageType: usageType,
      plateNumber: plateNumber,
      orcrStatus: orcrStatus,
      registrationStatus: registrationStatus,
      registrationExpiry: registrationExpiry,
      province: province,
      cityMunicipality: cityMunicipality,
      photoUrls: photoUrls,
      description: description,
      knownIssues: knownIssues,
      features: features,
      auctionEndDate: auctionEndTime,
    );
  }

  /// Helper: Parse photo URLs from JSONB
  static Map<String, List<String>> _parsePhotoUrls(Map<String, dynamic> json) {
    final Map<String, List<String>> result = {};
    json.forEach((key, value) {
      if (value is List) {
        result[key] = List<String>.from(value);
      }
    });
    return result;
  }

  /// Helper: Parse listing status from database string
  static ListingStatus _parseListingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'live':
        return ListingStatus.active;
      case 'pending':
      case 'pending_approval':
        return ListingStatus.pending;
      case 'approved':
        return ListingStatus.approved;
      case 'scheduled':
        return ListingStatus.scheduled;
      case 'ended':
        return ListingStatus.ended;
      case 'cancelled':
        return ListingStatus.cancelled;
      case 'in_transaction':
        return ListingStatus.inTransaction;
      case 'sold':
        return ListingStatus.sold;
      case 'deal_failed':
        return ListingStatus.dealFailed;
      case 'draft':
      default:
        return ListingStatus.draft;
    }
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
