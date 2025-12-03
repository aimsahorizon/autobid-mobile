import '../../domain/entities/auction_entity.dart';

/// Data model for auction that handles JSON serialization
/// Maps to Supabase 'auctions' table
class AuctionModel extends AuctionEntity {
  const AuctionModel({
    required super.id,
    required super.carImageUrl,
    required super.year,
    required super.make,
    required super.model,
    required super.currentBid,
    required super.watchersCount,
    required super.biddersCount,
    required super.endTime,
    required super.sellerId,
  });

  /// Create model from JSON (Supabase response)
  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    return AuctionModel(
      id: json['id'] as String,
      carImageUrl: json['car_image_url'] as String? ?? '',
      year: json['year'] as int,
      make: json['make'] as String,
      model: json['model'] as String,
      currentBid: (json['current_bid'] as num).toDouble(),
      watchersCount: json['watchers_count'] as int? ?? 0,
      biddersCount: json['bidders_count'] as int? ?? 0,
      endTime: DateTime.parse(json['end_time'] as String),
      sellerId: json['seller_id'] as String,
    );
  }

  /// Convert model to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'car_image_url': carImageUrl,
      'year': year,
      'make': make,
      'model': model,
      'current_bid': currentBid,
      'watchers_count': watchersCount,
      'bidders_count': biddersCount,
      'end_time': endTime.toIso8601String(),
      'seller_id': sellerId,
    };
  }

  /// Convert entity to model
  factory AuctionModel.fromEntity(AuctionEntity entity) {
    return AuctionModel(
      id: entity.id,
      carImageUrl: entity.carImageUrl,
      year: entity.year,
      make: entity.make,
      model: entity.model,
      currentBid: entity.currentBid,
      watchersCount: entity.watchersCount,
      biddersCount: entity.biddersCount,
      endTime: entity.endTime,
      sellerId: entity.sellerId,
    );
  }
}
