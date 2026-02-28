import 'package:equatable/equatable.dart';
import '../../domain/entities/location_entities.dart';

abstract class LocationState extends Equatable {
  const LocationState();
  
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class RegionsLoaded extends LocationState {
  final List<RegionEntity> regions;
  const RegionsLoaded(this.regions);
  @override
  List<Object?> get props => [regions];
}

class ProvincesLoaded extends LocationState {
  final List<ProvinceEntity> provinces;
  const ProvincesLoaded(this.provinces);
  @override
  List<Object?> get props => [provinces];
}

class CitiesLoaded extends LocationState {
  final List<CityEntity> cities;
  const CitiesLoaded(this.cities);
  @override
  List<Object?> get props => [cities];
}

class BarangaysLoaded extends LocationState {
  final List<BarangayEntity> barangays;
  const BarangaysLoaded(this.barangays);
  @override
  List<Object?> get props => [barangays];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
  @override
  List<Object?> get props => [message];
}
