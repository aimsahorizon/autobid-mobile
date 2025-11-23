import '../../domain/entities/auction_detail_entity.dart';

/// Data model for auction detail that handles JSON serialization
class AuctionDetailModel extends AuctionDetailEntity {
  const AuctionDetailModel({
    required super.id,
    required super.carImageUrl,
    required super.year,
    required super.make,
    required super.model,
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
  });

  /// Create model from JSON (Supabase response)
  factory AuctionDetailModel.fromJson(Map<String, dynamic> json) {
    return AuctionDetailModel(
      id: json['id'] as String,
      carImageUrl: json['car_image_url'] as String? ?? '',
      year: json['year'] as int,
      make: json['make'] as String,
      model: json['model'] as String,
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
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_image_url': carImageUrl,
      'year': year,
      'make': make,
      'model': model,
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
