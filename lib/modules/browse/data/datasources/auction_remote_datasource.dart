import 'package:autobid_mobile/core/services/supabase_service.dart';
import '../../domain/entities/auction_filter.dart';
import '../models/auction_model.dart';

/// Remote data source for auctions using Supabase
class AuctionRemoteDataSource {
  final SupabaseService _supabaseService;

  AuctionRemoteDataSource(this._supabaseService);

  /// Fetch all live auctions from Supabase with optional filtering
  /// Tries full browse view first, falls back to simple view if unavailable
  Future<List<AuctionModel>> getActiveAuctions({AuctionFilter? filter}) async {
    try {
      print('[AuctionRemoteDataSource] Loading auctions with filter: $filter');

      // Try the full auction_browse_listings view first
      return await _fetchFromView('auction_browse_listings', filter);
    } catch (e) {
      print(
        '[AuctionRemoteDataSource] Full view failed: $e. Trying fallback view...',
      );
      try {
        // Fallback to simpler view if full view fails
        return await _fetchFromView('auction_browse_simple', filter);
      } catch (e2) {
        print(
          '[AuctionRemoteDataSource] Fallback view also failed: $e2. Trying direct auctions table...',
        );
        // Final fallback: query auctions table directly
        return await _fetchFromAuctionsTable(filter);
      }
    }
  }

  /// Helper method to fetch from a specific view
  Future<List<AuctionModel>> _fetchFromView(
    String viewName,
    AuctionFilter? filter,
  ) async {
    var queryBuilder = _supabaseService.client
        .from(viewName)
        .select(
          'id, title, primary_image_url, vehicle_year, vehicle_make, vehicle_model, current_price, starting_price, watchers_count, total_bids, end_time, seller_id, created_at',
        );

    // Apply search filter on title and description
    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      queryBuilder = queryBuilder.or(
        'title.ilike.%$query%,'
        'description.ilike.%$query%',
      );
    }

    // Price range filtering
    if (filter?.priceMin != null) {
      queryBuilder = queryBuilder.gte('current_price', filter!.priceMin!);
    }
    if (filter?.priceMax != null) {
      queryBuilder = queryBuilder.lte('current_price', filter!.priceMax!);
    }

    // Apply ending soon filter (within 24 hours)
    if (filter?.endingSoon == true) {
      final twentyFourHoursLater = DateTime.now().add(
        const Duration(hours: 24),
      );
      queryBuilder = queryBuilder.lte(
        'end_time',
        twentyFourHoursLater.toIso8601String(),
      );
    }

    // Order by ending soonest first
    final response = await queryBuilder.order('end_time', ascending: true);
    print(
      '[AuctionRemoteDataSource] Fetched ${(response as List).length} auctions from $viewName',
    );

    return (response as List).map((json) {
      return AuctionModel.fromJson({
        'id': json['id'],
        'car_image_url': json['primary_image_url'] ?? '',
        'year': json['vehicle_year'] ?? 0,
        'make': json['vehicle_make'] ?? '',
        'model': json['vehicle_model'] ?? '',
        'current_bid': json['current_price'] ?? json['starting_price'],
        'watchers_count': json['watchers_count'] ?? 0,
        'bidders_count': json['total_bids'] ?? 0,
        'end_time': json['end_time'],
        'seller_id': json['seller_id'],
      });
    }).toList();
  }

  /// Fallback: fetch directly from auctions table
  Future<List<AuctionModel>> _fetchFromAuctionsTable(
    AuctionFilter? filter,
  ) async {
    // Get live status ID
    final statusResponse = await _supabaseService.client
        .from('auction_statuses')
        .select('id')
        .eq('status_name', 'live')
        .single();
    final liveStatusId = statusResponse['id'] as String;

    var queryBuilder = _supabaseService.client
        .from('auctions')
        .select(
          'id, title, description, starting_price, current_price, reserve_price, end_time, total_bids, view_count, seller_id, created_at',
        )
        .eq('status_id', liveStatusId)
        .gt('end_time', DateTime.now().toIso8601String());

    // Apply search filter
    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      queryBuilder = queryBuilder.or(
        'title.ilike.%$query%,'
        'description.ilike.%$query%',
      );
    }

    // Price filtering
    if (filter?.priceMin != null) {
      queryBuilder = queryBuilder.gte('current_price', filter!.priceMin!);
    }
    if (filter?.priceMax != null) {
      queryBuilder = queryBuilder.lte('current_price', filter!.priceMax!);
    }

    final response = await queryBuilder.order('end_time', ascending: true);
    print(
      '[AuctionRemoteDataSource] Fetched ${(response as List).length} auctions from auctions table (fallback)',
    );

    return (response as List).map((json) {
      return AuctionModel.fromJson({
        'id': json['id'],
        'car_image_url': '',
        'year': 0,
        'make': '',
        'model': '',
        'current_bid': json['current_price'] ?? json['starting_price'],
        'watchers_count': 0,
        'bidders_count': json['total_bids'] ?? 0,
        'end_time': json['end_time'],
        'seller_id': json['seller_id'],
      });
    }).toList();
  }

  /// Fetch single auction by ID from browse view
  Future<AuctionModel?> getAuctionById(String id) async {
    try {
      final response = await _supabaseService.client
          .from('auction_browse_listings')
          .select(
            'id, title, primary_image_url, vehicle_year, vehicle_make, vehicle_model, current_price, starting_price, watchers_count, total_bids, end_time, seller_id, created_at',
          )
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return AuctionModel.fromJson({
        'id': response['id'],
        'car_image_url': response['primary_image_url'] ?? '',
        'year': response['vehicle_year'] ?? 0,
        'make': response['vehicle_make'] ?? '',
        'model': response['vehicle_model'] ?? '',
        'current_bid': response['current_price'] ?? response['starting_price'],
        'watchers_count': response['watchers_count'] ?? 0,
        'bidders_count': response['total_bids'] ?? 0,
        'end_time': response['end_time'],
        'seller_id': response['seller_id'],
      });
    } catch (e) {
      throw Exception('Failed to fetch auction: $e');
    }
  }

  /// Search live auctions by title or description
  Future<List<AuctionModel>> searchAuctions(String query) async {
    try {
      final response = await _supabaseService.client
          .from('auction_browse_listings')
          .select(
            'id, title, primary_image_url, vehicle_year, vehicle_make, vehicle_model, current_price, starting_price, watchers_count, total_bids, end_time, seller_id, created_at',
          )
          .gt('end_time', DateTime.now().toIso8601String())
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('end_time', ascending: true);

      return (response as List)
          .map(
            (json) => AuctionModel.fromJson({
              'id': json['id'],
              'car_image_url': json['primary_image_url'] ?? '',
              'year': json['vehicle_year'] ?? 0,
              'make': json['vehicle_make'] ?? '',
              'model': json['vehicle_model'] ?? '',
              'current_bid': json['current_price'] ?? json['starting_price'],
              'watchers_count': json['watchers_count'] ?? 0,
              'bidders_count': json['total_bids'] ?? 0,
              'end_time': json['end_time'],
              'seller_id': json['seller_id'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('Failed to search auctions: $e');
    }
  }
}
