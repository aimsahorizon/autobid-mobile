import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/listing_draft_model.dart';
import '../models/listing_model.dart';
import '../../domain/entities/listing_draft_entity.dart';

/// Supabase datasource for listing operations
/// Handles all database interactions for listings and drafts
class ListingSupabaseDataSource {
  final SupabaseClient _supabase;

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
        photoUrls: draft.photoUrls,
        description: draft.description,
        knownIssues: draft.knownIssues,
        features: draft.features,
        startingPrice: draft.startingPrice,
        reservePrice: draft.reservePrice,
        auctionEndDate: draft.auctionEndDate,
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

  /// Delete draft (soft delete)
  Future<void> deleteDraft(String draftId) async {
    try {
      await _supabase
          .from('listing_drafts')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', draftId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete draft: ${e.message}');
    } catch (e) {
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
      final response = await _supabase
          .rpc('submit_listing_from_draft', params: {'draft_id': draftId});

      // RPC returns JSON: {success: bool, auction_id: string, message: string, error?: string}
      final result = response as Map<String, dynamic>;

      if (result['success'] == true) {
        return result['auction_id'] as String; // Returns new auction ID
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
      final response = await _supabase
          .from('listings')
          .select()
          .eq('seller_id', sellerId)
          .eq('status', status)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ListingModel.fromJson(json))
          .toList();
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

      return (response as List)
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
      final response = await _supabase
          .from('listings')
          .select()
          .eq('seller_id', sellerId)
          .eq('status', 'approved')
          .eq('admin_status', 'approved')
          .isFilter('deleted_at', null)
          .order('reviewed_at', ascending: false);

      return (response as List)
          .map((json) => ListingModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to fetch approved listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to fetch approved listings: $e');
    }
  }

  /// Get active listings (live auctions)
  Future<List<ListingModel>> getActiveListings(String sellerId) async {
    return getSellerListingsByStatus(sellerId, 'active');
  }

  /// Get ended listings (in transaction)
  Future<List<ListingModel>> getEndedListings(String sellerId) async {
    return getSellerListingsByStatus(sellerId, 'ended');
  }

  /// Get sold listings
  Future<List<ListingModel>> getSoldListings(String sellerId) async {
    return getSellerListingsByStatus(sellerId, 'sold');
  }

  /// Get cancelled/rejected listings
  Future<List<ListingModel>> getCancelledListings(String sellerId) async {
    return getSellerListingsByStatus(sellerId, 'cancelled');
  }

  // ============================================================================
  // LISTING ACTIONS
  // ============================================================================

  /// Make approved listing live (seller action)
  Future<void> makeListingLive(String listingId) async {
    try {
      await _supabase.rpc('make_listing_live', params: {'listing_id': listingId});
    } on PostgrestException catch (e) {
      throw Exception('Failed to make listing live: ${e.message}');
    } catch (e) {
      throw Exception('Failed to make listing live: $e');
    }
  }

  /// Complete sale (mark as sold)
  Future<void> completeSale(String listingId, double finalPrice) async {
    try {
      await _supabase.rpc('complete_sale', params: {
        'listing_id': listingId,
        'final_price': finalPrice,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to complete sale: ${e.message}');
    } catch (e) {
      throw Exception('Failed to complete sale: $e');
    }
  }

  /// Seller decides whether to proceed or cancel after auction ends
  Future<void> sellerDecideAfterAuction(String auctionId, bool proceed) async {
    try {
      final response = await _supabase.rpc('seller_decide_after_auction', params: {
        'p_auction_id': auctionId,
        'p_proceed': proceed,
      });

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

  /// Cancel listing (seller cancels before/during auction)
  Future<void> cancelListing(String listingId) async {
    try {
      await _supabase
          .from('listings')
          .update({'status': 'cancelled'})
          .eq('id', listingId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to cancel listing: $e');
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

      await _supabase.storage.from('auction-images').upload(
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
      if (title != null && title.isNotEmpty && !title.startsWith('Vehicle Auction #')) {
        // Title format is "2018 Toyota Camry LE"
        final parts = title.split(' ');
        if (parts.isNotEmpty) {
          // Try to extract year (first 4 digits)
          final yearStr = parts.firstWhere((p) => p.length == 4 && int.tryParse(p) != null, orElse: () => '0');
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
      // Find primary photo for cover
      try {
        final primaryPhoto = photosList.firstWhere(
          (photo) => photo['is_primary'] == true,
          orElse: () => photosList!.first,
        ) as Map<String, dynamic>;
        mergedJson['cover_photo_url'] = primaryPhoto['photo_url'];
      } catch (e) {
        // Fallback to first photo if any error
        mergedJson['cover_photo_url'] = (photosList.first as Map<String, dynamic>)['photo_url'];
      }

      // Build photo_urls map grouped by category
      final Map<String, List<String>> photoUrlsMap = {};
      for (final photo in photosList) {
        if (photo is Map<String, dynamic>) {
          final category = photo['category'] as String? ?? 'other';
          final url = photo['photo_url'] as String?;
          if (url != null) {
            photoUrlsMap.putIfAbsent(category, () => []).add(url);
          }
        }
      }
      mergedJson['photo_urls'] = photoUrlsMap;
    } else {
      mergedJson['photo_urls'] = {};
      mergedJson['cover_photo_url'] = null;
    }

    // Map auction table fields to expected listing model fields
    mergedJson['status'] = 'pending'; // Status from auction_statuses
    mergedJson['admin_status'] = 'pending'; // Admin approval status

    // Convert auction timestamps to expected field names
    mergedJson['auction_start_time'] = mergedJson['start_time'];
    mergedJson['auction_end_time'] = mergedJson['end_time'];
    mergedJson['current_bid'] = mergedJson['current_price'] ?? 0;

    // Ensure numeric fields have defaults
    mergedJson['total_bids'] = mergedJson['total_bids'] ?? 0;
    mergedJson['view_count'] = mergedJson['view_count'] ?? 0;
    mergedJson['watchers_count'] = 0; // Auctions table doesn't have watchers yet
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

    // Ensure numeric fields
    mergedJson['mileage'] = mergedJson['mileage'] ?? 0;
    mergedJson['has_modifications'] = mergedJson['has_modifications'] ?? false;
    mergedJson['has_warranty'] = mergedJson['has_warranty'] ?? false;

    return ListingModel.fromJson(mergedJson);
  }
}
