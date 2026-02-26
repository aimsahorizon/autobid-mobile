import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/bid_queue_entity.dart';
import '../repositories/auction_detail_repository.dart';

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
