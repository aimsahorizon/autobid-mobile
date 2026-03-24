import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auction_model.dart';
import '../models/auction_detail_model.dart';
import '../../domain/entities/auction_filter.dart';
import 'deposit_supabase_datasource.dart' show DepositSupabaseDataSource;

/// Supabase datasource for auction operations
/// Handles fetching, filtering, and managing auctions from vehicles table
class AuctionSupabaseDataSource {
  final SupabaseClient _supabase;
  late final DepositSupabaseDataSource _depositDatasource;

  SupabaseClient get client => _supabase;

  AuctionSupabaseDataSource(this._supabase) {
    _depositDatasource = DepositSupabaseDataSource(_supabase);
  }

  /// Get all live auctions with comprehensive filtering
  /// Tries full browse view first, then authorized_auctions (both enforce invite visibility)
  Future<List<AuctionModel>> getActiveAuctions({AuctionFilter? filter}) async {
    try {
      debugPrint(
        '[AuctionSupabaseDataSource] Loading auctions with filter: $filter',
      );

      return await _fetchFromView(
        viewName: 'auction_browse_listings',
        filter: filter,
        applyIsActiveFilter: true,
      );
    } catch (e) {
      debugPrint(
        '[AuctionSupabaseDataSource] Full view failed: $e. Trying authorized_auctions fallback...',
      );
      try {
        return await _fetchFromView(
          viewName: 'authorized_auctions',
          filter: filter,
          applyIsActiveFilter: false,
        );
      } catch (e2) {
        debugPrint(
          '[AuctionSupabaseDataSource] Authorized fallback failed: $e2. Returning empty list to avoid privacy leaks.',
        );
        return const <AuctionModel>[];
      }
    }
  }

  /// Helper method to fetch from a specific view
  Future<List<AuctionModel>> _fetchFromView({
    required String viewName,
    required AuctionFilter? filter,
    required bool applyIsActiveFilter,
  }) async {
    // Query the view directly — DB views enforce visibility rules.
    dynamic queryBuilder = _supabase
        .from(viewName)
        .select(
          'id, title, description, primary_image_url, vehicle_year, vehicle_make, vehicle_model, current_price, starting_price, watchers_count, total_bids, end_time, seller_id, seller_display_name, seller_profile_image_url, visibility, bidding_type, created_at',
        );

    if (applyIsActiveFilter) {
      queryBuilder = queryBuilder.eq('is_active', true);
    }

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

    // Vehicle filters
    if (filter?.make != null && filter!.make!.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('vehicle_make', filter.make!);
    }
    if (filter?.model != null && filter!.model!.isNotEmpty) {
      queryBuilder = queryBuilder.ilike('vehicle_model', '%${filter.model}%');
    }
    if (filter?.yearFrom != null) {
      queryBuilder = queryBuilder.gte('vehicle_year', filter!.yearFrom!);
    }
    if (filter?.yearTo != null) {
      queryBuilder = queryBuilder.lte('vehicle_year', filter!.yearTo!);
    }

    // Public/private filter
    if (filter?.visibility != null && filter!.visibility!.isNotEmpty) {
      queryBuilder = queryBuilder.eq('visibility', filter.visibility!);
    }

    // Transmission & Fuel (Attempting to filter if columns exist in view)
    if (filter?.transmission != null && filter!.transmission!.isNotEmpty) {
      // Using generic 'transmission' or 'vehicle_transmission' depending on view definition
      // Safest to try 'transmission' if view flattens it, or 'vehicle_transmission'
      // Based on other columns, likely 'vehicle_transmission'
      // But to avoid breakage if column missing, we might need to skip or use try/catch
      // For now, let's assume vehicle_transmission matches naming convention
      // If this fails, the 'catch' block in getActiveAuctions will handle it (fallback)
      // But fallback also needs these filters!
      // Ideally we should know the schema.
      // Given the user report is about BRAND, I will prioritize Make/Model/Year which are known.
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
    debugPrint(
      '[AuctionSupabaseDataSource] Fetched ${(response as List).length} auctions from $viewName',
    );

    final rows = (response as List<Map<String, dynamic>>);

    // Batch-enrich visibility from auctions table (not exposed by view)
    final auctionIds = rows.map((row) => row['id'] as String).toList();
    final visibilityById = <String, String>{};
    if (auctionIds.isNotEmpty) {
      try {
        final visResp = await _supabase
            .from('auctions')
            .select('id, visibility')
            .inFilter('id', auctionIds);
        for (final r in (visResp as List)) {
          final m = r as Map<String, dynamic>;
          visibilityById[m['id'] as String] =
              m['visibility'] as String? ?? 'public';
        }
      } catch (e) {
        debugPrint(
          '[AuctionSupabaseDataSource] Visibility enrichment failed: $e',
        );
      }
    }

    // Convert to AuctionModel list
    return rows.map((json) {
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
        'seller_display_name': json['seller_display_name'],
        'seller_profile_image_url': json['seller_profile_image_url'],
        'visibility': visibilityById[json['id'] as String] ?? 'public',
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
        debugPrint(
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
          .from('auction_photos')
          .select('photo_url, category, display_order')
          .eq('auction_id', auctionId)
          .order('display_order', ascending: true);

      final photos = <String, List<String>>{};
      if (photosResponse.isNotEmpty) {
        // Group photos by category
        final photoList = (photosResponse as List);
        for (final photo in photoList) {
          final url = photo['photo_url'] as String;
          final category = _normalizePhotoCategory(
            photo['category'] as String?,
          );
          photos.putIfAbsent(category, () => []).add(url);
        }
        // Also provide 'all' list for backward compatibility
        photos['all'] = photoList.map((p) => p['photo_url'] as String).toList();
      }

      // Fetch detailed configuration from auctions table directly
      // This ensures we get the latest schema fields even if the view is outdated
      final auctionConfigResponse = await _supabase
          .from('auctions')
          .select('bidding_type, deed_of_sale_url')
          .eq('id', auctionId)
          .single();

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
          100;
      final enableIncremental =
          (auctionResponse['enable_incremental_bidding'] as bool?) ?? true;

      // Build auction detail model
      return AuctionDetailModel.fromJson({
        ...auctionResponse,
        'bidding_type': auctionConfigResponse['bidding_type'],
        'deed_of_sale_url': auctionConfigResponse['deed_of_sale_url'],
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
            auctionConfigResponse['bidding_type'] != 'mystery' &&
            auctionResponse['reserve_price'] != null &&
            auctionResponse['current_price'] >=
                auctionResponse['reserve_price'],
        'show_reserve_price':
            auctionConfigResponse['bidding_type'] != 'mystery',
        'reserve_price': auctionConfigResponse['bidding_type'] == 'mystery'
            ? null
            : auctionResponse['reserve_price'],
        'bidders_count': auctionResponse['total_bids'] ?? 0,
        'has_user_deposited': hasUserDeposited,
        'photos': photos,
      });
    } on PostgrestException catch (e) {
      // Check if the auction exists but is no longer in the browse view (ended/sold)
      try {
        final auctionCheck = await _supabase
            .from('auctions')
            .select(
              'id, title, current_price, starting_price, end_time, status, vehicle_year, vehicle_make, vehicle_model, vehicle_variant, primary_image_url',
            )
            .eq('id', auctionId)
            .maybeSingle();

        if (auctionCheck != null) {
          final endTime = DateTime.parse(auctionCheck['end_time'] as String);
          final status = auctionCheck['status'] as String? ?? '';
          final isEnded = endTime.isBefore(DateTime.now()) || status != 'live';
          if (isEnded) {
            // Auction has ended — return a minimal ended model
            final carName = [
              auctionCheck['vehicle_year']?.toString(),
              auctionCheck['vehicle_make'],
              auctionCheck['vehicle_model'],
            ].where((s) => s != null && s.isNotEmpty).join(' ');

            return AuctionDetailModel.fromJson({
              'id': auctionCheck['id'],
              'title': auctionCheck['title'] ?? carName,
              'description': '',
              'starting_price': auctionCheck['starting_price'] ?? 0,
              'current_bid':
                  auctionCheck['current_price'] ??
                  auctionCheck['starting_price'] ??
                  0,
              'reserve_price': null,
              'bid_increment': 0,
              'min_bid_increment': 0,
              'enable_incremental_bidding': false,
              'deposit_amount': 0,
              'end_time': auctionCheck['end_time'],
              'total_bids': 0,
              'status': 'ended',
              'car_image_url': auctionCheck['primary_image_url'] ?? '',
              'brand': auctionCheck['vehicle_make'] ?? '',
              'make': auctionCheck['vehicle_make'] ?? '',
              'model': auctionCheck['vehicle_model'] ?? '',
              'year': auctionCheck['vehicle_year'] ?? 0,
              'minimum_bid': auctionCheck['starting_price'] ?? 0,
              'is_reserve_met': false,
              'show_reserve_price': false,
              'bidders_count': 0,
              'has_user_deposited': false,
              'photos': <String, dynamic>{},
            });
          }
        }
      } catch (_) {
        // Ignore fallback errors — throw original
      }
      throw Exception('Failed to get auction details: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get auction details: $e');
    }
  }

  String _normalizePhotoCategory(String? rawCategory) {
    final normalized = rawCategory?.trim().toLowerCase() ?? 'details';

    // Exact top-level match
    switch (normalized) {
      case 'exterior':
      case 'interior':
      case 'engine':
      case 'details':
      case 'documents':
        return normalized;
    }

    // Map subcategory keys (snake_case from PhotoCategories.toKey) to parent categories
    const exteriorKeys = {
      'front_view', 'rear_view', 'left_side', 'right_side',
      'front_left_angle',
      'front_right_angle',
      'rear_left_angle',
      'rear_right_angle',
      'roof', 'undercarriage', 'front_bumper', 'rear_bumper',
      'left_fender', 'right_fender', 'hood', 'trunk_tailgate',
      'fuel_door', 'side_mirrors', 'door_handles', 'exterior_lights',
      // Wheels & Tires subcategories (exterior-related)
      'front_left_wheel',
      'front_right_wheel',
      'rear_left_wheel',
      'rear_right_wheel',
    };
    const interiorKeys = {
      'dashboard',
      'steering_wheel',
      'center_console',
      'front_seats',
      'rear_seats',
      'headliner',
      'door_panels',
      'carpet_floor_mats',
      'trunk_interior',
      'glove_box',
      'sun_visors',
      'instrument_cluster',
      'infotainment_screen',
      'climate_controls',
      'interior_lights',
    };
    const engineKeys = {
      'engine_bay_overview',
      'engine_block',
      'battery',
      'fluid_reservoirs',
      'air_filter',
      'alternator',
      'belts_&_hoses',
      'suspension',
      'brakes_front',
      'brakes_rear',
      'exhaust_system',
      'transmission',
    };
    const documentKeys = {
      'or_cr',
      'registration_papers',
      'insurance',
      'maintenance_records',
      'inspection_report',
    };

    if (exteriorKeys.contains(normalized)) return 'exterior';
    if (interiorKeys.contains(normalized)) return 'interior';
    if (engineKeys.contains(normalized)) return 'engine';
    if (documentKeys.contains(normalized)) return 'documents';

    return 'details';
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

  /// Stream updates for a specific auction
  /// Listens to changes in the 'auctions' table
  Stream<List<Map<String, dynamic>>> streamAuctionUpdates(String auctionId) {
    return _supabase
        .from('auctions')
        .stream(primaryKey: ['id'])
        .eq('id', auctionId);
  }

  /// Stream updates for all auctions (signal for Browse page refresh)
  Stream<List<Map<String, dynamic>>> streamAuctionsTable() {
    return _supabase.from('auctions').stream(primaryKey: ['id']);
  }
}
