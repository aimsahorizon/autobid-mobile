import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../repositories/vehicle_repository.dart';
import '../entities/vehicle_entities.dart';

class GetVehicleBrandsUseCase {
  final VehicleRepository repository;

  GetVehicleBrandsUseCase(this.repository);

  Future<Either<Failure, List<VehicleBrand>>> call() {
    return repository.getBrands();
  }
}

class GetVehicleModelsUseCase {
  final VehicleRepository repository;

  GetVehicleModelsUseCase(this.repository);

  Future<Either<Failure, List<VehicleModel>>> call(String brandId) {
    return repository.getModels(brandId);
  }
}

class GetVehicleVariantsUseCase {
  final VehicleRepository repository;

  GetVehicleVariantsUseCase(this.repository);

  Future<Either<Failure, List<VehicleVariant>>> call(String modelId) {
    return repository.getVariants(modelId);
  }
}
