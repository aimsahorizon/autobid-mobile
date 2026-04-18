import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/bid_queue_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for getting the current queue status for an auction.
///
/// Returns the cycle state, queue entries, and remaining grace period.
class GetQueueStatusUseCase {
  final AuctionDetailRepository repository;

  GetQueueStatusUseCase(this.repository);

  Future<Either<Failure, BidQueueCycleEntity>> call({
    required String auctionId,
  }) {
    return repository.getQueueStatus(auctionId: auctionId);
  }
}
