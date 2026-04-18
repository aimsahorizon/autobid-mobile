import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for processing deposit payment for auction participation
class ProcessDepositUseCase {
  final AuctionDetailRepository repository;

  ProcessDepositUseCase(this.repository);

  Future<Either<Failure, void>> call({required String auctionId}) {
    return repository.processDeposit(auctionId: auctionId);
  }
}
