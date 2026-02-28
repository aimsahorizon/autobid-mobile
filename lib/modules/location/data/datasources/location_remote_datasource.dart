import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_models.dart';

abstract class LocationRemoteDataSource {
  Future<List<RegionModel>> getRegions();
  Future<List<ProvinceModel>> getProvinces(String regionId);
  Future<List<CityModel>> getCities(String provinceId);
  Future<List<BarangayModel>> getBarangays(String cityId);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final SupabaseClient supabaseClient;

  LocationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<RegionModel>> getRegions() async {
    final response = await supabaseClient
        .from('addr_regions')
        .select()
        .eq('is_active', true)
        .order('name');
    return (response as List).map((e) => RegionModel.fromJson(e)).toList();
  }

  @override
  Future<List<ProvinceModel>> getProvinces(String regionId) async {
    final response = await supabaseClient
        .from('addr_provinces')
        .select()
        .eq('region_id', regionId)
        .eq('is_active', true)
        .order('name');
    return (response as List).map((e) => ProvinceModel.fromJson(e)).toList();
  }

  @override
  Future<List<CityModel>> getCities(String provinceId) async {
    final response = await supabaseClient
        .from('addr_cities')
        .select()
        .eq('province_id', provinceId)
        .eq('is_active', true)
        .order('name');
    return (response as List).map((e) => CityModel.fromJson(e)).toList();
  }

  @override
  Future<List<BarangayModel>> getBarangays(String cityId) async {
    final response = await supabaseClient
        .from('addr_barangays')
        .select()
        .eq('city_id', cityId)
        .eq('is_active', true)
        .order('name');
    return (response as List).map((e) => BarangayModel.fromJson(e)).toList();
  }
}
