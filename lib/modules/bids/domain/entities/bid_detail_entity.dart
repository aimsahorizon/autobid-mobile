/// Complete bid details including auction info and user's participation
/// Combines auction data with user-specific bidding information
class BidDetailEntity {
  // Auction information (from AuctionDetailEntity)
  final String id;
  final String sellerId;

  // Basic car info
  final String? brand;
  final String? model;
  final String? variant;
  final int year;

  // Auction/Bidding info
  final double startingPrice;
  final double? currentBid;
  final double? reservePrice;
  final int totalBids;
  final DateTime? auctionEndDate;
  final List<BidHistoryItem> bidHistory;

  // User's bidding participation
  final double userHighestBid;
  final int userBidCount;
  final bool isUserHighestBidder;
  final bool hasDeposited;
  final double depositAmount;
  final DateTime? depositPaidAt;

  // Car specifications (from browse auction detail)
  final String? engineType;
  final double? engineDisplacement;
  final int? cylinderCount;
  final int? horsepower;
  final int? torque;
  final String? transmission;
  final String? fuelType;
  final String? driveType;

  // Dimensions
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

  // Exterior
  final String? exteriorColor;
  final String? paintType;
  final String? rimType;
  final String? rimSize;
  final String? tireSize;
  final String? tireBrand;

  // Condition
  final String? condition;
  final int? mileage;
  final int? previousOwners;
  final bool? hasModifications;
  final String? modificationsDetails;
  final bool? hasWarranty;
  final String? warrantyDetails;
  final String? usageType;

  // Documentation
  final String? plateNumber;
  final String? orcrStatus;
  final String? registrationStatus;
  final DateTime? registrationExpiry;
  final String? province;
  final String? cityMunicipality;

  // Media & description
  final Map<String, List<String>>? photoUrls;
  final String? description;
  final String? knownIssues;
  final List<String>? features;

  const BidDetailEntity({
    required this.id,
    required this.sellerId,
    this.brand,
    this.model,
    this.variant,
    required this.year,
    required this.startingPrice,
    this.currentBid,
    this.reservePrice,
    required this.totalBids,
    this.auctionEndDate,
    required this.bidHistory,
    required this.userHighestBid,
    required this.userBidCount,
    required this.isUserHighestBidder,
    required this.hasDeposited,
    required this.depositAmount,
    this.depositPaidAt,
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
  });

  String get fullCarName {
    final parts = [
      year.toString(),
      brand,
      model,
      if (variant != null) variant,
    ];
    return parts.join(' ');
  }

  bool get hasEnded => auctionEndDate != null && DateTime.now().isAfter(auctionEndDate!);

  Duration? get timeRemaining => auctionEndDate?.difference(DateTime.now());
}

/// Single bid record in auction history
class BidHistoryItem {
  final String id;
  final String bidderId;
  final String bidderName;
  final double bidAmount;
  final DateTime timestamp;
  final bool isCurrentUser;

  const BidHistoryItem({
    required this.id,
    required this.bidderId,
    required this.bidderName,
    required this.bidAmount,
    required this.timestamp,
    required this.isCurrentUser,
  });
}
