import '../entities/pricing_entity.dart';
import '../repositories/pricing_repository.dart';

/// Use case to subscribe to a plan
class SubscribeToPlanUsecase {
  final PricingRepository repository;

  SubscribeToPlanUsecase({required this.repository});

  Future<UserSubscriptionEntity> call({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    return await repository.subscribeToPlan(
      userId: userId,
      plan: plan,
    );
  }
}
