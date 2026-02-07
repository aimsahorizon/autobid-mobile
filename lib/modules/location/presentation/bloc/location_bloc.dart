import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/location_usecases.dart';
import 'location_event.dart';
import 'location_state.dart';

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GetRegionsUseCase getRegions;
  final GetProvincesUseCase getProvinces;
  final GetCitiesUseCase getCities;
  final GetBarangaysUseCase getBarangays;

  LocationBloc({
    required this.getRegions,
    required this.getProvinces,
    required this.getCities,
    required this.getBarangays,
  }) : super(LocationInitial()) {
    on<LoadRegions>(_onLoadRegions);
    on<LoadProvinces>(_onLoadProvinces);
    on<LoadCities>(_onLoadCities);
    on<LoadBarangays>(_onLoadBarangays);
  }

  Future<void> _onLoadRegions(LoadRegions event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    final result = await getRegions();
    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (regions) => emit(RegionsLoaded(regions)),
    );
  }

  Future<void> _onLoadProvinces(LoadProvinces event, Emitter<LocationState> emit) async {
    // Note: In a real UI, we might not want to clear the previous state if we are just cascading
    // But for simplicity, we emit loading.
    emit(LocationLoading());
    final result = await getProvinces(event.regionId);
    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (provinces) => emit(ProvincesLoaded(provinces)),
    );
  }

  Future<void> _onLoadCities(LoadCities event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    final result = await getCities(event.provinceId);
    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (cities) => emit(CitiesLoaded(cities)),
    );
  }

  Future<void> _onLoadBarangays(LoadBarangays event, Emitter<LocationState> emit) async {
    emit(LocationLoading());
    final result = await getBarangays(event.cityId);
    result.fold(
      (failure) => emit(LocationError(failure.message)),
      (barangays) => emit(BarangaysLoaded(barangays)),
    );
  }
}
