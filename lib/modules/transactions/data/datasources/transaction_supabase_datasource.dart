import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../lists/data/models/listing_model.dart';

/// Data source for transaction-related operations
/// Handles auctions in post-auction statuses: in_transaction, sold, deal_failed
/// Note: Reuses ListingModel since transactions are just listings in specific statuses
class TransactionSupabaseDataSource {
  final SupabaseClient _supabase;

  TransactionSupabaseDataSource(this._supabase);

  /// Get transactions by status
  /// Generic method to query auctions with transaction-related statuses
  Future<List<ListingModel>> getTransactionsByStatus(
    String userId,
    String status,
  ) async {
    try {
      // Resolve status id first to avoid join-related inconsistencies
      final statusResp = await _supabase
          .from('auction_statuses')
          .select('id')
          .eq('status_name', status)
          .maybeSingle();

      if (statusResp == null) {
        throw Exception('Auction status "$status" not found in database');
      }

      final statusId = statusResp['id'] as String;

      final response = await _supabase
          .from('auctions')
          .select('''
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
          ''')
          .eq('seller_id', userId)
          .eq('status_id', statusId)
          .order('updated_at', ascending: false);

      return (response as List)
          .map((json) => _mergeAuctionWithVehicleData(json))
          .toList();
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
    return getTransactionsByStatus(userId, 'sold');
  }

  /// Get failed transactions (deal_failed status)
  Future<List<ListingModel>> getFailedTransactions(String userId) async {
    return getTransactionsByStatus(userId, 'deal_failed');
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
}
