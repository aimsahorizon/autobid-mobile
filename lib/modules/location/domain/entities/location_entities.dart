import 'package:equatable/equatable.dart';

class RegionEntity extends Equatable {
  final String id;
  final String name;
  final String? code;

  const RegionEntity({
    required this.id,
    required this.name,
    this.code,
  });

  @override
  List<Object?> get props => [id, name, code];
}

class ProvinceEntity extends Equatable {
  final String id;
  final String regionId;
  final String name;

  const ProvinceEntity({
    required this.id,
    required this.regionId,
    required this.name,
  });

  @override
  List<Object?> get props => [id, regionId, name];
}

class CityEntity extends Equatable {
  final String id;
  final String provinceId;
  final String name;

  const CityEntity({
    required this.id,
    required this.provinceId,
    required this.name,
  });

  @override
  List<Object?> get props => [id, provinceId, name];
}

class BarangayEntity extends Equatable {
  final String id;
  final String cityId;
  final String name;

  const BarangayEntity({
    required this.id,
    required this.cityId,
    required this.name,
  });

  @override
  List<Object?> get props => [id, cityId, name];
}
