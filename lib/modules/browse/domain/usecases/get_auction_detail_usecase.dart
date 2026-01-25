import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auction_detail_entity.dart';
import '../repositories/auction_detail_repository.dart';

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
