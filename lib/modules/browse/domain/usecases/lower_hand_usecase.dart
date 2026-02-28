import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for lowering hand (withdrawing) from the bid queue.
///
/// Allows a buyer to back out of the queue at any time, even if it's their
/// turn. The next person in queue will be selected instead.
class LowerHandUseCase {
  final AuctionDetailRepository repository;

  LowerHandUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String auctionId,
    required String bidderId,
  }) {
    return repository.lowerHand(auctionId: auctionId, bidderId: bidderId);
  }
}
