import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_detail_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for getting detailed auction information
class GetAuctionDetailUseCase {
  final AuctionDetailRepository repository;

  GetAuctionDetailUseCase(this.repository);

  Future<Either<Failure, AuctionDetailEntity>> call({
    required String auctionId,
    String? userId,
  }) {
    return repository.getAuctionDetail(auctionId: auctionId, userId: userId);
  }
}
