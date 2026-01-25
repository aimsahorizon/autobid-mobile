import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for saving user's bid increment preference
class UpsertBidIncrementUseCase {
  final AuctionDetailRepository repository;

  UpsertBidIncrementUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String auctionId,
    required String userId,
    required double increment,
  }) {
    return repository.upsertBidIncrement(
      auctionId: auctionId,
      userId: userId,
      increment: increment,
    );
  }
}
