import 'package:autobid_mobile/modules/browse/domain/entities/auction_entity.dart';

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
    super.sellerDisplayName,
    super.sellerProfileImageUrl,
    super.visibility,
  });

  /// Create model from JSON (Supabase response)
  factory AuctionModel.fromJson(Map<String, dynamic> json) {
    DateTime parseEndTime(dynamic value) {
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      // Keep item renderable instead of failing whole browse payload.
      return DateTime.now().add(const Duration(hours: 1));
    }

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? fallback;
      return fallback;
    }

    double parseDouble(dynamic value, {double fallback = 0}) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? fallback;
      return fallback;
    }

    final make = (json['make'] as String?) ?? '';
    final model = (json['model'] as String?) ?? '';
    final title = (json['title'] as String?) ?? '';

    // Fallback: if make/model missing, use title so UI shows a meaningful name
    final resolvedMake = make.isNotEmpty ? make : title;
    final resolvedModel = model.isNotEmpty
        ? model
        : (resolvedMake.isNotEmpty ? resolvedMake : '');

    final currentBidValue = parseDouble(
      json['current_bid'] ?? json['starting_price'],
    );
    final yearValue = parseInt(json['year']);
    final sellerIdValue = (json['seller_id']?.toString() ?? '').trim();

    return AuctionModel(
      id: json['id']?.toString() ?? '',
      carImageUrl: json['car_image_url'] as String? ?? '',
      year: yearValue,
      make: resolvedMake,
      model: resolvedModel,
      currentBid: currentBidValue,
      watchersCount: parseInt(json['watchers_count']),
      biddersCount: parseInt(json['bidders_count']),
      endTime: parseEndTime(json['end_time']),
      sellerId: sellerIdValue,
      sellerDisplayName: json['seller_display_name'] as String?,
      sellerProfileImageUrl: json['seller_profile_image_url'] as String?,
      visibility: json['visibility'] as String? ?? 'open',
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
      'seller_display_name': sellerDisplayName,
      'seller_profile_image_url': sellerProfileImageUrl,
      'visibility': visibility,
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
      sellerDisplayName: entity.sellerDisplayName,
      sellerProfileImageUrl: entity.sellerProfileImageUrl,
      visibility: entity.visibility,
    );
  }
}
