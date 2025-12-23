import '../repositories/pricing_repository.dart';

/// Use case to consume a listing token
class ConsumeListingTokenUsecase {
  final PricingRepository repository;

  ConsumeListingTokenUsecase({required this.repository});

  Future<bool> call({
    required String userId,
    required String referenceId,
  }) async {
    return await repository.consumeListingToken(
      userId: userId,
      referenceId: referenceId,
    );
  }
}
