import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../lists/data/models/listing_model.dart';

/// Data source for transaction-related operations
/// Queries the dedicated auction_transactions table for seller-buyer transactions
/// Each transaction represents an auction that moved to in_transaction, sold, or deal_failed status
class TransactionSupabaseDataSource {
  final SupabaseClient _supabase;

  TransactionSupabaseDataSource(this._supabase);

  /// Get transactions by status
  /// Queries auction_transactions table joined with auctions and related data
  Future<List<ListingModel>> getTransactionsByStatus(
    String userId,
    String status,
  ) async {
    try {
      // Query auction_transactions for the user as seller with the specified status
      // Then join with auctions to get full listing details
      // IMPORTANT: Select 'id' (transaction_id) to use for navigation
      final response = await _supabase
          .from('auction_transactions')
          .select('''
            id,
            auction_id,
            status,
            seller_rejection_reason,
            buyer_rejection_reason,
            auctions!inner(
              *,
              auction_statuses(status_name),
              auction_vehicles(
                brand,
                model,
                variant,
                year,
                engine_type,
                engine_displacement,
                cylinder_count,
                horsepower,
                torque,
                transmission,
                fuel_type,
                drive_type,
                length,
                width,
                height,
                wheelbase,
                ground_clearance,
                seating_capacity,
                door_count,
                fuel_tank_capacity,
                curb_weight,
                gross_weight,
                exterior_color,
                paint_type,
                rim_type,
                rim_size,
                tire_size,
                tire_brand,
                condition,
                mileage,
                previous_owners,
                has_modifications,
                modifications_details,
                has_warranty,
                warranty_details,
                usage_type,
                plate_number,
                orcr_status,
                registration_status,
                registration_expiry,
                province,
                city_municipality,
                known_issues,
                features,
                ai_detected_brand,
                ai_detected_model,
                ai_detected_year,
                ai_detected_color,
                ai_detected_damage,
                ai_generated_tags,
                ai_suggested_price_min,
                ai_suggested_price_max,
                ai_price_confidence,
                ai_price_factors
              ),
              auction_photos(
                photo_url,
                category,
                display_order,
                is_primary,
                caption,
                width,
                height,
                file_size
              )
            )
          ''')
          .eq('seller_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);

      // Extract auction data from transaction records
      final transactions = (response as List);
      if (transactions.isEmpty) {
        debugPrint(
          '[TransactionSupabaseDataSource] No transactions found for status: $status',
        );
        return [];
      }

      debugPrint(
        '[TransactionSupabaseDataSource] Found ${transactions.length} transactions for status: $status',
      );

      final accurateBidCounts = await _getAccurateBidCounts(
        transactions
            .map((txn) => txn['auction_id'] as String?)
            .whereType<String>()
            .toList(),
      );

      // Map transaction -> auction data to ListingModel
      return transactions.map((txn) {
        // Clone auction data and normalize status/current_price fields
        final auctionData = Map<String, dynamic>.from(
          txn['auctions'] as Map<String, dynamic>,
        );

        // IMPORTANT: Override the auction's id with the TRANSACTION id
        // This ensures navigation to PreTransactionRealtimePage works correctly
        final transactionId = txn['id'] as String;
        final auctionId = txn['auction_id'] as String?;
        debugPrint(
          '[TransactionSupabaseDataSource] Transaction ID: $transactionId, Auction ID: $auctionId',
        );
        auctionData['id'] = transactionId; // Use transaction ID for navigation
        auctionData['transaction_id'] = transactionId;
        if (auctionId != null && auctionId.isNotEmpty) {
          auctionData['total_bids'] = accurateBidCounts[auctionId] ?? 0;
        }

        // Determine cancellation reason
        String? cancellationReason;
        String? cancelledBy;
        final sellerReason = txn['seller_rejection_reason'] as String?;
        final buyerReason = txn['buyer_rejection_reason'] as String?;
        if (sellerReason != null && sellerReason.isNotEmpty) {
          cancellationReason = sellerReason;
          cancelledBy = 'seller';
        } else if (buyerReason != null && buyerReason.isNotEmpty) {
          cancellationReason = buyerReason;
          cancelledBy = 'buyer';
        }
        auctionData['cancellation_reason'] = cancellationReason;
        auctionData['cancelled_by'] = cancelledBy;

        // Prefer transaction status, otherwise use joined auction_statuses.status_name
        final txnStatus = txn['status'] as String?;
        final joinedStatus = auctionData['auction_statuses'] is Map
            ? (auctionData['auction_statuses'] as Map)['status_name'] as String?
            : null;

        // Normalize to the string status field expected by ListingModel
        auctionData['status'] =
            txnStatus ?? joinedStatus ?? auctionData['status'];

        // Map current_price (DB) to current_bid (model expectation)
        if (auctionData['current_bid'] == null &&
            auctionData['current_price'] != null) {
          auctionData['current_bid'] = auctionData['current_price'];
        }

        return _mergeAuctionWithVehicleData(auctionData);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch transactions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  /// Get active transactions (in_transaction status)
  Future<List<ListingModel>> getActiveTransactions(String userId) async {
    return getTransactionsByStatus(userId, 'in_transaction');
  }

  /// Get completed transactions (sold status)
  Future<List<ListingModel>> getCompletedTransactions(String userId) async {
    final listings = await getTransactionsByStatus(userId, 'sold');
    return _attachReviewStatus(listings, userId);
  }

  /// Get failed transactions (deal_failed status)
  Future<List<ListingModel>> getFailedTransactions(String userId) async {
    return getTransactionsByStatus(userId, 'deal_failed');
  }

  /// Get transactions where user is the BUYER
  /// Queries auction_transactions with buyer_id = userId
  /// Excludes auctions where user is also the seller (prevents showing own listings)
  Future<List<ListingModel>> getBuyerTransactionsByStatus(
    String userId,
    String status,
  ) async {
    try {
      final response = await _supabase
          .from('auction_transactions')
          .select('''
            id,
            auction_id,
            status,
            seller_id,
            seller_rejection_reason,
            buyer_rejection_reason,
            auctions!inner(
              *,
              auction_statuses(status_name),
              auction_vehicles(
                brand, model, variant, year, engine_type, engine_displacement,
                cylinder_count, horsepower, torque, transmission, fuel_type,
                drive_type, length, width, height, wheelbase, ground_clearance,
                seating_capacity, door_count, fuel_tank_capacity, curb_weight,
                gross_weight, exterior_color, paint_type, rim_type, rim_size,
                tire_size, tire_brand, condition, mileage, previous_owners,
                has_modifications, modifications_details, has_warranty,
                warranty_details, usage_type, plate_number, orcr_status,
                registration_status, registration_expiry, province,
                city_municipality, known_issues, features
              ),
              auction_photos(
                photo_url, category, display_order, is_primary, caption
              )
            )
          ''')
          .eq('buyer_id', userId)
          .neq(
            'seller_id',
            userId,
          ) // Exclude transactions where user is also seller
          .eq('status', status)
          .order('created_at', ascending: false);

      final transactions = (response as List);
      if (transactions.isEmpty) return [];

      final accurateBidCounts = await _getAccurateBidCounts(
        transactions
            .map((txn) => txn['auction_id'] as String?)
            .whereType<String>()
            .toList(),
      );

      return transactions.map((txn) {
        final auctionData = Map<String, dynamic>.from(
          txn['auctions'] as Map<String, dynamic>,
        );

        // IMPORTANT: Override the auction's id with the TRANSACTION id
        final transactionId = txn['id'] as String;
        auctionData['id'] = transactionId;
        auctionData['transaction_id'] = transactionId;
        final auctionId = txn['auction_id'] as String?;
        if (auctionId != null && auctionId.isNotEmpty) {
          auctionData['total_bids'] = accurateBidCounts[auctionId] ?? 0;
        }

        // Determine cancellation reason
        String? cancellationReason;
        String? cancelledBy;
        final sellerReason = txn['seller_rejection_reason'] as String?;
        final buyerReason = txn['buyer_rejection_reason'] as String?;
        if (sellerReason != null && sellerReason.isNotEmpty) {
          cancellationReason = sellerReason;
          cancelledBy = 'seller';
        } else if (buyerReason != null && buyerReason.isNotEmpty) {
          cancellationReason = buyerReason;
          cancelledBy = 'buyer';
        }
        auctionData['cancellation_reason'] = cancellationReason;
        auctionData['cancelled_by'] = cancelledBy;

        final txnStatus = txn['status'] as String?;
        final joinedStatus = auctionData['auction_statuses'] is Map
            ? (auctionData['auction_statuses'] as Map)['status_name'] as String?
            : null;
        auctionData['status'] =
            txnStatus ?? joinedStatus ?? auctionData['status'];
        if (auctionData['current_bid'] == null &&
            auctionData['current_price'] != null) {
          auctionData['current_bid'] = auctionData['current_price'];
        }
        return _mergeAuctionWithVehicleData(auctionData);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch buyer transactions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch buyer transactions: $e');
    }
  }

  /// Get active buyer transactions (in_transaction status)
  Future<List<ListingModel>> getActiveBuyerTransactions(String userId) async {
    return getBuyerTransactionsByStatus(userId, 'in_transaction');
  }

  /// Get completed buyer transactions (sold status)
  Future<List<ListingModel>> getCompletedBuyerTransactions(
    String userId,
  ) async {
    final listings = await getBuyerTransactionsByStatus(userId, 'sold');
    return _attachReviewStatus(listings, userId);
  }

  /// Get failed buyer transactions (deal_failed status)
  Future<List<ListingModel>> getFailedBuyerTransactions(String userId) async {
    return getBuyerTransactionsByStatus(userId, 'deal_failed');
  }

  /// Attach review status to completed transaction listings
  Future<List<ListingModel>> _attachReviewStatus(
    List<ListingModel> listings,
    String userId,
  ) async {
    if (listings.isEmpty) return listings;

    try {
      final transactionIds = listings.map((l) => l.id).toList();
      final reviews = await _supabase
          .from('transaction_reviews')
          .select('transaction_id')
          .inFilter('transaction_id', transactionIds)
          .eq('reviewer_id', userId);

      final reviewedIds = <String>{};
      for (final row in (reviews as List)) {
        final txnId = row['transaction_id'] as String?;
        if (txnId != null) reviewedIds.add(txnId);
      }

      return listings.map((listing) {
        // Copy existing listing but with has_review set
        return ListingModel(
          id: listing.id,
          sellerId: listing.sellerId,
          status: listing.status,
          adminStatus: listing.adminStatus,
          rejectionReason: listing.rejectionReason,
          reviewedAt: listing.reviewedAt,
          reviewedBy: listing.reviewedBy,
          madeLiveAt: listing.madeLiveAt,
          brand: listing.brand,
          model: listing.model,
          variant: listing.variant,
          bodyType: listing.bodyType,
          year: listing.year,
          engineType: listing.engineType,
          engineDisplacement: listing.engineDisplacement,
          cylinderCount: listing.cylinderCount,
          horsepower: listing.horsepower,
          torque: listing.torque,
          transmission: listing.transmission,
          fuelType: listing.fuelType,
          driveType: listing.driveType,
          length: listing.length,
          width: listing.width,
          height: listing.height,
          wheelbase: listing.wheelbase,
          groundClearance: listing.groundClearance,
          seatingCapacity: listing.seatingCapacity,
          doorCount: listing.doorCount,
          fuelTankCapacity: listing.fuelTankCapacity,
          curbWeight: listing.curbWeight,
          grossWeight: listing.grossWeight,
          exteriorColor: listing.exteriorColor,
          paintType: listing.paintType,
          rimType: listing.rimType,
          rimSize: listing.rimSize,
          tireSize: listing.tireSize,
          tireBrand: listing.tireBrand,
          condition: listing.condition,
          mileage: listing.mileage,
          previousOwners: listing.previousOwners,
          hasModifications: listing.hasModifications,
          modificationsDetails: listing.modificationsDetails,
          hasWarranty: listing.hasWarranty,
          warrantyDetails: listing.warrantyDetails,
          usageType: listing.usageType,
          plateNumber: listing.plateNumber,
          chassisNumber: listing.chassisNumber,
          orcrStatus: listing.orcrStatus,
          registrationStatus: listing.registrationStatus,
          registrationExpiry: listing.registrationExpiry,
          province: listing.province,
          cityMunicipality: listing.cityMunicipality,
          barangay: listing.barangay,
          photoUrls: listing.photoUrls,
          coverPhotoUrl: listing.coverPhotoUrl,
          description: listing.description,
          knownIssues: listing.knownIssues,
          features: listing.features,
          startingPrice: listing.startingPrice,
          currentBid: listing.currentBid,
          reservePrice: listing.reservePrice,
          auctionStartTime: listing.auctionStartTime,
          auctionEndTime: listing.auctionEndTime,
          totalBids: listing.totalBids,
          watchersCount: listing.watchersCount,
          viewsCount: listing.viewsCount,
          winnerId: listing.winnerId,
          soldPrice: listing.soldPrice,
          soldAt: listing.soldAt,
          createdAt: listing.createdAt,
          updatedAt: listing.updatedAt,
          transactionId: listing.transactionId,
          cancellationReason: listing.cancellationReason,
          cancelledBy: listing.cancelledBy,
          biddingType: listing.biddingType,
          exclusiveTier: listing.exclusiveTier,
          bidIncrement: listing.bidIncrement,
          minBidIncrement: listing.minBidIncrement,
          depositAmount: listing.depositAmount,
          enableIncrementalBidding: listing.enableIncrementalBidding,
          autoLiveAfterApproval: listing.autoLiveAfterApproval,
          snipeGuardEnabled: listing.snipeGuardEnabled,
          snipeGuardThresholdSeconds: listing.snipeGuardThresholdSeconds,
          snipeGuardExtendSeconds: listing.snipeGuardExtendSeconds,
          deedOfSaleUrl: listing.deedOfSaleUrl,
          visibility: listing.visibility,
          allowsInstallment: listing.allowsInstallment,
          hasReview: reviewedIds.contains(listing.id),
        );
      }).toList();
    } catch (e) {
      debugPrint(
        '[TransactionSupabaseDataSource] Error attaching review status: $e',
      );
      return listings;
    }
  }

  /// Helper: Merge auction data with nested vehicle and photo data
  /// Handles Supabase's varying return formats (array vs object for one-to-one relations)
  ListingModel _mergeAuctionWithVehicleData(Map<String, dynamic> json) {
    try {
      // Create a copy of the JSON to merge data into
      final mergedJson = Map<String, dynamic>.from(json);

      // Extract nested vehicle data
      final vehicleData = json['auction_vehicles'];
      Map<String, dynamic>? vehicle;

      if (vehicleData is List && vehicleData.isNotEmpty) {
        // Supabase sometimes returns one-to-one as array
        vehicle = vehicleData[0] as Map<String, dynamic>?;
      } else if (vehicleData is Map<String, dynamic>) {
        // Sometimes as object
        vehicle = vehicleData;
      }

      // Merge vehicle fields into root level
      if (vehicle != null) {
        vehicle.forEach((key, value) {
          mergedJson[key] = value;
        });
      } else {
        // Fallback: parse from auction title if vehicle data is missing
        final title = mergedJson['title'] as String?;
        if (title != null && !title.startsWith('Vehicle Auction #')) {
          final parts = title.split(' ');
          final yearStr = parts.firstWhere(
            (p) => p.length == 4 && int.tryParse(p) != null,
            orElse: () => '0',
          );
          mergedJson['year'] = int.tryParse(yearStr) ?? 0;

          final yearIndex = parts.indexOf(yearStr);
          if (yearIndex >= 0 && yearIndex < parts.length - 1) {
            mergedJson['brand'] = parts[yearIndex + 1];
            if (yearIndex + 2 < parts.length) {
              mergedJson['model'] = parts.sublist(yearIndex + 2).join(' ');
            }
          }
        }

        // Set default values if still missing
        mergedJson['brand'] ??= 'Unknown';
        mergedJson['model'] ??= 'Vehicle';
        mergedJson['year'] ??= 0;
      }

      // Process photos
      final photosData = json['auction_photos'];
      Map<String, List<String>> photoUrls = {};
      String? coverPhotoUrl;

      if (photosData is List) {
        // Group photos by category
        for (var photo in photosData) {
          final category = photo['category'] as String? ?? 'other';
          final url = photo['photo_url'] as String?;

          if (url != null) {
            photoUrls.putIfAbsent(category, () => []);
            photoUrls[category]!.add(url);

            // Set cover photo
            if (photo['is_primary'] == true && coverPhotoUrl == null) {
              coverPhotoUrl = url;
            }
          }
        }

        // If no primary photo, use first photo as cover
        if (coverPhotoUrl == null && photosData.isNotEmpty) {
          coverPhotoUrl = photosData[0]['photo_url'] as String?;
        }
      }

      mergedJson['photo_urls'] = photoUrls;
      mergedJson['cover_photo_url'] = coverPhotoUrl;

      // Set default values for required fields
      mergedJson['condition'] ??= 'used';
      mergedJson['mileage'] ??= 0;
      mergedJson['transmission'] ??= 'manual';
      mergedJson['fuel_type'] ??= 'gasoline';
      mergedJson['exterior_color'] ??= 'other';
      mergedJson['plate_number'] ??= '';
      mergedJson['orcr_status'] ??= 'complete';
      mergedJson['registration_status'] ??= 'registered';
      mergedJson['province'] ??= '';
      mergedJson['city_municipality'] ??= '';
      mergedJson['description'] ??= '';
      mergedJson['has_modifications'] ??= false;
      mergedJson['has_warranty'] ??= false;
      mergedJson['starting_price'] ??= 0.0;
      mergedJson['current_bid'] ??= 0.0;
      mergedJson['total_bids'] ??= 0;
      mergedJson['watchers_count'] ??= 0;
      mergedJson['views_count'] ??= 0;

      return ListingModel.fromJson(mergedJson);
    } catch (e) {
      throw Exception('Failed to merge transaction data: $e');
    }
  }

  Future<Map<String, int>> _getAccurateBidCounts(
    List<String> auctionIds,
  ) async {
    final uniqueAuctionIds = auctionIds.toSet().toList();
    if (uniqueAuctionIds.isEmpty) {
      return {};
    }

    try {
      final bids = await _supabase
          .from('bids')
          .select('auction_id')
          .inFilter('auction_id', uniqueAuctionIds);

      final counts = <String, int>{};
      for (final row in (bids as List)) {
        if (row is Map<String, dynamic>) {
          final auctionId = row['auction_id'] as String?;
          if (auctionId != null && auctionId.isNotEmpty) {
            counts[auctionId] = (counts[auctionId] ?? 0) + 1;
          }
        }
      }
      return counts;
    } catch (_) {
      return {};
    }
  }

  /// Submit a report for a transaction
  Future<void> submitReport({
    required String transactionId,
    required String reporterId,
    required String reportedUserId,
    required String reason,
    required String description,
  }) async {
    await _supabase.from('transaction_reports').insert({
      'transaction_id': transactionId,
      'reporter_id': reporterId,
      'reported_user_id': reportedUserId,
      'reason': reason,
      'description': description,
    });
  }

  /// Get the next eligible winner for an auction after the current buyer cancels.
  /// Excludes all bids from the previous winning bidder.
  /// Returns null if no eligible next winner exists (e.g. only 1 unique bidder).
  Future<Map<String, dynamic>?> getNextEligibleWinner(
    String transactionId,
  ) async {
    try {
      final result = await _supabase.rpc(
        'get_top_next_winner',
        params: {'p_transaction_id': transactionId},
      );

      final rows = result as List?;
      if (rows == null || rows.isEmpty) return null;

      return Map<String, dynamic>.from(rows.first as Map);
    } catch (e) {
      debugPrint('[TransactionDS] Error getting next eligible winner: $e');
      return null;
    }
  }

  /// Count unique eligible bidders that could be the next winner.
  /// Returns 0 if only the cancelled buyer has bid.
  Future<int> countEligibleNextBidders(String transactionId) async {
    try {
      final result = await _supabase.rpc(
        'count_eligible_next_bidders',
        params: {'p_transaction_id': transactionId},
      );
      return (result as int?) ?? 0;
    } catch (e) {
      debugPrint('[TransactionDS] Error counting eligible bidders: $e');
      return 0;
    }
  }

  /// Cancel the auction with penalty recorded for the cancelling party.
  Future<bool> cancelAuctionWithPenalty(
    String transactionId,
    String reason,
  ) async {
    try {
      await _supabase.rpc(
        'cancel_auction_with_penalty',
        params: {'p_transaction_id': transactionId, 'p_reason': reason},
      );
      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error cancelling with penalty: $e');
      return false;
    }
  }

  /// Automatically reselect the next highest eligible bidder.
  Future<bool> autoReselectNextWinner(String transactionId) async {
    try {
      final result = await _supabase.rpc(
        'auto_reselect_next_winner',
        params: {'p_transaction_id': transactionId},
      );
      return result == true;
    } catch (e) {
      debugPrint('[TransactionDS] Error auto-reselecting winner: $e');
      return false;
    }
  }

  /// Restart auction bidding from scratch (relist).
  Future<bool> restartAuctionBidding(String transactionId) async {
    try {
      await _supabase.rpc(
        'restart_auction_bidding',
        params: {'p_transaction_id': transactionId},
      );
      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error restarting auction: $e');
      return false;
    }
  }
}
