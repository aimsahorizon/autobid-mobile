import '../entities/pricing_entity.dart';
import '../repositories/pricing_repository.dart';

/// Use case to get user's subscription details
class GetUserSubscriptionUsecase {
  final PricingRepository repository;

  GetUserSubscriptionUsecase({required this.repository});

  Future<UserSubscriptionEntity> call(String userId) async {
    return await repository.getUserSubscription(userId);
  }
}
