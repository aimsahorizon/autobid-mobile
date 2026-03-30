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

  // In-memory cache (persists for app session, cleared on restart)
  List<RegionModel>? _cachedRegions;
  final Map<String, List<ProvinceModel>> _cachedProvinces = {};
  final Map<String, List<CityModel>> _cachedCities = {};
  final Map<String, List<BarangayModel>> _cachedBarangays = {};

  LocationRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<RegionModel>> getRegions() async {
    if (_cachedRegions != null) return _cachedRegions!;
    final response = await supabaseClient
        .from('addr_regions')
        .select()
        .eq('is_active', true)
        .order('name');
    _cachedRegions = (response as List).map((e) => RegionModel.fromJson(e)).toList();
    return _cachedRegions!;
  }

  @override
  Future<List<ProvinceModel>> getProvinces(String regionId) async {
    if (_cachedProvinces.containsKey(regionId)) return _cachedProvinces[regionId]!;
    final response = await supabaseClient
        .from('addr_provinces')
        .select()
        .eq('region_id', regionId)
        .eq('is_active', true)
        .order('name');
    final result = (response as List).map((e) => ProvinceModel.fromJson(e)).toList();
    _cachedProvinces[regionId] = result;
    return result;
  }

  @override
  Future<List<CityModel>> getCities(String provinceId) async {
    if (_cachedCities.containsKey(provinceId)) return _cachedCities[provinceId]!;
    final response = await supabaseClient
        .from('addr_cities')
        .select()
        .eq('province_id', provinceId)
        .eq('is_active', true)
        .order('name');
    final result = (response as List).map((e) => CityModel.fromJson(e)).toList();
    _cachedCities[provinceId] = result;
    return result;
  }

  @override
  Future<List<BarangayModel>> getBarangays(String cityId) async {
    if (_cachedBarangays.containsKey(cityId)) return _cachedBarangays[cityId]!;
    final response = await supabaseClient
        .from('addr_barangays')
        .select()
        .eq('city_id', cityId)
        .eq('is_active', true)
        .order('name');
    final result = (response as List).map((e) => BarangayModel.fromJson(e)).toList();
    _cachedBarangays[cityId] = result;
    return result;
  }
}
