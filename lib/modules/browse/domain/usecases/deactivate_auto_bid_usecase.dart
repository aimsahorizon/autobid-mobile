import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for deactivating auto-bid for a user on an auction
class DeactivateAutoBidUseCase {
  final AuctionDetailRepository repository;

  DeactivateAutoBidUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String auctionId,
    required String userId,
  }) {
    return repository.deactivateAutoBid(auctionId: auctionId, userId: userId);
  }
}
