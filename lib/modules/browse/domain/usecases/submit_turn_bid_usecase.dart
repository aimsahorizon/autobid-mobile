import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for submitting a bid during the user's active turn.
///
/// When it's the user's turn (status = 'active_turn'), they have 60 seconds
/// to call this with their chosen bid amount. The server validates the amount,
/// places the bid, and moves the turn to the next person in queue.
class SubmitTurnBidUseCase {
  final AuctionDetailRepository repository;

  SubmitTurnBidUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
  }) {
    return repository.submitTurnBid(
      auctionId: auctionId,
      bidderId: bidderId,
      bidAmount: bidAmount,
    );
  }
}
