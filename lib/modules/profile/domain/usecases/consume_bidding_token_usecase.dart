import '../repositories/pricing_repository.dart';

/// Use case to consume a bidding token
class ConsumeBiddingTokenUsecase {
  final PricingRepository repository;

  ConsumeBiddingTokenUsecase({required this.repository});

  Future<bool> call({
    required String userId,
    required String referenceId,
  }) async {
    return await repository.consumeBiddingToken(
      userId: userId,
      referenceId: referenceId,
    );
  }
}
