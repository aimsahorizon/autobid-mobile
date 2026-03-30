import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_entities.dart';
import '../repositories/location_repository.dart';

class GetRegionsUseCase {
  final LocationRepository repository;
  GetRegionsUseCase(this.repository);
  Future<Either<Failure, List<RegionEntity>>> call() => repository.getRegions();
}

class GetProvincesUseCase {
  final LocationRepository repository;
  GetProvincesUseCase(this.repository);
  Future<Either<Failure, List<ProvinceEntity>>> call(String regionId) => repository.getProvinces(regionId);
}

class GetCitiesUseCase {
  final LocationRepository repository;
  GetCitiesUseCase(this.repository);
  Future<Either<Failure, List<CityEntity>>> call(String provinceId) => repository.getCities(provinceId);
}

class GetBarangaysUseCase {
  final LocationRepository repository;
  GetBarangaysUseCase(this.repository);
  Future<Either<Failure, List<BarangayEntity>>> call(String cityId) => repository.getBarangays(cityId);
}
