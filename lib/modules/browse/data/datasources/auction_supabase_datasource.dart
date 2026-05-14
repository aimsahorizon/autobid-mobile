import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/modules/browse/data/models/auction_model.dart';
import 'package:autobid_mobile/modules/browse/data/models/auction_detail_model.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_filter.dart';
import 'package:autobid_mobile/modules/browse/data/datasources/deposit_supabase_datasource.dart'
    show DepositSupabaseDataSource;

/// Supabase datasource for auction operations
/// Handles fetching, filtering, and managing auctions from vehicles table
class AuctionSupabaseDataSource {
  final SupabaseClient _supabase;
  late final DepositSupabaseDataSource _depositDatasource;

  SupabaseClient get client => _supabase;

  AuctionSupabaseDataSource(this._supabase) {
    _depositDatasource = DepositSupabaseDataSource(_supabase);
  }

  /// Get all live auctions with comprehensive filtering.
  /// Fallback order:
  /// 1) auction_browse_listings
  /// 2) auction_browse_simple
  /// 3) authorized_auctions
  /// 4) auctions table (live + not ended)
  Future<List<AuctionModel>> getActiveAuctions({AuctionFilter? filter}) async {
    Future<List<AuctionModel>> run(
      Future<List<AuctionModel>> Function() loader,
      String label,
    ) async {
      try {
        final rows = await loader();
        debugPrint(
          '[AuctionSupabaseDataSource] $label returned ${rows.length} auctions',
        );
        return rows;
      } catch (e) {
        debugPrint('[AuctionSupabaseDataSource] $label failed: $e');
        return const <AuctionModel>[];
      }
    }

    debugPrint(
      '[AuctionSupabaseDataSource] Loading auctions with filter: $filter',
    );

    final browseListings = await run(
      () => _fetchFromView(
        viewName: 'auction_browse_listings',
        filter: filter,
        applyIsActiveFilter: false,
      ),
      'auction_browse_listings',
    );
    // When a visibility/type filter is active, a 0-result response is correct
    // (means no matching auctions). Do NOT fall back — fallbacks return all types.
    final hasVisibilityFilter =
        (filter?.auctionType != null && filter!.auctionType!.isNotEmpty) ||
        (filter?.visibility != null && filter!.visibility!.isNotEmpty);
    if (browseListings.isNotEmpty || hasVisibilityFilter) return browseListings;

    final browseSimple = await run(
      () => _fetchFromView(
        viewName: 'auction_browse_simple',
        filter: filter,
        applyIsActiveFilter: false,
      ),
      'auction_browse_simple',
    );
    if (browseSimple.isNotEmpty) return browseSimple;

    final authorized = await run(
      () => _fetchFromAuthorizedAuctions(filter: filter),
      'authorized_auctions',
    );
    if (authorized.isNotEmpty) return authorized;

    return run(() => _fetchFromAuctionsTable(filter: filter), 'auctions_table');
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
          'id, title, description, primary_image_url, vehicle_year, vehicle_make,'
          ' vehicle_model, current_price, starting_price, watchers_count, total_bids,'
          ' end_time, seller_id, seller_display_name, seller_profile_image_url,'
          ' visibility, bidding_type, created_at',
        );

    if (applyIsActiveFilter) {
      queryBuilder = queryBuilder.eq('is_active', true);
    }

    // Apply search filter on title and description
    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      queryBuilder = queryBuilder.or(
        'title.ilike.%$query%,description.ilike.%$query%',
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
      queryBuilder = queryBuilder.ilike('vehicle_make', '%${filter.make}%');
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
    // Auction type → visibility column ('open', 'exclusive', 'mystery')
    if (filter?.auctionType != null && filter!.auctionType!.isNotEmpty) {
      queryBuilder = queryBuilder.eq('visibility', filter.auctionType!);
    } else if (filter?.visibility != null && filter!.visibility!.isNotEmpty) {
      // Legacy visibility filter — only apply if no auctionType is set
      queryBuilder = queryBuilder.eq('visibility', filter.visibility!);
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

    var rows = response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    // --- Vehicle-specific post-filter (transmission/fuel/condition etc.) ---
    // These columns are not in the browse view, so we batch-query auction_vehicles
    // for the fetched auction IDs and keep only matching rows.
    final needsVehicleFilter =
        (filter?.transmission != null && filter!.transmission!.isNotEmpty) ||
        (filter?.fuelType != null && filter!.fuelType!.isNotEmpty) ||
        (filter?.driveType != null && filter!.driveType!.isNotEmpty) ||
        (filter?.condition != null && filter!.condition!.isNotEmpty) ||
        filter?.maxMileage != null ||
        (filter?.exteriorColor != null && filter!.exteriorColor!.isNotEmpty) ||
        (filter?.province != null && filter!.province!.isNotEmpty) ||
        (filter?.city != null && filter!.city!.isNotEmpty);

    if (needsVehicleFilter && rows.isNotEmpty) {
      final ids = rows
          .map((r) => r['id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toList();
      try {
        dynamic vq = _supabase
            .from('auction_vehicles')
            .select('auction_id')
            .inFilter('auction_id', ids);
        if (filter!.transmission != null && filter.transmission!.isNotEmpty) {
          vq = vq.ilike('transmission', '%${filter.transmission}%');
        }
        if (filter.fuelType != null && filter.fuelType!.isNotEmpty) {
          vq = vq.ilike('fuel_type', '%${filter.fuelType}%');
        }
        if (filter.driveType != null && filter.driveType!.isNotEmpty) {
          vq = vq.ilike('drive_type', '%${filter.driveType}%');
        }
        if (filter.condition != null && filter.condition!.isNotEmpty) {
          vq = vq.ilike('condition', '%${filter.condition}%');
        }
        if (filter.maxMileage != null) {
          vq = vq.lte('mileage', filter.maxMileage!);
        }
        if (filter.exteriorColor != null && filter.exteriorColor!.isNotEmpty) {
          vq = vq.ilike('exterior_color', '%${filter.exteriorColor}%');
        }
        if (filter.province != null && filter.province!.isNotEmpty) {
          vq = vq.ilike('province', '%${filter.province}%');
        }
        if (filter.city != null && filter.city!.isNotEmpty) {
          vq = vq.ilike('city_municipality', '%${filter.city}%');
        }
        final vResp = await vq;
        final matchIds = (vResp as List)
            .map((r) => (r as Map)['auction_id']?.toString())
            .whereType<String>()
            .toSet();
        rows = rows
            .where((r) => matchIds.contains(r['id']?.toString()))
            .toList();
      } catch (e) {
        debugPrint(
          '[AuctionSupabaseDataSource] Vehicle post-filter failed: $e',
        );
      }
    }

    // Convert to AuctionModel list
    final models = <AuctionModel>[];
    for (final json in rows) {
      try {
        final id = json['id']?.toString() ?? '';
        models.add(
          AuctionModel.fromJson({
            'id': id,
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
            'visibility': json['visibility'] ?? 'open',
          }),
        );
      } catch (e) {
        debugPrint(
          '[AuctionSupabaseDataSource] Skipping malformed view row: $e',
        );
      }
    }
    return models;
  }

  Future<List<AuctionModel>> _fetchFromAuthorizedAuctions({
    required AuctionFilter? filter,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    dynamic queryBuilder = _supabase
        .from('authorized_auctions')
        .select(
          'id, title, description, current_price, starting_price, end_time, total_bids, seller_id, visibility',
        )
        .or('end_time.gt.$nowIso,end_time.is.null');

    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      queryBuilder = queryBuilder.or(
        'title.ilike.%$query%,description.ilike.%$query%',
      );
    }

    if (filter?.priceMin != null) {
      queryBuilder = queryBuilder.gte('current_price', filter!.priceMin!);
    }
    if (filter?.priceMax != null) {
      queryBuilder = queryBuilder.lte('current_price', filter!.priceMax!);
    }

    // auctionType maps to the visibility column ('open'/'exclusive'/'mystery')
    if (filter?.auctionType != null && filter!.auctionType!.isNotEmpty) {
      queryBuilder = queryBuilder.eq('visibility', filter.auctionType!);
    } else if (filter?.visibility != null && filter!.visibility!.isNotEmpty) {
      queryBuilder = queryBuilder.eq('visibility', filter.visibility!);
    }

    if (filter?.endingSoon == true) {
      final twentyFourHoursLater = DateTime.now().add(
        const Duration(hours: 24),
      );
      queryBuilder = queryBuilder.lte(
        'end_time',
        twentyFourHoursLater.toIso8601String(),
      );
    }

    final response = await queryBuilder.order('end_time', ascending: true);
    final rows = response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    final models = <AuctionModel>[];
    for (final json in rows) {
      try {
        models.add(
          AuctionModel.fromJson({
            'id': json['id'],
            'title': json['title'] ?? '',
            'car_image_url': '',
            'year': 0,
            'make': '',
            'model': '',
            'current_bid': json['current_price'] ?? json['starting_price'] ?? 0,
            'watchers_count': 0,
            'bidders_count': json['total_bids'] ?? 0,
            'end_time': json['end_time'],
            'seller_id': json['seller_id'],
            'visibility': json['visibility'] ?? 'public',
          }),
        );
      } catch (e) {
        debugPrint(
          '[AuctionSupabaseDataSource] Skipping malformed authorized row: $e',
        );
      }
    }
    return models;
  }

  Future<List<AuctionModel>> _fetchFromAuctionsTable({
    required AuctionFilter? filter,
  }) async {
    List<dynamic> statusRows = const [];
    try {
      statusRows = await _supabase
          .from('auction_statuses')
          .select('id,status_name')
          .inFilter('status_name', [
            'live',
            'active',
            'scheduled',
            'ongoing',
            'in_progress',
          ]);
    } catch (_) {
      statusRows = const [];
    }

    final allowedStatusIds = statusRows
        .map((row) => (row as Map<String, dynamic>)['id'])
        .whereType<String>()
        .toList();
    dynamic queryBuilder = _supabase
        .from('auctions')
        .select(
          'id, title, description, starting_price, current_price, end_time, total_bids, seller_id, visibility',
        );

    if (allowedStatusIds.isNotEmpty) {
      queryBuilder = queryBuilder.inFilter('status_id', allowedStatusIds);
    }

    if (filter?.searchQuery != null && filter!.searchQuery!.isNotEmpty) {
      final query = filter.searchQuery!.toLowerCase();
      queryBuilder = queryBuilder.or(
        'title.ilike.%$query%,description.ilike.%$query%',
      );
    }

    if (filter?.priceMin != null) {
      queryBuilder = queryBuilder.gte('current_price', filter!.priceMin!);
    }
    if (filter?.priceMax != null) {
      queryBuilder = queryBuilder.lte('current_price', filter!.priceMax!);
    }

    // auctionType maps to the visibility column ('open'/'exclusive'/'mystery')
    if (filter?.auctionType != null && filter!.auctionType!.isNotEmpty) {
      queryBuilder = queryBuilder.eq('visibility', filter.auctionType!);
    } else if (filter?.visibility != null && filter!.visibility!.isNotEmpty) {
      queryBuilder = queryBuilder.eq('visibility', filter.visibility!);
    }

    if (filter?.endingSoon == true) {
      final twentyFourHoursLater = DateTime.now().add(
        const Duration(hours: 24),
      );
      queryBuilder = queryBuilder.lte(
        'end_time',
        twentyFourHoursLater.toIso8601String(),
      );
    }

    final response = await queryBuilder.order('end_time', ascending: true);
    final rows = response
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();

    final models = <AuctionModel>[];
    for (final json in rows) {
      try {
        models.add(
          AuctionModel.fromJson({
            'id': json['id'],
            'title': json['title'] ?? '',
            'car_image_url': '',
            'year': 0,
            'make': '',
            'model': '',
            'current_bid': json['current_price'] ?? json['starting_price'] ?? 0,
            'watchers_count': 0,
            'bidders_count': json['total_bids'] ?? 0,
            'end_time': json['end_time'],
            'seller_id': json['seller_id'],
            'visibility': json['visibility'] ?? 'public',
          }),
        );
      } catch (e) {
        debugPrint(
          '[AuctionSupabaseDataSource] Skipping malformed auctions row: $e',
        );
      }
    }
    return models;
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

      const vehicleDetailSelect = '''
            brand, model, variant, year,
            engine_type, engine_displacement, cylinder_count, horsepower, torque,
            transmission, fuel_type, drive_type,
            length, width, height, wheelbase, ground_clearance,
            seating_capacity, door_count, fuel_tank_capacity, curb_weight, gross_weight,
            exterior_color, paint_type, rim_type, rim_size, tire_size, tire_brand,
            condition, mileage, previous_owners, has_modifications, modifications_details,
            has_warranty, warranty_details, usage_type,
            plate_number, chassis_number, orcr_status, registration_status, registration_expiry,
            province, city_municipality,
            known_issues, features
            ''';

      // Fetch the associated vehicle specs similar to the Lists module implementation
      final vehicleResponse = await _supabase
          .from('auction_vehicles')
          .select(vehicleDetailSelect)
          .eq('auction_id', auctionId)
          .maybeSingle();

      Map<String, dynamic>? vehicleData = vehicleResponse == null
          ? null
          : Map<String, dynamic>.from(vehicleResponse as Map);

      // Match list-module robustness: if direct select returns null, try joined fetch from auctions.
      if (vehicleData == null) {
        try {
          final joinedAuction = await _supabase
              .from('auctions')
              .select('auction_vehicles($vehicleDetailSelect)')
              .eq('id', auctionId)
              .maybeSingle();

          final joinedVehicle = joinedAuction?['auction_vehicles'];
          if (joinedVehicle is List && joinedVehicle.isNotEmpty) {
            vehicleData = Map<String, dynamic>.from(joinedVehicle.first as Map);
          } else if (joinedVehicle is Map<String, dynamic>) {
            vehicleData = Map<String, dynamic>.from(joinedVehicle);
          }
        } catch (_) {
          // Keep null if joined fallback fails.
        }
      }

      // Transaction-context fallback: some RLS policies allow auction_vehicles only
      // through the current user's auction_transactions relationship.
      if (vehicleData == null && userId != null && userId.isNotEmpty) {
        try {
          final txnScoped = await _supabase
              .from('auction_transactions')
              .select(
                'auctions!auction_id(auction_vehicles($vehicleDetailSelect))',
              )
              .eq('auction_id', auctionId)
              .or('seller_id.eq.$userId,buyer_id.eq.$userId')
              .limit(1)
              .maybeSingle();

          final txnAuction = txnScoped?['auctions'];
          final txnVehicle = txnAuction is Map<String, dynamic>
              ? txnAuction['auction_vehicles']
              : null;

          if (txnVehicle is List && txnVehicle.isNotEmpty) {
            vehicleData = Map<String, dynamic>.from(txnVehicle.first as Map);
          } else if (txnVehicle is Map<String, dynamic>) {
            vehicleData = Map<String, dynamic>.from(txnVehicle);
          }
        } catch (_) {
          // Keep null if transaction-scoped fallback fails.
        }
      }

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
      // Auction not in browse view (ended/in_transaction/sold/deal_failed).
      // Build a full detail model from direct table queries.
      try {
        final auctionCheck = await _supabase
            .from('auctions')
            .select(
              'id, title, description, current_price, starting_price, reserve_price, bid_increment, min_bid_increment, enable_incremental_bidding, deposit_amount, end_time, start_time, total_bids, view_count, is_featured, seller_id, status_id, bidding_type, deed_of_sale_url, created_at',
            )
            .eq('id', auctionId)
            .maybeSingle();

        if (auctionCheck != null) {
          // Resolve status name from status_id
          String statusName = 'ended';
          try {
            final statusRow = await _supabase
                .from('auction_statuses')
                .select('status_name')
                .eq('id', auctionCheck['status_id'])
                .single();
            statusName = statusRow['status_name'] as String? ?? 'ended';
          } catch (_) {}

          final isEnded = statusName != 'live';
          if (isEnded) {
            // Fetch vehicle data
            Map<String, dynamic>? vehicleData;
            try {
              const fallbackVehicleSelect = '''
                  brand, model, variant, year,
                  engine_type, engine_displacement, cylinder_count, horsepower, torque,
                  transmission, fuel_type, drive_type,
                  length, width, height, wheelbase, ground_clearance,
                  seating_capacity, door_count, fuel_tank_capacity, curb_weight, gross_weight,
                  exterior_color, paint_type, rim_type, rim_size, tire_size, tire_brand,
                  condition, mileage, previous_owners, has_modifications, modifications_details,
                  has_warranty, warranty_details, usage_type,
                  plate_number, chassis_number, orcr_status, registration_status, registration_expiry,
                  province, city_municipality,
                  known_issues, features
                  ''';

              final vResp = await _supabase
                  .from('auction_vehicles')
                  .select(fallbackVehicleSelect)
                  .eq('auction_id', auctionId)
                  .maybeSingle();
              if (vResp != null) vehicleData = Map<String, dynamic>.from(vResp);
            } catch (_) {}

            if (vehicleData == null && userId != null && userId.isNotEmpty) {
              try {
                final txnScoped = await _supabase
                    .from('auction_transactions')
                    .select('auctions!auction_id(auction_vehicles(*))')
                    .eq('auction_id', auctionId)
                    .or('seller_id.eq.$userId,buyer_id.eq.$userId')
                    .limit(1)
                    .maybeSingle();

                final txnAuction = txnScoped?['auctions'];
                final txnVehicle = txnAuction is Map<String, dynamic>
                    ? txnAuction['auction_vehicles']
                    : null;

                if (txnVehicle is List && txnVehicle.isNotEmpty) {
                  vehicleData = Map<String, dynamic>.from(
                    txnVehicle.first as Map,
                  );
                } else if (txnVehicle is Map<String, dynamic>) {
                  vehicleData = Map<String, dynamic>.from(txnVehicle);
                }
              } catch (_) {}
            }

            // Fetch photos
            final photos = <String, List<String>>{};
            try {
              final pResp = await _supabase
                  .from('auction_photos')
                  .select('photo_url, category, display_order')
                  .eq('auction_id', auctionId)
                  .order('display_order', ascending: true);
              if (pResp.isNotEmpty) {
                for (final photo in pResp) {
                  final url = photo['photo_url'] as String;
                  final category = _normalizePhotoCategory(
                    photo['category'] as String?,
                  );
                  photos.putIfAbsent(category, () => []).add(url);
                }
                photos['all'] = pResp
                    .map((p) => p['photo_url'] as String)
                    .toList();
              }
            } catch (_) {}

            // Primary image
            String primaryImage = '';
            if (photos['all'] != null && photos['all']!.isNotEmpty) {
              primaryImage = photos['all']!.first;
            }

            // Check deposit
            bool hasUserDeposited = false;
            if (userId != null) {
              try {
                hasUserDeposited = await _depositDatasource.hasUserDeposited(
                  auctionId: auctionId,
                  userId: userId,
                );
              } catch (_) {}
            }

            final numBidIncrement =
                (auctionCheck['min_bid_increment'] as num?) ??
                (auctionCheck['bid_increment'] as num?) ??
                100;
            final biddingType =
                auctionCheck['bidding_type'] as String? ?? 'standard';

            return AuctionDetailModel.fromJson({
              'id': auctionCheck['id'],
              'title': auctionCheck['title'] ?? '',
              'description': auctionCheck['description'] ?? '',
              'starting_price': auctionCheck['starting_price'] ?? 0,
              'current_bid':
                  auctionCheck['current_price'] ??
                  auctionCheck['starting_price'] ??
                  0,
              'reserve_price': biddingType == 'mystery'
                  ? null
                  : auctionCheck['reserve_price'],
              'bid_increment': auctionCheck['bid_increment'] ?? 0,
              'min_bid_increment': numBidIncrement,
              'enable_incremental_bidding':
                  (auctionCheck['enable_incremental_bidding'] as bool?) ?? true,
              'deposit_amount': auctionCheck['deposit_amount'] ?? 0,
              'end_time': auctionCheck['end_time'],
              'start_time': auctionCheck['start_time'],
              'total_bids': auctionCheck['total_bids'] ?? 0,
              'status': 'ended',
              'bidding_type': biddingType,
              'deed_of_sale_url': auctionCheck['deed_of_sale_url'],
              'seller_id': auctionCheck['seller_id'],
              'car_image_url': primaryImage,
              'brand': vehicleData?['brand'] ?? '',
              'make': vehicleData?['brand'] ?? '',
              'model': vehicleData?['model'] ?? '',
              'year': vehicleData?['year'] ?? 0,
              'variant': vehicleData?['variant'],
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
              'chassis_number': vehicleData?['chassis_number'],
              'orcr_status': vehicleData?['orcr_status'],
              'registration_status': vehicleData?['registration_status'],
              'registration_expiry': vehicleData?['registration_expiry'],
              'province': vehicleData?['province'],
              'city_municipality': vehicleData?['city_municipality'],
              'known_issues': vehicleData?['known_issues'],
              'features': vehicleData?['features'],
              'minimum_bid': auctionCheck['starting_price'] ?? 0,
              'is_reserve_met':
                  biddingType != 'mystery' &&
                  auctionCheck['reserve_price'] != null &&
                  (auctionCheck['current_price'] ?? 0) >=
                      auctionCheck['reserve_price'],
              'show_reserve_price': biddingType != 'mystery',
              'bidders_count': auctionCheck['total_bids'] ?? 0,
              'has_user_deposited': hasUserDeposited,
              'photos': photos,
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
