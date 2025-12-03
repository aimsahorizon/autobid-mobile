import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for seller listing operations
/// Handles creating, updating, and managing vehicle listings
class ListingSupabaseDataSource {
  final SupabaseClient _supabase;

  ListingSupabaseDataSource(this._supabase);

  /// Get seller's listings filtered by status
  /// Fetches vehicles owned by seller from vehicles table
  Future<List<Map<String, dynamic>>> getSellerListings({
    required String sellerId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('vehicles')
          .select('id, brand, model, year, starting_price, current_bid, reserve_price, total_bids, watchers_count, views_count, status, created_at, end_time, main_image_url')
          .eq('seller_id', sellerId);

      // Filter by status if provided
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get seller listings: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get seller listings: $e');
    }
  }

  /// Create a new draft listing
  /// Inserts vehicle with draft status into vehicles table
  Future<String> createDraft({
    required String sellerId,
    required String brand,
    required String model,
    required int year,
    required double startingPrice,
    String? variant,
    double? reservePrice,
  }) async {
    try {
      final response = await _supabase.from('vehicles').insert({
        'seller_id': sellerId,
        'brand': brand,
        'model': model,
        'year': year,
        'variant': variant,
        'starting_price': startingPrice,
        'reserve_price': reservePrice,
        'status': 'draft',
        'current_bid': 0,
        'main_image_url': '', // Will be updated when photos uploaded
      }).select('id').single();

      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Failed to create draft: ${e.message}');
    } catch (e) {
      throw Exception('Failed to create draft: $e');
    }
  }

  /// Update vehicle listing details
  /// Updates fields in vehicles table
  Future<void> updateListing({
    required String vehicleId,
    Map<String, dynamic>? basicInfo,
    Map<String, dynamic>? mechanicalSpecs,
    Map<String, dynamic>? dimensions,
    Map<String, dynamic>? exterior,
    Map<String, dynamic>? condition,
    Map<String, dynamic>? documentation,
    Map<String, dynamic>? finalDetails,
  }) async {
    try {
      // Merge all updates into single map
      final Map<String, dynamic> updates = {};

      if (basicInfo != null) updates.addAll(basicInfo);
      if (mechanicalSpecs != null) updates.addAll(mechanicalSpecs);
      if (dimensions != null) updates.addAll(dimensions);
      if (exterior != null) updates.addAll(exterior);
      if (condition != null) updates.addAll(condition);
      if (documentation != null) updates.addAll(documentation);
      if (finalDetails != null) updates.addAll(finalDetails);

      if (updates.isEmpty) return;

      await _supabase
          .from('vehicles')
          .update(updates)
          .eq('id', vehicleId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to update listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to update listing: $e');
    }
  }

  /// Upload vehicle photo to storage and save to database
  /// Uploads to vehicle-photos bucket and inserts into vehicle_photos table
  Future<String> uploadVehiclePhoto({
    required String vehicleId,
    required String userId,
    required File imageFile,
    required String category, // exterior, interior, engine, details, documents
    int displayOrder = 0,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last;
      final filename = '${category}_$timestamp.$extension';
      final filepath = '$userId/$vehicleId/$filename';

      // Upload to vehicle-photos bucket
      await _supabase.storage.from('vehicle-photos').upload(
            filepath,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );

      // Get public URL
      final publicUrl = _supabase.storage.from('vehicle-photos').getPublicUrl(filepath);

      // Insert into vehicle_photos table
      await _supabase.from('vehicle_photos').insert({
        'vehicle_id': vehicleId,
        'category': category,
        'photo_url': publicUrl,
        'display_order': displayOrder,
      });

      // Update main_image_url if this is first exterior photo
      if (category == 'exterior' && displayOrder == 0) {
        await _supabase
            .from('vehicles')
            .update({'main_image_url': publicUrl})
            .eq('id', vehicleId);
      }

      return publicUrl;
    } on StorageException catch (e) {
      throw Exception('Failed to upload photo: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Failed to save photo: ${e.message}');
    } catch (e) {
      throw Exception('Failed to upload vehicle photo: $e');
    }
  }

  /// Delete vehicle photo from storage and database
  /// Removes from vehicle_photos table and vehicle-photos bucket
  Future<void> deleteVehiclePhoto({
    required String photoId,
    required String photoUrl,
  }) async {
    try {
      // Delete from database
      await _supabase
          .from('vehicle_photos')
          .delete()
          .eq('id', photoId);

      // Extract filepath from URL and delete from storage
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 5) {
        final filepath = pathSegments.sublist(5).join('/');
        await _supabase.storage.from('vehicle-photos').remove([filepath]);
      }
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete photo: ${e.message}');
    } catch (e) {
      // Don't throw on storage errors - photo may already be deleted
      print('Error deleting photo from storage: $e');
    }
  }

  /// Submit listing for admin approval
  /// Changes status from draft to pending
  Future<void> submitForApproval(String vehicleId) async {
    try {
      await _supabase
          .from('vehicles')
          .update({'status': 'pending'})
          .eq('id', vehicleId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit for approval: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit for approval: $e');
    }
  }

  /// Activate listing (start auction)
  /// Sets status to active and auction times
  Future<void> activateListing({
    required String vehicleId,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    try {
      await _supabase.from('vehicles').update({
        'status': 'active',
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
      }).eq('id', vehicleId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to activate listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to activate listing: $e');
    }
  }

  /// Cancel listing
  /// Sets status to cancelled
  Future<void> cancelListing(String vehicleId) async {
    try {
      await _supabase
          .from('vehicles')
          .update({'status': 'cancelled'})
          .eq('id', vehicleId);
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel listing: ${e.message}');
    } catch (e) {
      throw Exception('Failed to cancel listing: $e');
    }
  }

  /// Delete draft listing
  /// Deletes vehicle and all associated photos
  Future<void> deleteDraft(String vehicleId) async {
    try {
      // Delete all photos first (cascade will handle vehicle_photos table)
      final photos = await _supabase
          .from('vehicle_photos')
          .select('photo_url')
          .eq('vehicle_id', vehicleId);

      for (var photo in photos) {
        final photoUrl = photo['photo_url'] as String;
        final uri = Uri.parse(photoUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 5) {
          final filepath = pathSegments.sublist(5).join('/');
          try {
            await _supabase.storage.from('vehicle-photos').remove([filepath]);
          } catch (e) {
            // Continue even if storage deletion fails
            print('Error deleting photo: $e');
          }
        }
      }

      // Delete vehicle (will cascade delete vehicle_photos)
      await _supabase
          .from('vehicles')
          .delete()
          .eq('id', vehicleId)
          .eq('status', 'draft'); // Safety check - only delete drafts
    } on PostgrestException catch (e) {
      throw Exception('Failed to delete draft: ${e.message}');
    } catch (e) {
      throw Exception('Failed to delete draft: $e');
    }
  }

  /// Get listing detail
  /// Fetches vehicle with all photos
  Future<Map<String, dynamic>> getListingDetail(String vehicleId) async {
    try {
      final vehicle = await _supabase
          .from('vehicles')
          .select()
          .eq('id', vehicleId)
          .single();

      final photos = await _supabase
          .from('vehicle_photos')
          .select()
          .eq('vehicle_id', vehicleId)
          .order('display_order');

      vehicle['photos'] = photos;
      return vehicle;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get listing detail: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get listing detail: $e');
    }
  }
}
