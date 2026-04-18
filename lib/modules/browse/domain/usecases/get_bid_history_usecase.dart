import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/bid_history_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for getting bid history timeline for an auction
class GetBidHistoryUseCase {
  final AuctionDetailRepository repository;

  GetBidHistoryUseCase(this.repository);

  Future<Either<Failure, List<BidHistoryEntity>>> call({
    required String auctionId,
  }) {
    return repository.getBidHistory(auctionId: auctionId);
  }
}
