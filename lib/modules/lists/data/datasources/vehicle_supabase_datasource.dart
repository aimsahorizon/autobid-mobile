import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/vehicle_entities.dart';

class VehicleSupabaseDataSource {
  final SupabaseClient _supabase;

  VehicleSupabaseDataSource(this._supabase);

  Future<List<VehicleBrand>> getBrands() async {
    try {
      final response = await _supabase
          .from('vehicle_brands')
          .select()
          .eq('is_active', true)
          .order('name');
      
      return (response as List).map((json) => VehicleBrand(
        id: json['id'],
        name: json['name'],
        logoUrl: json['logo_url'],
      )).toList();
    } catch (e) {
      // Fallback or rethrow
      throw Exception('Failed to load brands: $e');
    }
  }

  Future<List<VehicleModel>> getModels(String brandId) async {
    try {
      final response = await _supabase
          .from('vehicle_models')
          .select()
          .eq('brand_id', brandId)
          .eq('is_active', true)
          .order('name');
      
      return (response as List).map((json) => VehicleModel(
        id: json['id'],
        brandId: json['brand_id'],
        name: json['name'],
        bodyType: json['body_type'],
      )).toList();
    } catch (e) {
      throw Exception('Failed to load models: $e');
    }
  }

  Future<List<VehicleVariant>> getVariants(String modelId) async {
    try {
      final response = await _supabase
          .from('vehicle_variants')
          .select()
          .eq('model_id', modelId)
          .eq('is_active', true)
          .order('name');
      
      return (response as List).map((json) => VehicleVariant(
        id: json['id'],
        modelId: json['model_id'],
        name: json['name'],
        transmission: json['transmission'],
        fuelType: json['fuel_type'],
      )).toList();
    } catch (e) {
      throw Exception('Failed to load variants: $e');
    }
  }
}
