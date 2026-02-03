import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/vehicle_entities.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_supabase_datasource.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleSupabaseDataSource dataSource;
  final NetworkInfo networkInfo;

  VehicleRepositoryImpl(this.dataSource, this.networkInfo);

  @override
  Future<Either<Failure, List<VehicleBrand>>> getBrands() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.getBrands();
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VehicleModel>>> getModels(String brandId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.getModels(brandId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VehicleVariant>>> getVariants(String modelId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await dataSource.getVariants(modelId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
