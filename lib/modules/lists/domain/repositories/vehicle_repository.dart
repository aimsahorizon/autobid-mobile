import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/vehicle_entities.dart';

abstract class VehicleRepository {
  Future<Either<Failure, List<VehicleBrand>>> getBrands();
  Future<Either<Failure, List<VehicleModel>>> getModels(String brandId);
  Future<Either<Failure, List<VehicleVariant>>> getVariants(String modelId);
}
