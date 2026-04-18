import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for raising hand in the bid queue (queue-only).
///
/// The user signals intent to bid and is added to the queue.
/// When it's their turn, they get 60 seconds to manually place a bid
/// via [SubmitTurnBidUseCase].
class RaiseHandUseCase {
  final AuctionDetailRepository repository;

  RaiseHandUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String auctionId,
    required String bidderId,
  }) {
    return repository.raiseHand(auctionId: auctionId, bidderId: bidderId);
  }
}
