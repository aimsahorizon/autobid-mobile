import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/location_entities.dart';

abstract class LocationRepository {
  Future<Either<Failure, List<RegionEntity>>> getRegions();
  Future<Either<Failure, List<ProvinceEntity>>> getProvinces(String regionId);
  Future<Either<Failure, List<CityEntity>>> getCities(String provinceId);
  Future<Either<Failure, List<BarangayEntity>>> getBarangays(String cityId);
}
