import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auction_model.dart';
import '../models/auction_detail_model.dart';
import '../../domain/entities/auction_filter.dart';

/// Supabase datasource for auction operations
/// Handles fetching, filtering, and managing auctions from vehicles table
class AuctionSupabaseDataSource {
  final SupabaseClient _supabase;

  AuctionSupabaseDataSource(this._supabase);

  /// Get all active auctions with comprehensive filtering
  /// Uses listings table with full-text search across multiple fields
  Future<List<AuctionModel>> getActiveAuctions({
    AuctionFilter? filter,
  }) async {
    try {
      // Build base query - query listings table directly for access to all fields
      var queryBuilder = _supabase
          .from('listings')
          .select('id, cover_photo_url, year, brand, model, current_bid, watchers_count, total_bids, auction_end_time, seller_id, created_at')
          .eq('status', 'active')
          .gt('auction_end_time', DateTime.now().toIso8601String())
          .isFilter('deleted_at', null);

      // Apply search query (comprehensive search across multiple text fields)
      if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        // Search in: brand, model, variant, description, exterior_color, condition, transmission, fuel_type, drive_type, location
        queryBuilder = queryBuilder.or(
          'brand.ilike.%$query%,'
          'model.ilike.%$query%,'
          'variant.ilike.%$query%,'
          'description.ilike.%$query%,'
          'exterior_color.ilike.%$query%,'
          'condition.ilike.%$query%,'
          'transmission.ilike.%$query%,'
          'fuel_type.ilike.%$query%,'
          'drive_type.ilike.%$query%,'
          'province.ilike.%$query%,'
          'city_municipality.ilike.%$query%'
        );
      }

      // Apply specific filters
      if (filter?.make != null) {
        queryBuilder = queryBuilder.eq('brand', filter!.make!);
      }
      if (filter?.model != null) {
        queryBuilder = queryBuilder.eq('model', filter!.model!);
      }
      if (filter?.yearFrom != null) {
        queryBuilder = queryBuilder.gte('year', filter!.yearFrom!);
      }
      if (filter?.yearTo != null) {
        queryBuilder = queryBuilder.lte('year', filter!.yearTo!);
      }
      if (filter?.priceMin != null) {
        queryBuilder = queryBuilder.gte('current_bid', filter!.priceMin!);
      }
      if (filter?.priceMax != null) {
        queryBuilder = queryBuilder.lte('current_bid', filter!.priceMax!);
      }
      if (filter?.transmission != null) {
        queryBuilder = queryBuilder.eq('transmission', filter!.transmission!);
      }
      if (filter?.fuelType != null) {
        queryBuilder = queryBuilder.eq('fuel_type', filter!.fuelType!);
      }
      if (filter?.driveType != null) {
        queryBuilder = queryBuilder.eq('drive_type', filter!.driveType!);
      }
      if (filter?.condition != null) {
        queryBuilder = queryBuilder.eq('condition', filter!.condition!);
      }
      if (filter?.maxMileage != null) {
        queryBuilder = queryBuilder.lte('mileage', filter!.maxMileage!);
      }
      if (filter?.exteriorColor != null) {
        queryBuilder = queryBuilder.eq('exterior_color', filter!.exteriorColor!);
      }
      if (filter?.province != null) {
        queryBuilder = queryBuilder.eq('province', filter!.province!);
      }
      if (filter?.city != null) {
        queryBuilder = queryBuilder.eq('city_municipality', filter!.city!);
      }

      // Apply ending soon filter (within 24 hours)
      if (filter?.endingSoon == true) {
        final twentyFourHoursLater = DateTime.now().add(const Duration(hours: 24));
        queryBuilder = queryBuilder.lte('auction_end_time', twentyFourHoursLater.toIso8601String());
      }

      // Order by ending soonest first
      final response = await queryBuilder.order('auction_end_time');

      // Convert to AuctionModel list
      return (response as List).map((json) {
        // Map database columns to model fields
        return AuctionModel.fromJson({
          'id': json['id'],
          'car_image_url': json['cover_photo_url'] ?? '',
          'year': json['year'],
          'make': json['brand'],
          'model': json['model'],
          'current_bid': json['current_bid'],
          'watchers_count': json['watchers_count'] ?? 0,
          'bidders_count': json['total_bids'] ?? 0,
          'end_time': json['auction_end_time'],
          'seller_id': json['seller_id'],
        });
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get auctions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get auctions: $e');
    }
  }

  /// Get auction details by ID with all related data
  /// Includes listing photos from photo_urls JSONB field
  Future<AuctionDetailModel> getAuctionDetail(String auctionId, String? userId) async {
    try {
      // Get listing details
      final listingResponse = await _supabase
          .from('listings')
          .select()
          .eq('id', auctionId)
          .eq('status', 'active')
          .isFilter('deleted_at', null)
          .single();

      // Get photos from JSONB field
      final photoUrls = listingResponse['photo_urls'] as Map<String, dynamic>? ?? {};
      final Map<String, List<String>> photosByCategory = {};

      photoUrls.forEach((category, urls) {
        if (urls is List) {
          photosByCategory[category] = List<String>.from(urls);
        }
      });

      // Build auction detail model
      return AuctionDetailModel.fromJson({
        ...listingResponse,
        'car_image_url': listingResponse['cover_photo_url'] ?? '',
        'make': listingResponse['brand'],
        'minimum_bid': listingResponse['starting_price'],
        'end_time': listingResponse['auction_end_time'],
        'is_reserve_met': listingResponse['reserve_price'] != null &&
            listingResponse['current_bid'] >= listingResponse['reserve_price'],
        'show_reserve_price': true,
        'bidders_count': listingResponse['total_bids'] ?? 0,
        'has_user_deposited': false, // Will be implemented with bids module
        'photos': photosByCategory,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to get auction details: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get auction details: $e');
    }
  }

  /// Add auction to user's watchlist
  /// Increments watchers_count on listing
  Future<void> watchAuction(String userId, String auctionId) async {
    try {
      // Increment watchers count
      await _supabase.rpc('increment_watchers', params: {
        'listing_id': auctionId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to watch auction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to watch auction: $e');
    }
  }

  /// Remove auction from user's watchlist
  /// Decrements watchers_count on listing
  Future<void> unwatchAuction(String userId, String auctionId) async {
    try {
      // Decrement watchers count
      await _supabase.rpc('decrement_watchers', params: {
        'listing_id': auctionId,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to unwatch auction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to unwatch auction: $e');
    }
  }
}
