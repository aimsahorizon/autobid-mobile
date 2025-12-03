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

  // ============================================================================
  // LISTING SUBMISSION
  // ============================================================================

  /// Submit draft as listing (calls database function)
  Future<String> submitListing(String draftId) async {
    try {
      final response = await _supabase
          .rpc('submit_listing_from_draft', params: {'draft_id': draftId});

      return response as String; // Returns new listing ID
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
      final response = await _supabase
          .from('listings')
          .select()
          .eq('seller_id', sellerId)
          .eq('admin_status', 'pending')
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ListingModel.fromJson(json))
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

      // Path: {user_id}/{listing_id}/{category}/{filename}
      final path = '$userId/$listingId/$category/$filename';

      await _supabase.storage.from('listing-photos').upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final url = _supabase.storage.from('listing-photos').getPublicUrl(path);

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
}
