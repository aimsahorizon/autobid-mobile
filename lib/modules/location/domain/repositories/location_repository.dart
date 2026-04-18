import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/location/domain/entities/location_entities.dart';

abstract class LocationRepository {
  Future<Either<Failure, List<RegionEntity>>> getRegions();
  Future<Either<Failure, List<ProvinceEntity>>> getProvinces(String regionId);
  Future<Either<Failure, List<CityEntity>>> getCities(String provinceId);
  Future<Either<Failure, List<BarangayEntity>>> getBarangays(String cityId);
}
