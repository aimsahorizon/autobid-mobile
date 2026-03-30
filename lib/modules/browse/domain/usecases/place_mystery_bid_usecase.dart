import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

class PlaceMysteryBidUseCase {
  final AuctionDetailRepository repository;

  PlaceMysteryBidUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String auctionId,
    required String bidderId,
    required double amount,
  }) {
    return repository.placeMysteryBid(
      auctionId: auctionId,
      bidderId: bidderId,
      amount: amount,
    );
  }
}
