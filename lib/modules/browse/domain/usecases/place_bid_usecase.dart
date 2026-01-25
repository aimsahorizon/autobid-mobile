import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for placing a bid on an auction
class PlaceBidUseCase {
  final AuctionDetailRepository repository;

  PlaceBidUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  }) {
    return repository.placeBid(
      auctionId: auctionId,
      bidderId: bidderId,
      amount: amount,
      isAutoBid: isAutoBid,
      maxAutoBid: maxAutoBid,
      autoBidIncrement: autoBidIncrement,
    );
  }
}
