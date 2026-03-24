import '../entities/pricing_entity.dart';
import '../repositories/pricing_repository.dart';
import '../../data/datasources/pricing_supabase_datasource.dart';

export '../../data/datasources/pricing_supabase_datasource.dart'
    show SubscriptionChangeException;

/// Use case to subscribe to a plan
class SubscribeToPlanUsecase {
  final PricingRepository repository;

  SubscribeToPlanUsecase({required this.repository});

  /// Throws [SubscriptionChangeException] on cooldown, already_on_plan, etc.
  Future<UserSubscriptionEntity> call({
    required String userId,
    required SubscriptionPlan plan,
  }) async {
    return await repository.subscribeToPlan(userId: userId, plan: plan);
  }
}
