import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for getting user's saved bid increment preference
class GetBidIncrementUseCase {
  final AuctionDetailRepository repository;

  GetBidIncrementUseCase(this.repository);

  Future<Either<Failure, double?>> call({
    required String auctionId,
    required String userId,
  }) {
    return repository.getBidIncrement(auctionId: auctionId, userId: userId);
  }
}
