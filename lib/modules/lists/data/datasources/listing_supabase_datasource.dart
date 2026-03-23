import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing_draft_model.dart';
import '../models/listing_model.dart';
import '../../domain/entities/listing_draft_entity.dart';

/// Supabase datasource for listing operations
/// Handles all database interactions for listings and drafts
class ListingSupabaseDataSource {
  final SupabaseClient _supabase;

  SupabaseClient get client => _supabase;

  ListingSupabaseDataSource(this._supabase);

  // ============================================================================
  // DRAFT OPERATIONS
  // ============================================================================

  /// Create a new empty draft
  Future<ListingDraftModel> createDraft(String sellerId) async {
    try {
      final response = await _supabase
          .from('listing_drafts')
          .insert({
            'seller_id': sellerId,
            'current_step': 1,
            'is_complete': false,
            'last_saved': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ListingDraftModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to create draft: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create draft: $e');
    }
  }

  /// Get all drafts for a seller
  Future<List<ListingDraftModel>> getSellerDrafts(String sellerId) async {
    try {
      final response = await _supabase
          .from('listing_drafts')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_complete', false)
          .isFilter('deleted_at', null)
          .order('last_saved', ascending: false);

      return (response as List)
          .map((json) => ListingDraftModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch drafts: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch drafts: $e');
    }
  }

  /// Get specific draft by ID
  Future<ListingDraftModel?> getDraft(String draftId) async {
    try {
      final response = await _supabase
          .from('listing_drafts')
          .select()
          .eq('id', draftId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return ListingDraftModel.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch draft: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch draft: $e');
    }
  }

  /// Save/update draft (auto-save functionality)
  Future<void> saveDraft(ListingDraftEntity draft) async {
    try {
      final model = ListingDraftModel(
        id: draft.id,
        sellerId: draft.sellerId,
        currentStep: draft.currentStep,
        lastSaved: DateTime.now(),
        isComplete: draft.isComplete,
        brand: draft.brand,
        model: draft.model,
        variant: draft.variant,
        bodyType: draft.bodyType,
        year: draft.year,
        engineType: draft.engineType,
        engineDisplacement: draft.engineDisplacement,
        cylinderCount: draft.cylinderCount,
        horsepower: draft.horsepower,
        torque: draft.torque,
        transmission: draft.transmission,
        fuelType: draft.fuelType,
        driveType: draft.driveType,
        length: draft.length,
        width: draft.width,
        height: draft.height,
        wheelbase: draft.wheelbase,
        groundClearance: draft.groundClearance,
        seatingCapacity: draft.seatingCapacity,
        doorCount: draft.doorCount,
        fuelTankCapacity: draft.fuelTankCapacity,
        curbWeight: draft.curbWeight,
        grossWeight: draft.grossWeight,
        exteriorColor: draft.exteriorColor,
        paintType: draft.paintType,
        rimType: draft.rimType,
        rimSize: draft.rimSize,
        tireSize: draft.tireSize,
        tireBrand: draft.tireBrand,
        condition: draft.condition,
        mileage: draft.mileage,
        previousOwners: draft.previousOwners,
        hasModifications: draft.hasModifications,
        modificationsDetails: draft.modificationsDetails,
        hasWarranty: draft.hasWarranty,
        warrantyDetails: draft.warrantyDetails,
        usageType: draft.usageType,
        plateNumber: draft.plateNumber,
        orcrStatus: draft.orcrStatus,
        registrationStatus: draft.registrationStatus,
        registrationExpiry: draft.registrationExpiry,
        province: draft.province,
        cityMunicipality: draft.cityMunicipality,
        barangay: draft.barangay,
        photoUrls: draft.photoUrls,
        coverPhotoUrl: draft.coverPhotoUrl,
        tags: draft.tags,
        deedOfSaleUrl: draft.deedOfSaleUrl,
        description: draft.description,
        knownIssues: draft.knownIssues,
        features: draft.features,
        startingPrice: draft.startingPrice,
        reservePrice: draft.reservePrice,
        auctionEndDate: draft.auctionEndDate,
        // Bidding Configuration
        biddingType: draft.biddingType,
        bidIncrement: draft.bidIncrement,
        minBidIncrement: draft.minBidIncrement,
        depositAmount: draft.depositAmount,
        enableIncrementalBidding: draft.enableIncrementalBidding,
        autoLiveAfterApproval: draft.autoLiveAfterApproval,
        scheduleLiveMode: draft.scheduleLiveMode,
        auctionStartDate: draft.auctionStartDate,
        auctionDurationHours: draft.auctionDurationHours,
        snipeGuardEnabled: draft.snipeGuardEnabled,
        snipeGuardThresholdSeconds: draft.snipeGuardThresholdSeconds,
        snipeGuardExtendSeconds: draft.snipeGuardExtendSeconds,
        allowsInstallment: draft.allowsInstallment,
        isPlateValid: draft.isPlateValid,
      );

      await _supabase
          .from('listing_drafts')
          .update(model.toJson())
          .eq('id', draft.id);
    } on PostgrestException catch (e) {
      throw Exception('Failed to save draft: ${e.message}');
    } catch (e) {
      throw Exception('Failed to save draft: $e');
    }
  }

  /// Delete draft (Hard delete)
  /// Requires proper authentication - the current user must be the draft owner
  Future<void> deleteDraft(String draftId) async {
    try {
      // Ensure user is authenticated
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User must be authenticated to delete draft');
      }

      debugPrint(
        '[ListingSupabaseDataSource] Deleting draft: $draftId for user: ${currentUser.id}',
      );

      // Hard delete: remove the row completely
      final response = await _supabase
          .from('listing_drafts')
          .delete()
          .eq('id', draftId)
          .select(); // Returns deleted rows if any

      // Check if any rows were actually deleted
      if (response.isEmpty) {
        throw Exception(
          'Draft not found or access denied. Ensure you own this draft.',
        );
      }

      debugPrint(
        '[ListingSupabaseDataSource] Successfully deleted draft: $draftId',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] PostgrestException deleting draft: ${e.message}',
      );
      if (e.message.contains('row level security')) {
        throw Exception('Access denied: You can only delete your own drafts');
      }
      throw Exception('Failed to delete draft: ${e.message}');
    } catch (e) {
      debugPrint('[ListingSupabaseDataSource] Exception deleting draft: $e');
      throw Exception('Failed to delete draft: $e');
    }
  }

  /// Mark draft as complete (ready for submission)
  Future<void> markDraftComplete(String draftId) async {
    try {
      await _supabase
          .from('listing_drafts')
          .update({'is_complete': true})
          .eq('id', draftId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to mark draft complete: ${e.message}');
    } catch (e) {
      throw Exception('Failed to mark draft complete: $e');
    }
  }

  // ============================================================================
  // LISTING SUBMISSION
  // ============================================================================

  /// Submit draft as listing (calls database function)
  Future<String> submitListing(String draftId) async {
    try {
      // Pre-check: prevent duplicate car (by plate_number) across statuses
      final draftRow = await _supabase
          .from('listing_drafts')
          .select('seller_id, plate_number, auto_live_after_approval')
          .eq('id', draftId)
          .single();

      final sellerId = draftRow['seller_id'] as String?;
      final plateNumber = draftRow['plate_number'] as String?;
      final autoLiveAfterApproval =
          draftRow['auto_live_after_approval'] as bool? ?? false;

      if (sellerId != null && plateNumber != null && plateNumber.isNotEmpty) {
        await _ensureUniquePlate(sellerId, plateNumber);
      }

      final response = await _supabase.rpc(
        'submit_listing_from_draft',
        params: {'draft_id': draftId},
      );

      // RPC returns JSON: {success: bool, auction_id: string, message: string, error?: string}
      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        final auctionId = result['auction_id'] as String;
        await _syncSelectedPrimaryPhoto(draftId: draftId, auctionId: auctionId);

        await _supabase
            .from('auctions')
            .update({'auto_live_after_approval': autoLiveAfterApproval})
            .eq('id', auctionId);

        await _supabase
            .from('listing_drafts')
            .update({'deleted_at': DateTime.now().toIso8601String()})
            .eq('id', draftId);

        return auctionId; // Returns new auction ID
      } else {
        throw Exception(result['error'] ?? 'Failed to submit listing');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit listing: $e');
    }
  }

  // ============================================================================
  // LISTING RETRIEVAL (by status for different tabs)
  // ============================================================================

  /// Get seller's listings by status
  Future<List<ListingModel>> getSellerListingsByStatus(
    String sellerId,
    String status,
  ) async {
    try {
      // Query auctions table and filter by joined auction_statuses.status_name
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            visibility,
            auction_statuses!inner(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('auction_statuses.status_name', status)
          .order('created_at', ascending: false);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows.map((json) {
        // Ensure status is correctly set based on the query filter
        if (json['auction_statuses'] == null) {
          json['auction_statuses'] = {'status_name': status};
        } else if (json['auction_statuses'] is Map) {
          (json['auction_statuses'] as Map)['status_name'] = status;
        }
        return _mergeAuctionWithVehicleData(json);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch listings: $e');
    }
  }

  /// Get pending listings (pending admin approval)
  Future<List<ListingModel>> getPendingListings(String sellerId) async {
    try {
      // Query auctions with status 'pending_approval' and JOIN with auction_vehicles for car details
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses!inner(status_name),
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
              features
            ),
            auction_photos(
              photo_url,
              category,
              display_order,
              is_primary
            )
          ''')
          .eq('seller_id', sellerId)
          .eq('auction_statuses.status_name', 'pending_approval')
          .order('created_at', ascending: false);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows
          .map((json) => _mergeAuctionWithVehicleData(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch pending listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch pending listings: $e');
    }
  }

  /// Get approved listings (waiting for seller to make live)
  Future<List<ListingModel>> getApprovedListings(String sellerId) async {
    try {
      final approvedStatusId = await _getStatusId('approved');

      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', approvedStatusId)
          .order('updated_at', ascending: false);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows
          .map((json) => _mergeAuctionWithVehicleData(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch approved listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch approved listings: $e');
    }
  }

  /// Helper: Get status ID from status name
  Future<String> _getStatusId(String statusName) async {
    // Use maybeSingle to avoid PostgrestException when the status does not exist.
    final response = await _supabase
        .from('auction_statuses')
        .select('id')
        .eq('status_name', statusName)
        .maybeSingle();

    if (response == null) {
      throw Exception(
        'Auction status "$statusName" not found in database. Ensure migrations/seeds have been applied to add this status.',
      );
    }

    return response['id'] as String;
  }

  /// Get active listings (live auctions)
  /// Also checks for and transitions any 'scheduled' listings that have passed their start time
  Future<List<ListingModel>> getActiveListings(String sellerId) async {
    try {
      final liveStatusId = await _getStatusId('live');
      final scheduledStatusId = await _getStatusId('scheduled');
      final now = DateTime.now().toIso8601String();

      // 1. Fetch currently live listings
      final liveResponse = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', liveStatusId);

      // 2. Fetch scheduled listings that should be live (start_time <= now)
      final dueScheduledResponse = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', scheduledStatusId)
          .lte('start_time', now);

      final hydratedLiveRows = await _applyAccurateBidCounts(
        liveResponse as List,
      );
      final hydratedDueRows = await _applyAccurateBidCounts(
        dueScheduledResponse as List,
      );

      final liveList = hydratedLiveRows
          .map((json) => _mergeAuctionWithVehicleData(json))
          .toList();

      final dueList = hydratedDueRows
          .map((json) => _mergeAuctionWithVehicleData(json))
          .toList();

      // 3. Transition any due scheduled listings to live
      if (dueList.isNotEmpty) {
        debugPrint(
          '[ListingSupabaseDataSource] Found ${dueList.length} scheduled listings due for go-live. Auto-transitioning...',
        );

        for (final listing in dueList) {
          try {
            // Update status in DB
            await updateListingStatusByName(listing.id, 'live');

            // Update local model status to 'live' so it shows correctly immediately
            // We can't modify the immutable ListingModel, so we rely on the DB update
            // and the fact that we're adding it to the liveList implies it's treated as active
            // But we should ideally update the status field in the model if we could.
            // Since we can't easily clone-update, we'll just add it to the list.
            // The UI will show it in the Active tab, effectively "fixing" the view.
          } catch (e) {
            debugPrint('Failed to auto-transition listing ${listing.id}: $e');
          }
        }

        // Add them to the main list
        liveList.addAll(dueList);
      }

      // 4. Sort by start_time descending
      liveList.sort((a, b) {
        final aTime = a.auctionStartTime ?? DateTime(0);
        final bTime = b.auctionStartTime ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

      return liveList;
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch active listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch active listings: $e');
    }
  }

  /// Get scheduled listings
  Future<List<ListingModel>> getScheduledListings(String sellerId) async {
    try {
      final scheduledStatusId = await _getStatusId('scheduled');

      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', scheduledStatusId)
          .order('start_time', ascending: true);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows
          .map((json) => _mergeAuctionWithVehicleData(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch scheduled listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch scheduled listings: $e');
    }
  }

  /// Get ended listings (awaiting seller decision: reauction or cancel)
  Future<List<ListingModel>> getEndedListings(String sellerId) async {
    try {
      final endedStatusId = await _getStatusId('ended');

      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', endedStatusId)
          .order('end_time', ascending: false);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows.map((json) {
        // Force status to 'ended'
        if (json['auction_statuses'] == null) {
          json['auction_statuses'] = {'status_name': 'ended'};
        } else if (json['auction_statuses'] is Map) {
          (json['auction_statuses'] as Map)['status_name'] = 'ended';
        }
        return _mergeAuctionWithVehicleData(json);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch ended listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch ended listings: $e');
    }
  }

  /// Get sold listings
  Future<List<ListingModel>> getSoldListings(String sellerId) async {
    try {
      final soldStatusId = await _getStatusId('sold');

      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', soldStatusId)
          .order('end_time', ascending: false);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows.map((json) {
        // Force status to 'sold'
        if (json['auction_statuses'] == null) {
          json['auction_statuses'] = {'status_name': 'sold'};
        } else if (json['auction_statuses'] is Map) {
          (json['auction_statuses'] as Map)['status_name'] = 'sold';
        }
        return _mergeAuctionWithVehicleData(json);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch sold listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch sold listings: $e');
    }
  }

  /// Get cancelled/rejected listings
  /// Joins with auction_transactions to check if cancelled listing has a failed transaction
  Future<List<ListingModel>> getCancelledListings(String sellerId) async {
    try {
      final cancelledStatusId = await _getStatusId('cancelled');

      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles(*),
            auction_photos(photo_url, category, display_order, is_primary),
            auction_transactions!auction_transactions_auction_id_fkey(id, status)
          ''')
          .eq('seller_id', sellerId)
          .eq('status_id', cancelledStatusId)
          .order('created_at', ascending: false);

      final hydratedRows = await _applyAccurateBidCounts(response as List);

      return hydratedRows.map((json) {
        // Check if there's a failed transaction associated with this cancelled listing
        final transactionsData = json['auction_transactions'];
        List<dynamic> transactions = [];
        if (transactionsData is List) {
          transactions = transactionsData;
        } else if (transactionsData is Map) {
          transactions = [transactionsData];
        }

        String? transactionId;
        if (transactions.isNotEmpty) {
          // Find the transaction (typically deal_failed status for buyer-cancelled deals)
          final failedTransaction = transactions.firstWhere(
            (txn) => txn['status'] == 'deal_failed',
            orElse: () => transactions.first,
          );
          transactionId = failedTransaction['id'] as String?;
        }

        // Add transaction_id to the JSON before merging
        final jsonWithTransaction = Map<String, dynamic>.from(json);
        jsonWithTransaction['transaction_id'] = transactionId;

        return _mergeAuctionWithVehicleData(jsonWithTransaction);
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch cancelled listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch cancelled listings: $e');
    }
  }

  // ============================================================================
  // LISTING ACTIONS
  // ============================================================================

  /// Update listing status by name (e.g., 'live', 'scheduled', 'ended')
  /// Performs the update and verifies success without complex select queries
  Future<bool> updateListingStatusByName(
    String auctionId,
    String statusName, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Validate input
      if (auctionId.isEmpty || statusName.isEmpty) {
        throw Exception('Invalid auctionId or statusName');
      }

      debugPrint(
        '[ListingSupabaseDataSource] Starting status update: '
        'auctionId=$auctionId, statusName=$statusName',
      );

      // Get status ID from status name
      final statusId = await _getStatusId(statusName);
      debugPrint(
        '[ListingSupabaseDataSource] Resolved status $statusName to ID: $statusId',
      );

      // Prepare update data
      final updateData = {
        'status_id': statusId,
        'updated_at': DateTime.now().toIso8601String(),
        if (additionalData != null) ...additionalData,
      };

      debugPrint('[ListingSupabaseDataSource] Update data: $updateData');

      // First, verify the auction exists before updating
      final existingAuction = await _supabase
          .from('auctions')
          .select('id, status_id, seller_id')
          .eq('id', auctionId)
          .maybeSingle();

      if (existingAuction == null) {
        throw Exception('Auction not found with ID: $auctionId');
      }

      debugPrint(
        '[ListingSupabaseDataSource] Found auction: '
        'seller_id=${existingAuction['seller_id']}, '
        'current_status_id=${existingAuction['status_id']}',
      );

      // Perform the update - capture any errors
      debugPrint('[ListingSupabaseDataSource] Executing update query...');
      await _supabase.from('auctions').update(updateData).eq('id', auctionId);

      debugPrint('[ListingSupabaseDataSource] Update query completed');

      // Wait a moment for DB replication
      await Future.delayed(const Duration(milliseconds: 500));

      // Verify the update by fetching the auction back
      final verification = await _supabase
          .from('auctions')
          .select('id, status_id, updated_at')
          .eq('id', auctionId)
          .maybeSingle();

      if (verification == null) {
        throw Exception('Auction disappeared after update (ID: $auctionId)');
      }

      final updatedStatusId = verification['status_id'] as String?;
      debugPrint(
        '[ListingSupabaseDataSource] After update: status_id=$updatedStatusId, '
        'updated_at=${verification['updated_at']}',
      );

      if (updatedStatusId != statusId) {
        debugPrint(
          '[ListingSupabaseDataSource] WARNING: Status not persisted! '
          'Expected $statusId but got $updatedStatusId. '
          'This suggests RLS policy issue or permission problem.',
        );
        throw Exception(
          'Status update failed to persist: expected $statusId, got $updatedStatusId. '
          'Check RLS policies and user permissions.',
        );
      }

      debugPrint(
        '[ListingSupabaseDataSource] Successfully updated auction $auctionId '
        'from status ${existingAuction['status_id']} to $statusId ($statusName)',
      );
      return true;
    } on PostgrestException catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] PostgreSQL error updating status: '
        'code=${e.code}, message=${e.message}, details=${e.details}',
      );
      throw Exception('Database error: ${e.message}');
    } catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] Error updating listing status: $e',
      );
      rethrow;
    }
  }

  /// Trigger transaction creation when auction moves to in_transaction status
  /// This ensures a record exists in the auction_transactions table
  /// The trigger should handle this automatically, but this method provides explicit creation
  Future<bool> ensureTransactionCreated(
    String auctionId,
    String sellerId,
  ) async {
    try {
      debugPrint(
        '[ListingSupabaseDataSource] Ensuring transaction record for auction: $auctionId',
      );

      // First, verify auction exists and get its current_price
      final auctionData = await _supabase
          .from('auctions')
          .select('current_price, total_bids')
          .eq('id', auctionId)
          .maybeSingle();

      if (auctionData == null) {
        debugPrint(
          '[ListingSupabaseDataSource] ❌ Auction not found: $auctionId',
        );
        return false;
      }

      final currentPrice = auctionData['current_price'] as num?;
      final totalBids = auctionData['total_bids'] as int?;

      debugPrint(
        '[ListingSupabaseDataSource] Auction current_price: $currentPrice, total_bids: $totalBids',
      );

      // Get the highest bidder - try multiple approaches
      Map<String, dynamic>? highestBid;

      // Approach 1: Get by max bid_amount
      try {
        final bids = await _supabase
            .from('bids')
            .select('bidder_id, bid_amount, id')
            .eq('auction_id', auctionId)
            .order('bid_amount', ascending: false)
            .limit(1);

        if ((bids as List).isNotEmpty) {
          highestBid = bids[0];
          debugPrint(
            '[ListingSupabaseDataSource] Found highest bid via query: ${highestBid['bid_amount']}',
          );
        }
      } catch (e) {
        debugPrint(
          '[ListingSupabaseDataSource] Error querying bids directly: $e',
        );
      }

      // Approach 2: If no bid found via direct query, use RPC or aggregation
      if (highestBid == null) {
        try {
          final rpcResult = await _supabase.rpc(
            'get_highest_bid',
            params: {'auction_id_param': auctionId},
          );

          if (rpcResult != null) {
            // RPC returns a list, get first element
            if (rpcResult is List && rpcResult.isNotEmpty) {
              highestBid = rpcResult[0] as Map<String, dynamic>;
            } else if (rpcResult is Map) {
              highestBid = rpcResult as Map<String, dynamic>;
            }

            if (highestBid != null) {
              debugPrint(
                '[ListingSupabaseDataSource] Found highest bid via RPC: ${highestBid['bid_amount']}',
              );
            }
          }
        } catch (e) {
          debugPrint(
            '[ListingSupabaseDataSource] RPC approach failed: $e - continuing with fallback',
          );
        }
      }

      // Approach 3: Use auction's current_price as fallback (it should be synced by trigger)
      if (highestBid == null && currentPrice != null && currentPrice > 0) {
        debugPrint(
          '[ListingSupabaseDataSource] Using auction current_price ($currentPrice) as bid amount',
        );

        // Get any bidder for this price
        try {
          final bidderSearch = await _supabase
              .from('bids')
              .select('bidder_id')
              .eq('auction_id', auctionId)
              .eq('bid_amount', currentPrice)
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

          if (bidderSearch != null) {
            highestBid = {
              'bidder_id': bidderSearch['bidder_id'],
              'bid_amount': currentPrice,
            };
            debugPrint(
              '[ListingSupabaseDataSource] Found bidder with current_price',
            );
          }
        } catch (e) {
          debugPrint('[ListingSupabaseDataSource] Bidder search failed: $e');
        }
      }

      if (highestBid == null) {
        debugPrint(
          '[ListingSupabaseDataSource] ❌ No winning bid found for auction: $auctionId. Current price: $currentPrice, Total bids: $totalBids',
        );
        return false;
      }

      final buyerId = highestBid['bidder_id'] as String;
      final agreedPrice = (highestBid['bid_amount'] as num).toDouble();

      debugPrint(
        '[ListingSupabaseDataSource] Creating transaction - Buyer: $buyerId, Price: $agreedPrice',
      );

      // Create or update transaction record
      await _supabase.from('auction_transactions').upsert({
        'auction_id': auctionId,
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'agreed_price': agreedPrice,
        'status': 'in_transaction',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'auction_id');

      debugPrint(
        '[ListingSupabaseDataSource] ✅ Transaction record created/updated for auction: $auctionId',
      );
      return true;
    } on PostgrestException catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] Postgrest error creating transaction: ${e.message} (Code: ${e.code})',
      );
      debugPrint('[ListingSupabaseDataSource] Details: ${e.details}');
      return false;
    } catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] Unexpected error ensuring transaction: $e',
      );
      return false;
    }
  }

  /// End active auction (move to ended status)
  Future<bool> endAuction(String auctionId) async {
    try {
      debugPrint('[ListingSupabaseDataSource] Ending auction: $auctionId');

      return await updateListingStatusByName(
        auctionId,
        'ended',
        additionalData: {'end_time': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      debugPrint('[ListingSupabaseDataSource] Error ending auction: $e');
      rethrow;
    }
  }

  /// Reauction ended listing (move back to pending for admin review)
  Future<bool> reauctiongListing(String auctionId) async {
    try {
      debugPrint('[ListingSupabaseDataSource] Reauction listing: $auctionId');

      return await updateListingStatusByName(auctionId, 'pending_approval');
    } catch (e) {
      debugPrint('[ListingSupabaseDataSource] Error reauction listing: $e');
      rethrow;
    }
  }

  /// Cancel ended auction (move to cancelled status)
  Future<bool> cancelEndedAuction(String auctionId) async {
    try {
      debugPrint(
        '[ListingSupabaseDataSource] Cancelling ended auction: $auctionId',
      );

      return await updateListingStatusByName(auctionId, 'cancelled');
    } catch (e) {
      debugPrint('[ListingSupabaseDataSource] Error cancelling auction: $e');
      rethrow;
    }
  }

  /// Update auction end time for pending/approved listings
  Future<void> updateAuctionEndTime(
    String auctionId,
    DateTime newEndTime,
  ) async {
    try {
      final response = await _supabase.rpc(
        'update_auction_end_time',
        params: {
          'p_auction_id': auctionId,
          'p_new_end_time': newEndTime.toIso8601String(),
        },
      );

      // Check if RPC returned error
      if (response is Map) {
        if (response['success'] == false) {
          throw Exception(
            response['error'] ?? 'Failed to update auction end time',
          );
        }
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to update end time: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update end time: $e');
    }
  }

  /// Complete sale (mark as sold)
  Future<void> completeSale(String listingId, double finalPrice) async {
    try {
      await _supabase.rpc(
        'complete_sale',
        params: {'listing_id': listingId, 'final_price': finalPrice},
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to complete sale: ${e.message}');
    } catch (e) {
      throw Exception('Failed to complete sale: $e');
    }
  }

  /// Seller decides whether to proceed or cancel after auction ends
  Future<void> sellerDecideAfterAuction(String auctionId, bool proceed) async {
    try {
      final response = await _supabase.rpc(
        'seller_decide_after_auction',
        params: {'p_auction_id': auctionId, 'p_proceed': proceed},
      );

      // Check if RPC returned error
      if (response is Map && response['success'] == false) {
        throw Exception(response['error'] ?? 'Failed to process decision');
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to process decision: ${e.message}');
    } catch (e) {
      throw Exception('Failed to process decision: $e');
    }
  }

  /// Cancel listing (seller cancels from pending, approved, or any status)
  /// Moves listing to cancelled status
  Future<void> cancelListing(String auctionId) async {
    try {
      debugPrint('[ListingSupabaseDataSource] Cancelling listing: $auctionId');

      // Verify auction exists and get current status before update
      final beforeUpdate = await _supabase
          .from('auctions')
          .select('id, status_id, seller_id')
          .eq('id', auctionId)
          .maybeSingle();

      if (beforeUpdate == null) {
        throw Exception('Auction not found with ID: $auctionId');
      }

      debugPrint(
        '[ListingSupabaseDataSource] Before cancel - status_id: ${beforeUpdate['status_id']}',
      );

      // Perform the status update
      await updateListingStatusByName(auctionId, 'cancelled');

      // Verify the update persisted
      final afterUpdate = await _supabase
          .from('auctions')
          .select('id, status_id, auction_statuses(status_name)')
          .eq('id', auctionId)
          .maybeSingle();

      if (afterUpdate == null) {
        throw Exception(
          'Listing disappeared after cancel attempt - may have been deleted by trigger',
        );
      }

      final newStatusId = afterUpdate['status_id'];
      final statusInfo = afterUpdate['auction_statuses'];
      final statusName = statusInfo is Map
          ? statusInfo['status_name']
          : 'unknown';

      debugPrint(
        '[ListingSupabaseDataSource] After cancel - status_id: $newStatusId, status_name: $statusName',
      );
      debugPrint(
        '[ListingSupabaseDataSource] Successfully cancelled listing: $auctionId',
      );
    } on PostgrestException catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] PostgrestException cancelling: code=${e.code}, message=${e.message}, details=${e.details}',
      );
      throw Exception('Failed to cancel listing: ${e.message}');
    } catch (e) {
      debugPrint(
        '[ListingSupabaseDataSource] Exception cancelling listing: $e',
      );
      throw Exception('Failed to cancel listing: $e');
    }
  }

  // ============================================================================
  // CANCELLED LISTING ACTIONS
  // ============================================================================

  /// Copy cancelled listing to a new draft for editing and resubmission
  /// Used when seller wants to edit and resubmit a cancelled listing
  Future<String> copyListingToDraft(String auctionId, String sellerId) async {
    try {
      debugPrint(
        '[ListingSupabaseDataSource] Copying cancelled listing to draft: $auctionId',
      );

      // Fetch the cancelled auction with all its details
      final auctionResponse = await _supabase
          .from('auctions')
          .select('''
            id, title, description, starting_price, reserve_price, 
            bid_increment, deposit_amount, seller_id,
            auction_vehicles(*),
            auction_photos(*)
            ''')
          .eq('id', auctionId)
          .eq('seller_id', sellerId)
          .single();

      // Extract vehicle data
      final vehicleData = auctionResponse['auction_vehicles'];
      Map<String, dynamic>? vehicleInfo;
      if (vehicleData != null && vehicleData is Map<String, dynamic>) {
        vehicleInfo = vehicleData;
      } else if (vehicleData != null &&
          vehicleData is List &&
          vehicleData.isNotEmpty) {
        vehicleInfo = vehicleData[0] as Map<String, dynamic>;
      }

      // Extract photos
      final photosData = auctionResponse['auction_photos'] as List? ?? [];
      final photoUrls = <String, List<String>>{};
      String? coverPhotoUrl;
      for (final photo in photosData) {
        if (photo is Map<String, dynamic>) {
          final category = _normalizePhotoCategory(
            photo['category'] as String?,
          );
          final url = photo['photo_url'] as String?;
          if (url != null && url.isNotEmpty) {
            photoUrls.putIfAbsent(category, () => []).add(url);
            if (photo['is_primary'] == true) {
              coverPhotoUrl = url;
            }
          }
        }
      }

      coverPhotoUrl ??= _resolveCoverFromPhotoUrls(photoUrls);

      // Create new draft with copied data
      final draftResponse = await _supabase
          .from('listing_drafts')
          .insert({
            'seller_id': sellerId,
            'current_step': 1,
            'is_complete': false,
            'last_saved': DateTime.now().toIso8601String(),
            // Copy vehicle details if available
            if (vehicleInfo != null) ...{
              'brand': vehicleInfo['brand'],
              'model': vehicleInfo['model'],
              'variant': vehicleInfo['variant'],
              'year': vehicleInfo['year'],
              'engine_type': vehicleInfo['engine_type'],
              'engine_displacement': vehicleInfo['engine_displacement'],
              'cylinder_count': vehicleInfo['cylinder_count'],
              'horsepower': vehicleInfo['horsepower'],
              'torque': vehicleInfo['torque'],
              'transmission': vehicleInfo['transmission'],
              'fuel_type': vehicleInfo['fuel_type'],
              'drive_type': vehicleInfo['drive_type'],
              'length': vehicleInfo['length'],
              'width': vehicleInfo['width'],
              'height': vehicleInfo['height'],
              'wheelbase': vehicleInfo['wheelbase'],
              'ground_clearance': vehicleInfo['ground_clearance'],
              'seating_capacity': vehicleInfo['seating_capacity'],
              'door_count': vehicleInfo['door_count'],
              'fuel_tank_capacity': vehicleInfo['fuel_tank_capacity'],
              'curb_weight': vehicleInfo['curb_weight'],
              'gross_weight': vehicleInfo['gross_weight'],
              'exterior_color': vehicleInfo['exterior_color'],
              'paint_type': vehicleInfo['paint_type'],
              'rim_type': vehicleInfo['rim_type'],
              'rim_size': vehicleInfo['rim_size'],
              'tire_size': vehicleInfo['tire_size'],
              'tire_brand': vehicleInfo['tire_brand'],
              'condition': vehicleInfo['condition'],
              'mileage': vehicleInfo['mileage'],
              'previous_owners': vehicleInfo['previous_owners'],
              'has_modifications': vehicleInfo['has_modifications'],
              'modifications_details': vehicleInfo['modifications_details'],
              'has_warranty': vehicleInfo['has_warranty'],
              'warranty_details': vehicleInfo['warranty_details'],
              'usage_type': vehicleInfo['usage_type'],
              'plate_number': vehicleInfo['plate_number'],
              'chassis_number': vehicleInfo['chassis_number'],
              'orcr_status': vehicleInfo['orcr_status'],
              'registration_status': vehicleInfo['registration_status'],
              'registration_expiry': vehicleInfo['registration_expiry'],
              'province': vehicleInfo['province'],
              'city_municipality': vehicleInfo['city_municipality'],
              'known_issues': vehicleInfo['known_issues'],
              'features': vehicleInfo['features'],
            },
            // Copy auction details (only columns that exist in listing_drafts)
            'description': auctionResponse['description'],
            'starting_price': auctionResponse['starting_price'],
            'reserve_price': auctionResponse['reserve_price'],
            // Note: bid_increment and deposit_amount are auction-specific, not draft fields
            'photo_urls': photoUrls,
            'cover_photo_url': coverPhotoUrl,
          })
          .select()
          .single();

      final draftId = draftResponse['id'] as String;
      debugPrint(
        '[ListingSupabaseDataSource] Successfully created draft: $draftId',
      );
      return draftId;
    } on PostgrestException catch (e) {
      throw Exception('Failed to copy listing to draft: ${e.message}');
    } catch (e) {
      throw Exception('Failed to copy listing to draft: $e');
    }
  }

  /// Create a new auction from a cancelled listing with same details
  /// Allows seller to re-list the same vehicle with potentially different terms
  Future<String> createAuctionFromCancelled(
    String auctionId,
    String sellerId,
    double? newStartingPrice,
    DateTime? newEndTime,
  ) async {
    try {
      debugPrint(
        '[ListingSupabaseDataSource] Creating new auction from cancelled: $auctionId',
      );

      // Guard against duplicate plate numbers across statuses
      final cancelledVehicle = await _supabase
          .from('auction_vehicles')
          .select('plate_number')
          .eq('auction_id', auctionId)
          .maybeSingle();

      final plateNumber = cancelledVehicle?['plate_number'] as String?;
      if (plateNumber != null && plateNumber.isNotEmpty) {
        await _ensureUniquePlate(
          sellerId,
          plateNumber,
          excludeAuctionId: auctionId,
        );
      }

      // Fetch the cancelled auction with all its details
      final auctionResponse = await _supabase
          .from('auctions')
          .select('''
            id, title, description, category_id, starting_price, reserve_price, 
            bid_increment, deposit_amount, seller_id,
            auction_vehicles(*),
            auction_photos(*)
            ''')
          .eq('id', auctionId)
          .eq('seller_id', sellerId)
          .single();

      // Get the pending_approval status ID
      final statusResponse = await _supabase
          .from('auction_statuses')
          .select('id')
          .eq('status_name', 'pending_approval')
          .single();
      final statusId = statusResponse['id'] as String;

      // Determine auction duration (default to 7 days if not provided)
      final endTime = newEndTime ?? DateTime.now().add(const Duration(days: 7));

      // Create new auction with same details (no vehicle_id - vehicle data goes to auction_vehicles table)
      final newAuctionResponse = await _supabase
          .from('auctions')
          .insert({
            'title': auctionResponse['title'],
            'description': auctionResponse['description'],
            'seller_id': sellerId,
            'category_id': auctionResponse['category_id'],
            'starting_price':
                newStartingPrice ?? auctionResponse['starting_price'],
            'reserve_price': auctionResponse['reserve_price'],
            'current_price':
                newStartingPrice ?? auctionResponse['starting_price'],
            'bid_increment': auctionResponse['bid_increment'],
            'deposit_amount': auctionResponse['deposit_amount'],
            'status_id': statusId,
            'end_time': endTime.toIso8601String(),
            'start_time': DateTime.now().toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      final newAuctionId = newAuctionResponse['id'] as String;

      // Copy vehicle data from old auction to new auction
      final vehicleData = auctionResponse['auction_vehicles'];
      if (vehicleData != null) {
        final vehicleMap = vehicleData is Map<String, dynamic>
            ? vehicleData
            : (vehicleData is List && vehicleData.isNotEmpty
                  ? vehicleData[0] as Map<String, dynamic>
                  : null);

        if (vehicleMap != null) {
          // Create new vehicle record for the new auction
          final vehicleInsertData = Map<String, dynamic>.from(vehicleMap);
          vehicleInsertData['auction_id'] = newAuctionId;
          // Remove any id field if it exists
          vehicleInsertData.remove('id');

          await _supabase.from('auction_vehicles').insert(vehicleInsertData);
        }
      }

      // Copy all photos from old auction to new auction
      final photosData = auctionResponse['auction_photos'] as List? ?? [];
      if (photosData.isNotEmpty) {
        final photoInserts = <Map<String, dynamic>>[];
        for (final photo in photosData) {
          if (photo is Map<String, dynamic>) {
            photoInserts.add({
              'auction_id': newAuctionId,
              'photo_url': photo['photo_url'],
              'category': photo['category'],
              'display_order': photo['display_order'],
              'is_primary': photo['is_primary'] ?? false,
            });
          }
        }

        if (photoInserts.isNotEmpty) {
          await _supabase.from('auction_photos').insert(photoInserts);
        }
      }

      debugPrint(
        '[ListingSupabaseDataSource] Successfully created new auction: $newAuctionId',
      );
      return newAuctionId;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create new auction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create new auction: $e');
    }
  }

  /// Delete a listing permanently along with related data
  /// Removes auction, photos, bids, watchers, and vehicle data
  Future<void> deleteListing(String auctionId, String sellerId) async {
    try {
      debugPrint('[ListingSupabaseDataSource] Deleting listing: $auctionId');

      // Verify seller ownership before deleting
      final auctionResponse = await _supabase
          .from('auctions')
          .select('id, seller_id')
          .eq('id', auctionId)
          .single();

      if (auctionResponse['seller_id'] != sellerId) {
        throw Exception('Unauthorized: You do not own this listing');
      }

      // Delete related data in order of dependencies (ignore missing relations)
      Future<void> safeDelete(String table) async {
        try {
          await _supabase.from(table).delete().eq('auction_id', auctionId);
        } on PostgrestException catch (e) {
          if (e.message.contains('relation') ||
              e.message.contains('does not exist')) {
            return; // table not present; ignore
          }
          rethrow;
        }
      }

      await safeDelete('bids');
      await safeDelete('auction_watchers');
      await safeDelete('auction_photos');
      await safeDelete('transactions');
      await safeDelete('deposits');
      await safeDelete('payments');
      await safeDelete('seller_payouts');

      // 5. Delete the auction itself
      await _supabase.from('auctions').delete().eq('id', auctionId);

      debugPrint(
        '[ListingSupabaseDataSource] Successfully deleted listing: $auctionId',
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete listing: $e');
    }
  }

  // ============================================================================
  // PHOTO UPLOAD
  // ============================================================================

  /// Upload listing photo to storage
  Future<String> uploadPhoto({
    required String userId,
    required String listingId,
    required String category,
    required File imageFile,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final filename = '${category}_$timestamp.$extension';

      // Path: {listing_id}/{category}/{filename}
      // Note: listing_id first for RLS policy compatibility
      final path = '$listingId/$category/$filename';

      await _supabase.storage
          .from('auction-images')
          .upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final url = _supabase.storage.from('auction-images').getPublicUrl(path);

      return url;
    } on StorageException catch (e) {
      throw Exception('Failed to upload photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload photo: $e');
    }
  }

  /// Delete listing photo from storage
  Future<void> deletePhoto(String photoUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;

      // URL format: .../storage/v1/object/public/listing-photos/{path}
      if (pathSegments.length >= 6) {
        final path = pathSegments.sublist(6).join('/');
        await _supabase.storage.from('listing-photos').remove([path]);
      }
    } on StorageException catch (e) {
      throw Exception('Failed to delete photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete photo: $e');
    }
  }

  // ============================================================================
  // DOCUMENT UPLOAD (Deed of Sale)
  // ============================================================================

  /// Upload deed of sale document to storage
  /// Supports PDF and image files (PNG, JPG, JPEG)
  Future<String> uploadDeedOfSale({
    required String userId,
    required String listingId,
    required File documentFile,
  }) async {
    try {
      // Validate file extension
      final extension = documentFile.path.split('.').last.toLowerCase();
      final allowedExtensions = ['pdf', 'png', 'jpg', 'jpeg'];
      if (!allowedExtensions.contains(extension)) {
        throw Exception('Invalid file type. Allowed: PDF, PNG, JPG, JPEG');
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'deed_of_sale_$timestamp.$extension';

      // Path: {listing_id}/documents/{filename}
      final path = '$listingId/documents/$filename';

      // Determine content type
      String contentType;
      switch (extension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      await _supabase.storage
          .from('auction-images')
          .upload(
            path,
            documentFile,
            fileOptions: FileOptions(upsert: true, contentType: contentType),
          );

      // Get public URL
      final url = _supabase.storage.from('auction-images').getPublicUrl(path);

      return url;
    } on StorageException catch (e) {
      throw Exception('Failed to upload deed of sale: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload deed of sale: $e');
    }
  }

  /// Delete deed of sale document from storage
  Future<void> deleteDeedOfSale(String documentUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(documentUrl);
      final pathSegments = uri.pathSegments;

      // URL format: .../storage/v1/object/public/auction-images/{path}
      if (pathSegments.length >= 6) {
        final path = pathSegments.sublist(6).join('/');
        await _supabase.storage.from('auction-images').remove([path]);
      }
    } on StorageException catch (e) {
      throw Exception('Failed to delete deed of sale: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete deed of sale: $e');
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Merge auction data with vehicle data from joined tables
  /// Converts nested auction_vehicles and auction_photos into flat structure
  ListingModel _mergeAuctionWithVehicleData(Map<String, dynamic> json) {
    // Create a copy to avoid modifying the original
    final Map<String, dynamic> mergedJson = Map<String, dynamic>.from(json);

    // Extract nested vehicle data - Supabase returns one-to-one as object, one-to-many as array
    final vehicleData = json['auction_vehicles'];
    Map<String, dynamic>? vehicle;

    if (vehicleData != null) {
      if (vehicleData is List && vehicleData.isNotEmpty) {
        // Returned as array (shouldn't happen for one-to-one, but handle it)
        vehicle = vehicleData[0] as Map<String, dynamic>;
      } else if (vehicleData is Map<String, dynamic>) {
        // Returned as object (expected for one-to-one relationship)
        vehicle = vehicleData;
      }
    }

    // Merge vehicle fields into main json if vehicle data exists
    if (vehicle != null) {
      // Copy all vehicle fields to the merged json
      vehicle.forEach((key, value) {
        mergedJson[key] = value;
      });
    } else {
      // Fallback: Try to parse from auction title
      final title = mergedJson['title'] as String?;
      if (title != null &&
          title.isNotEmpty &&
          !title.startsWith('Vehicle Auction #')) {
        // Title format is "2018 Toyota Camry LE"
        final parts = title.split(' ');
        if (parts.isNotEmpty) {
          // Try to extract year (first 4 digits)
          final yearStr = parts.firstWhere(
            (p) => p.length == 4 && int.tryParse(p) != null,
            orElse: () => '0',
          );
          mergedJson['year'] = int.tryParse(yearStr) ?? 0;

          // Try to extract brand (usually after year)
          final yearIndex = parts.indexOf(yearStr);
          if (yearIndex >= 0 && yearIndex < parts.length - 1) {
            mergedJson['brand'] = parts[yearIndex + 1];
            // Model is everything after brand
            if (yearIndex + 2 < parts.length) {
              mergedJson['model'] = parts.sublist(yearIndex + 2).join(' ');
            } else {
              mergedJson['model'] = '';
            }
          } else {
            mergedJson['brand'] = '';
            mergedJson['model'] = '';
          }
        }
      } else {
        // No title to parse, use empty defaults
        mergedJson['brand'] = '';
        mergedJson['model'] = '';
        mergedJson['year'] = 0;
      }
    }

    // Process photos - can be array or null
    final photosData = json['auction_photos'];
    List<dynamic>? photosList;

    if (photosData != null) {
      if (photosData is List) {
        photosList = photosData;
      }
    }

    if (photosList != null && photosList.isNotEmpty) {
      final sortedPhotos =
          List<Map<String, dynamic>>.from(
            photosList.whereType<Map<String, dynamic>>(),
          )..sort((a, b) {
            final aPrimary = a['is_primary'] == true ? 1 : 0;
            final bPrimary = b['is_primary'] == true ? 1 : 0;
            if (aPrimary != bPrimary) {
              return bPrimary.compareTo(aPrimary);
            }
            final aOrder = (a['display_order'] as num?)?.toInt() ?? 99999;
            final bOrder = (b['display_order'] as num?)?.toInt() ?? 99999;
            return aOrder.compareTo(bOrder);
          });

      // Find primary photo for cover
      try {
        final primaryPhoto = sortedPhotos.firstWhere(
          (photo) => photo['is_primary'] == true,
          orElse: () => sortedPhotos.first,
        );
        mergedJson['cover_photo_url'] = primaryPhoto['photo_url'];
      } catch (e) {
        // Fallback to first photo if any error
        mergedJson['cover_photo_url'] = sortedPhotos.first['photo_url'];
      }

      // Build photo_urls map grouped by category
      final Map<String, List<String>> photoUrlsMap = {};
      for (final photo in sortedPhotos) {
        final category = _normalizePhotoCategory(photo['category'] as String?);
        final url = photo['photo_url'] as String?;
        if (url != null && url.isNotEmpty) {
          photoUrlsMap.putIfAbsent(category, () => []).add(url);
        }
      }
      mergedJson['photo_urls'] = photoUrlsMap;
    } else {
      mergedJson['photo_urls'] = {};
      mergedJson['cover_photo_url'] = null;
    }

    // Map auction table fields to expected listing model fields
    // Determine status from joined `auction_statuses` (may be Map or List)
    String resolvedStatus = 'pending';
    final auctionStatuses = json['auction_statuses'];
    if (auctionStatuses != null) {
      if (auctionStatuses is Map<String, dynamic>) {
        resolvedStatus =
            (auctionStatuses['status_name'] as String?) ?? resolvedStatus;
      } else if (auctionStatuses is List && auctionStatuses.isNotEmpty) {
        final first = auctionStatuses[0];
        if (first is Map<String, dynamic>) {
          resolvedStatus = (first['status_name'] as String?) ?? resolvedStatus;
        } else if (first is String) {
          resolvedStatus = first;
        }
      } else if (auctionStatuses is String) {
        resolvedStatus = auctionStatuses;
      }
    } else if (mergedJson['status'] != null && mergedJson['status'] is String) {
      resolvedStatus = mergedJson['status'] as String;
    }

    mergedJson['status'] = resolvedStatus.toLowerCase();

    // Admin status may be stored separately; preserve if present otherwise default
    if (json.containsKey('admin_status') && json['admin_status'] is String) {
      mergedJson['admin_status'] = json['admin_status'] as String;
    } else if (json.containsKey('reviewed_by') ||
        json.containsKey('reviewed_at')) {
      mergedJson['admin_status'] = 'approved';
    } else {
      mergedJson['admin_status'] = mergedJson['admin_status'] ?? 'pending';
    }

    // Convert auction timestamps to expected field names
    mergedJson['auction_start_time'] = mergedJson['start_time'];
    mergedJson['auction_end_time'] = mergedJson['end_time'];
    mergedJson['current_bid'] = mergedJson['current_price'] ?? 0;

    // Ensure numeric fields have defaults
    mergedJson['total_bids'] = mergedJson['total_bids'] ?? 0;
    mergedJson['view_count'] = mergedJson['view_count'] ?? 0;
    mergedJson['watchers_count'] =
        0; // Auctions table doesn't have watchers yet
    mergedJson['views_count'] = mergedJson['view_count'] ?? 0;

    // Ensure required string fields have defaults
    mergedJson['transmission'] = mergedJson['transmission'] ?? '';
    mergedJson['fuel_type'] = mergedJson['fuel_type'] ?? '';
    mergedJson['exterior_color'] = mergedJson['exterior_color'] ?? '';
    mergedJson['condition'] = mergedJson['condition'] ?? '';
    mergedJson['plate_number'] = mergedJson['plate_number'] ?? '';
    mergedJson['orcr_status'] = mergedJson['orcr_status'] ?? '';
    mergedJson['registration_status'] = mergedJson['registration_status'] ?? '';
    mergedJson['province'] = mergedJson['province'] ?? '';
    mergedJson['city_municipality'] = mergedJson['city_municipality'] ?? '';
    mergedJson['description'] = mergedJson['description'] ?? '';
    mergedJson['auto_live_after_approval'] =
        mergedJson['auto_live_after_approval'] ?? false;

    // Ensure numeric fields
    mergedJson['mileage'] = mergedJson['mileage'] ?? 0;
    mergedJson['has_modifications'] = mergedJson['has_modifications'] ?? false;
    mergedJson['has_warranty'] = mergedJson['has_warranty'] ?? false;

    return ListingModel.fromJson(mergedJson);
  }

  Future<List<Map<String, dynamic>>> _applyAccurateBidCounts(
    List rawRows,
  ) async {
    final rows = rawRows
        .whereType<Map>()
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
    if (rows.isEmpty) return rows;

    final auctionIds = rows
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toList();
    if (auctionIds.isEmpty) return rows;

    try {
      final bids = await _supabase
          .from('bids')
          .select('auction_id')
          .inFilter('auction_id', auctionIds);

      final counts = <String, int>{};
      for (final row in (bids as List)) {
        if (row is Map<String, dynamic>) {
          final auctionId = row['auction_id'] as String?;
          if (auctionId != null && auctionId.isNotEmpty) {
            counts[auctionId] = (counts[auctionId] ?? 0) + 1;
          }
        }
      }

      for (final row in rows) {
        final auctionId = row['id'] as String?;
        if (auctionId != null && auctionId.isNotEmpty) {
          row['total_bids'] = counts[auctionId] ?? 0;
        }
      }
    } catch (_) {
      // Keep server-provided total_bids when bid count hydration fails.
    }

    return rows;
  }

  Future<void> _syncSelectedPrimaryPhoto({
    required String draftId,
    required String auctionId,
  }) async {
    try {
      final draft = await _supabase
          .from('listing_drafts')
          .select('cover_photo_url')
          .eq('id', draftId)
          .maybeSingle();

      final selectedCoverUrl = draft?['cover_photo_url'] as String?;
      if (selectedCoverUrl == null || selectedCoverUrl.isEmpty) {
        return;
      }

      await _supabase
          .from('auction_photos')
          .update({'is_primary': false})
          .eq('auction_id', auctionId);

      final updatedRows = await _supabase
          .from('auction_photos')
          .update({'is_primary': true})
          .eq('auction_id', auctionId)
          .eq('photo_url', selectedCoverUrl)
          .select('id');

      if ((updatedRows as List).isEmpty) {
        final firstPhoto = await _supabase
            .from('auction_photos')
            .select('id')
            .eq('auction_id', auctionId)
            .order('display_order', ascending: true)
            .limit(1)
            .maybeSingle();

        final firstPhotoId = firstPhoto?['id'] as String?;
        if (firstPhotoId == null) {
          return;
        }

        await _supabase
            .from('auction_photos')
            .update({'is_primary': true})
            .eq('id', firstPhotoId);
      }
    } catch (_) {
      // Do not fail submission if post-submit primary sync fails.
    }
  }

  String _normalizePhotoCategory(String? rawCategory) {
    if (rawCategory == null || rawCategory.trim().isEmpty) return 'details';
    return rawCategory
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('/', '_');
  }

  String? _resolveCoverFromPhotoUrls(Map<String, List<String>> photoUrls) {
    for (final urls in photoUrls.values) {
      if (urls.isNotEmpty) {
        return urls.first;
      }
    }

    return null;
  }

  /// Check if a plate number is unique for a seller (Public for validation)
  /// Returns true if unique, false if duplicate exists
  Future<bool> isPlateUnique(
    String sellerId,
    String plateNumber, {
    String? excludeAuctionId,
  }) async {
    try {
      // Create variations to check (Spaced and No-Space) to prevent "NGA 1234" vs "NGA1234" dupes
      final raw = plateNumber.toUpperCase().replaceAll(' ', '');
      final variants = {
        plateNumber, // As provided
        raw, // No spaces
        // Attempt to reconstruct standard format if raw is just letters+numbers
        if (RegExp(r'^[A-Z]+[0-9]+$').hasMatch(raw)) ...[
          // Split letters and numbers
          raw.replaceAllMapped(
            RegExp(r'^([A-Z]+)([0-9]+)$'),
            (m) => '${m[1]} ${m[2]}',
          ),
        ],
      }.toList();

      final dupes = await _supabase
          .from('auctions')
          .select(
            '''id, auction_statuses!inner(status_name), auction_vehicles!inner(plate_number)''',
          )
          // Removed .eq('seller_id', sellerId) to check globally
          .inFilter('auction_vehicles.plate_number', variants)
          .inFilter('auction_statuses.status_name', [
            'pending_approval',
            'approved',
            'scheduled',
            'live',
            'active',
            'ended',
            'cancelled',
            'in_transaction',
            'sold',
          ]);

      final conflict = dupes.any(
        (row) => (row['id'] as String?) != excludeAuctionId,
      );

      return !conflict;
    } catch (e) {
      debugPrint('Error checking plate uniqueness: $e');
      throw Exception('Failed to check plate uniqueness: $e');
    }
  }

  /// Ensure a plate number is unique for a seller across all listing states
  /// Throws exception if not unique (Used for submission checks)
  Future<void> _ensureUniquePlate(
    String sellerId,
    String plateNumber, {
    String? excludeAuctionId,
  }) async {
    final isUnique = await isPlateUnique(
      sellerId,
      plateNumber,
      excludeAuctionId: excludeAuctionId,
    );

    if (!isUnique) {
      throw Exception(
        'A listing for plate $plateNumber already exists in your account. Please delete or finish it before submitting a new one.',
      );
    }
  }

  /// Stream seller's listings updates
  /// Listens to changes in 'auctions' table for the specific seller
  Stream<List<Map<String, dynamic>>> streamSellerListings(String sellerId) {
    return _supabase
        .from('auctions')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId);
  }

  /// Stream seller's drafts updates
  /// Listens to changes in 'listing_drafts' table for the specific seller
  Stream<List<Map<String, dynamic>>> streamSellerDrafts(String sellerId) {
    return _supabase
        .from('listing_drafts')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId);
  }

  /// Fetch a single seller listing by ID with full details
  /// Used for navigating from list to detail view
  Future<ListingModel> getSellerListing(String auctionId) async {
    try {
      final response = await _supabase
          .from('auctions')
          .select('''
            *,
            auction_statuses(status_name),
            auction_vehicles!left(*),
            auction_photos(photo_url, category, display_order, is_primary),
            auction_transactions!auction_transactions_auction_id_fkey(id, status)
          ''')
          .eq('id', auctionId)
          .maybeSingle();

      if (response == null) {
        throw Exception('Listing not found');
      }

      // Check for transaction (for cancelled listings)
      final transactions = response['auction_transactions'] as List?;
      String? transactionId;
      if (transactions != null && transactions.isNotEmpty) {
        final failedTransaction = transactions.firstWhere(
          (txn) => txn['status'] == 'deal_failed',
          orElse: () => transactions.first,
        );
        transactionId = failedTransaction['id'] as String?;
      }

      final jsonWithTransaction = Map<String, dynamic>.from(response);
      jsonWithTransaction['transaction_id'] = transactionId;

      return _mergeAuctionWithVehicleData(jsonWithTransaction);
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch listing detail: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch listing detail: $e');
    }
  }

  /// Get bid history for a listing
  /// Performs manual join with user_profiles to ensure data availability
  Future<List<Map<String, dynamic>>> getBids(String auctionId) async {
    try {
      // 1. Fetch bids
      final bidsResponse = await _supabase
          .from('bids')
          .select('id, bid_amount, created_at, bidder_id')
          .eq('auction_id', auctionId)
          .order('bid_amount', ascending: false);

      final bids = List<Map<String, dynamic>>.from(bidsResponse);

      if (bids.isEmpty) return [];

      // 2. Extract unique bidder IDs
      final bidderIds = bids
          .map((b) => b['bidder_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (bidderIds.isEmpty) return bids;

      // 3. Fetch user profiles for these bidders
      // Fetch from 'users' table as 'user_profiles' is deprecated/merged
      final profilesResponse = await _supabase
          .from('users')
          .select(
            'id, username, first_name, middle_name, last_name, profile_photo_url',
          )
          .inFilter('id', bidderIds);

      final profilesMap = {
        for (var p in profilesResponse)
          p['id'] as String: () {
            // Construct full_name for UI compatibility
            final firstName = p['first_name'] as String? ?? '';
            final middleName = p['middle_name'] as String? ?? '';
            final lastName = p['last_name'] as String? ?? '';
            final fullName = middleName.isNotEmpty
                ? '$firstName $middleName $lastName'
                : '$firstName $lastName';

            return {
              'id': p['id'],
              'username': p['username'],
              'full_name': fullName.trim(),
              'profile_photo_url': p['profile_photo_url'],
            };
          }(),
      };

      // 4. Merge profiles into bids
      return bids.map((bid) {
        final bidderId = bid['bidder_id'] as String?;
        final profile = profilesMap[bidderId];

        // Add the nested user_profiles object structure that the UI expects
        final bidWithProfile = Map<String, dynamic>.from(bid);
        if (profile != null) {
          bidWithProfile['user_profiles'] = profile;
        } else {
          // Fallback if profile not found (optional: try fetching from 'users' table if needed)
          bidWithProfile['user_profiles'] = {
            'username': 'Unknown Bidder',
            'full_name': 'Unknown Bidder',
          };
        }
        return bidWithProfile;
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch bids: $e');
    }
  }
}
