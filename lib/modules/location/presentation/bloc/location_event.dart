import 'package:equatable/equatable.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class LoadRegions extends LocationEvent {}

class LoadProvinces extends LocationEvent {
  final String regionId;
  const LoadProvinces(this.regionId);
  @override
  List<Object?> get props => [regionId];
}

class LoadCities extends LocationEvent {
  final String provinceId;
  const LoadCities(this.provinceId);
  @override
  List<Object?> get props => [provinceId];
}

class LoadBarangays extends LocationEvent {
  final String cityId;
  const LoadBarangays(this.cityId);
  @override
  List<Object?> get props => [cityId];
}
