import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result from a car search combining brand, model, variant info
class CarSearchResult {
  final String brandId;
  final String brandName;
  final String modelId;
  final String modelName;
  final String? bodyType;
  final String variantId;
  final String variantName;
  final String? transmission;
  final String? fuelType;

  const CarSearchResult({
    required this.brandId,
    required this.brandName,
    required this.modelId,
    required this.modelName,
    this.bodyType,
    required this.variantId,
    required this.variantName,
    this.transmission,
    this.fuelType,
  });

  String get displayName => '$brandName $modelName $variantName';
}

/// Service that searches Supabase vehicle tables for car autofill
class CarApiService {
  final SupabaseClient _supabase;

  CarApiService(this._supabase);

  /// Search vehicles by query string, matching across brand+model+variant
  /// Returns combined results sorted by relevance
  Future<List<CarSearchResult>> searchCars(String query) async {
    if (query.trim().length < 2) return [];

    try {
      final normalizedQuery = query.trim().toLowerCase();
      final words = normalizedQuery.split(RegExp(r'\s+'));

      // Query variants joined with models and brands
      final response = await _supabase
          .from('vehicle_variants')
          .select('''
            id, name, transmission, fuel_type,
            vehicle_models!inner(id, name, body_type,
              vehicle_brands!inner(id, name)
            )
          ''')
          .eq('is_active', true)
          .limit(100);

      final results = <CarSearchResult>[];

      for (final row in response) {
        final model = row['vehicle_models'] as Map<String, dynamic>;
        final brand = model['vehicle_brands'] as Map<String, dynamic>;

        final brandName = (brand['name'] as String? ?? '').toLowerCase();
        final modelName = (model['name'] as String? ?? '').toLowerCase();
        final variantName = (row['name'] as String? ?? '').toLowerCase();
        final combined = '$brandName $modelName $variantName';

        // All query words must appear somewhere in the combined string
        final matches = words.every((w) => combined.contains(w));
        if (!matches) continue;

        results.add(
          CarSearchResult(
            brandId: brand['id'] as String,
            brandName: brand['name'] as String? ?? '',
            modelId: model['id'] as String,
            modelName: model['name'] as String? ?? '',
            bodyType: model['body_type'] as String?,
            variantId: row['id'] as String,
            variantName: row['name'] as String? ?? '',
            transmission: row['transmission'] as String?,
            fuelType: row['fuel_type'] as String?,
          ),
        );
      }

      // Sort: exact prefix matches first, then alphabetical
      results.sort((a, b) {
        final aStarts = a.displayName.toLowerCase().startsWith(normalizedQuery);
        final bStarts = b.displayName.toLowerCase().startsWith(normalizedQuery);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return a.displayName.compareTo(b.displayName);
      });

      return results.take(20).toList();
    } catch (e) {
      debugPrint('CarApiService.searchCars error: $e');
      return [];
    }
  }
}
