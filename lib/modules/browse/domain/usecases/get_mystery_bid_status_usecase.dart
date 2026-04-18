import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

class GetMysteryBidStatusUseCase {
  final AuctionDetailRepository repository;

  GetMysteryBidStatusUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String auctionId,
    required String userId,
  }) {
    return repository.getMysteryBidStatus(auctionId: auctionId, userId: userId);
  }
}
