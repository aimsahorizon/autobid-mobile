import '../entities/pricing_entity.dart';
import '../repositories/pricing_repository.dart';

/// Use case to purchase a token package
class PurchaseTokenPackageUsecase {
  final PricingRepository repository;

  PurchaseTokenPackageUsecase({required this.repository});

  Future<TokenBalanceEntity> call({
    required String userId,
    required String packageId,
    required double amount,
  }) async {
    return await repository.purchaseTokenPackage(
      userId: userId,
      packageId: packageId,
      amount: amount,
    );
  }
}
