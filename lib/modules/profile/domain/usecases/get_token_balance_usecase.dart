import '../entities/pricing_entity.dart';
import '../repositories/pricing_repository.dart';

/// Use case to get user's token balance
class GetTokenBalanceUsecase {
  final PricingRepository repository;

  GetTokenBalanceUsecase({required this.repository});

  Future<TokenBalanceEntity> call(String userId) async {
    return await repository.getTokenBalance(userId);
  }
}
