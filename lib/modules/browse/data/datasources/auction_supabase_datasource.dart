import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auction_model.dart';
import '../models/auction_detail_model.dart';
import '../../domain/entities/auction_filter.dart';
import 'deposit_supabase_datasource.dart' show DepositSupabaseDatasource;

/// Supabase datasource for auction operations
/// Handles fetching, filtering, and managing auctions from vehicles table
class AuctionSupabaseDataSource {
  final SupabaseClient _supabase;
  late final DepositSupabaseDatasource _depositDatasource;

  SupabaseClient get client => _supabase;

  AuctionSupabaseDataSource(this._supabase) {
    _depositDatasource = DepositSupabaseDatasource(supabase: _supabase);
  }

  /// Get all live auctions with comprehensive filtering
  /// Tries full browse view first, falls back to simple view, then direct auctions table
  Future<List<AuctionModel>> getActiveAuctions({AuctionFilter? filter}) async {
    try {
      print(
        '[AuctionSupabaseDataSource] Loading auctions with filter: $filter',
      );

      // Try the full auction_browse_listings view first
      return await _fetchFromView('auction_browse_listings', filter);
    } catch (e) {
      print(
        '[AuctionSupabaseDataSource] Full view failed: $e. Trying fallback view...',
      );
      try {
        // Fallback to simpler view if full view fails
        return await _fetchFromView('auction_browse_simple', filter);
      } catch (e2) {
        print(
          '[AuctionSupabaseDataSource] Fallback view also failed: $e2. Trying direct auctions table...',
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
    // Use authorized_auctions when available to respect private auction visibility
    final source = viewName == 'auction_browse_listings'
        ? 'authorized_auctions'
        : viewName;

    var queryBuilder = _supabase
        .from(source)
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
      '[AuctionSupabaseDataSource] Fetched ${(response as List).length} auctions from $source',
    );

    // Convert to AuctionModel list
    return (response as List).map((json) {
      return AuctionModel.fromJson({
        'id': json['id'],
        'car_image_url': json['primary_image_url'] ?? '',
        'year': json['vehicle_year'] ?? 0,
        'make': json['vehicle_make'] ?? '',
        'model': json['vehicle_model'] ?? '',
        'title': json['title'] ?? '',
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
    final statusResponse = await _supabase
        .from('auction_statuses')
        .select('id')
        .eq('status_name', 'live')
        .single();
    final liveStatusId = statusResponse['id'] as String;

    var queryBuilder = _supabase
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
      '[AuctionSupabaseDataSource] Fetched ${(response as List).length} auctions from auctions table (fallback)',
    );

    return (response as List).map((json) {
      return AuctionModel.fromJson({
        'id': json['id'],
        'car_image_url': '',
        'year': 0,
        // Fall back to title so cards show a meaningful name if vehicle metadata is missing
        'make': (json['title'] as String?) ?? '',
        'model': '',
        'title': json['title'] ?? '',
        'current_bid': json['current_price'] ?? json['starting_price'],
        'watchers_count': 0,
        'bidders_count': json['total_bids'] ?? 0,
        'end_time': json['end_time'],
        'seller_id': json['seller_id'],
      });
    }).toList();
  }

  /// Get auction details by ID for live auctions
  /// Fetches from auction_browse_listings view with all related data
  Future<AuctionDetailModel> getAuctionDetail(
    String auctionId,
    String? userId,
  ) async {
    try {
      // Get auction details from view
      Map<String, dynamic> auctionResponse;
      try {
        // Try selecting with new fields (min_bid_increment, enable_incremental_bidding)
        auctionResponse = await _supabase
            .from('auction_browse_listings')
            .select(
              'id, title, description, starting_price, current_price, reserve_price, bid_increment, min_bid_increment, enable_incremental_bidding, deposit_amount, end_time, total_bids, view_count, is_featured, seller_id, created_at, start_time, vehicle_year, vehicle_make, vehicle_model, vehicle_variant, primary_image_url',
            )
            .eq('id', auctionId)
            .single();
      } on PostgrestException catch (e) {
        // Fallback: older view may not have new columns; re-query without them
        print(
          '[AuctionSupabaseDataSource] Fallback select without min/enable columns due to: ${e.message}',
        );
        auctionResponse = await _supabase
            .from('auction_browse_listings')
            .select(
              'id, title, description, starting_price, current_price, reserve_price, bid_increment, deposit_amount, end_time, total_bids, view_count, is_featured, seller_id, created_at, start_time, vehicle_year, vehicle_make, vehicle_model, vehicle_variant, primary_image_url',
            )
            .eq('id', auctionId)
            .single();
      }

      // Fetch the associated vehicle specs similar to the Lists module implementation
      final vehicleResponse = await _supabase
          .from('auction_vehicles')
          .select('''
            brand, model, variant, year,
            engine_type, engine_displacement, cylinder_count, horsepower, torque,
            transmission, fuel_type, drive_type,
            length, width, height, wheelbase, ground_clearance,
            seating_capacity, door_count, fuel_tank_capacity, curb_weight, gross_weight,
            exterior_color, paint_type, rim_type, rim_size, tire_size, tire_brand,
            condition, mileage, previous_owners, has_modifications, modifications_details,
            has_warranty, warranty_details, usage_type,
            plate_number, orcr_status, registration_status, registration_expiry,
            province, city_municipality,
            known_issues, features
            ''')
          .eq('auction_id', auctionId)
          .maybeSingle();

      final vehicleData = vehicleResponse == null
          ? null
          : Map<String, dynamic>.from(vehicleResponse as Map);

      // Get all photos for the auction
      final photosResponse = await _supabase
          .from('auction_images')
          .select('image_url, display_order')
          .eq('auction_id', auctionId)
          .order('display_order', ascending: true);

      final photos = <String, List<String>>{};
      if (photosResponse.isNotEmpty) {
        photos['all'] = (photosResponse as List)
            .map((p) => p['image_url'] as String)
            .toList();
      }

      // Check if user has deposited (if logged in)
      bool hasUserDeposited = false;
      if (userId != null) {
        hasUserDeposited = await _depositDatasource.hasUserDeposited(
          auctionId: auctionId,
          userId: userId,
        );
      }

      // Compute safe defaults for new fields if missing
      final numBidIncrement =
          (auctionResponse['min_bid_increment'] as num?) ??
          (auctionResponse['bid_increment'] as num?) ??
          1000;
      final enableIncremental =
          (auctionResponse['enable_incremental_bidding'] as bool?) ?? true;

      // Build auction detail model
      return AuctionDetailModel.fromJson({
        ...auctionResponse,
        'car_image_url': auctionResponse['primary_image_url'] ?? '',
        // Map database current_price to model's current_bid
        'current_bid':
            auctionResponse['current_price'] ??
            auctionResponse['starting_price'],
        // Ensure required fields exist for model parsing
        'min_bid_increment': numBidIncrement,
        'enable_incremental_bidding': enableIncremental,
        'brand': vehicleData?['brand'] ?? auctionResponse['vehicle_make'] ?? '',
        'make': vehicleData?['brand'] ?? auctionResponse['vehicle_make'] ?? '',
        'model':
            vehicleData?['model'] ?? auctionResponse['vehicle_model'] ?? '',
        'year': vehicleData?['year'] ?? auctionResponse['vehicle_year'] ?? 0,
        'variant':
            vehicleData?['variant'] ?? auctionResponse['vehicle_variant'],
        'engine_type': vehicleData?['engine_type'],
        'engine_displacement': vehicleData?['engine_displacement'],
        'cylinder_count': vehicleData?['cylinder_count'],
        'horsepower': vehicleData?['horsepower'],
        'torque': vehicleData?['torque'],
        'transmission': vehicleData?['transmission'],
        'fuel_type': vehicleData?['fuel_type'],
        'drive_type': vehicleData?['drive_type'],
        'length': vehicleData?['length'],
        'width': vehicleData?['width'],
        'height': vehicleData?['height'],
        'wheelbase': vehicleData?['wheelbase'],
        'ground_clearance': vehicleData?['ground_clearance'],
        'seating_capacity': vehicleData?['seating_capacity'],
        'door_count': vehicleData?['door_count'],
        'fuel_tank_capacity': vehicleData?['fuel_tank_capacity'],
        'curb_weight': vehicleData?['curb_weight'],
        'gross_weight': vehicleData?['gross_weight'],
        'exterior_color': vehicleData?['exterior_color'],
        'paint_type': vehicleData?['paint_type'],
        'rim_type': vehicleData?['rim_type'],
        'rim_size': vehicleData?['rim_size'],
        'tire_size': vehicleData?['tire_size'],
        'tire_brand': vehicleData?['tire_brand'],
        'condition': vehicleData?['condition'],
        'mileage': vehicleData?['mileage'],
        'previous_owners': vehicleData?['previous_owners'],
        'has_modifications': vehicleData?['has_modifications'],
        'modifications_details': vehicleData?['modifications_details'],
        'has_warranty': vehicleData?['has_warranty'],
        'warranty_details': vehicleData?['warranty_details'],
        'usage_type': vehicleData?['usage_type'],
        'plate_number': vehicleData?['plate_number'],
        'orcr_status': vehicleData?['orcr_status'],
        'registration_status': vehicleData?['registration_status'],
        'registration_expiry': vehicleData?['registration_expiry'],
        'province': vehicleData?['province'],
        'city_municipality': vehicleData?['city_municipality'],
        'known_issues': vehicleData?['known_issues'],
        'features': vehicleData?['features'],
        'minimum_bid': auctionResponse['starting_price'],
        'end_time': auctionResponse['end_time'],
        'is_reserve_met':
            auctionResponse['reserve_price'] != null &&
            auctionResponse['current_price'] >=
                auctionResponse['reserve_price'],
        'show_reserve_price': true,
        'bidders_count': auctionResponse['total_bids'] ?? 0,
        'has_user_deposited': hasUserDeposited,
        'photos': photos,
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
      await _supabase.rpc(
        'increment_watchers',
        params: {'listing_id': auctionId},
      );
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
      await _supabase.rpc(
        'decrement_watchers',
        params: {'listing_id': auctionId},
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to unwatch auction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to unwatch auction: $e');
    }
  }
}
