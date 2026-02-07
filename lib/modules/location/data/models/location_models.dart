import '../../domain/entities/location_entities.dart';

class RegionModel extends RegionEntity {
  const RegionModel({required super.id, required super.name, super.code});

  factory RegionModel.fromJson(Map<String, dynamic> json) {
    return RegionModel(id: json['id'], name: json['name'], code: json['code']);
  }
}

class ProvinceModel extends ProvinceEntity {
  const ProvinceModel({
    required super.id,
    required super.regionId,
    required super.name,
  });

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: json['id'],
      regionId: json['region_id'],
      name: json['name'],
    );
  }
}

class CityModel extends CityEntity {
  const CityModel({
    required super.id,
    required super.provinceId,
    required super.name,
  });

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      id: json['id'],
      provinceId: json['province_id'],
      name: json['name'],
    );
  }
}

class BarangayModel extends BarangayEntity {
  const BarangayModel({
    required super.id,
    required super.cityId,
    required super.name,
  });

  factory BarangayModel.fromJson(Map<String, dynamic> json) {
    return BarangayModel(
      id: json['id'],
      cityId: json['city_id'],
      name: json['name'],
    );
  }
}
