import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/location_entities.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_remote_datasource.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource remoteDataSource;

  LocationRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<RegionEntity>>> getRegions() async {
    try {
      final result = await remoteDataSource.getRegions();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProvinceEntity>>> getProvinces(String regionId) async {
    try {
      final result = await remoteDataSource.getProvinces(regionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CityEntity>>> getCities(String provinceId) async {
    try {
      final result = await remoteDataSource.getCities(provinceId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BarangayEntity>>> getBarangays(String cityId) async {
    try {
      final result = await remoteDataSource.getBarangays(cityId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
