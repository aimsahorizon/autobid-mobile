import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

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
