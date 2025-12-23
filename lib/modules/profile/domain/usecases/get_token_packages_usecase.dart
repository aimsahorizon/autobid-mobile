import '../entities/pricing_entity.dart';
import '../repositories/pricing_repository.dart';

/// Use case to get available token packages
class GetTokenPackagesUsecase {
  final PricingRepository repository;

  GetTokenPackagesUsecase({required this.repository});

  Future<List<TokenPackageEntity>> call() async {
    return await repository.getTokenPackages();
  }
}
