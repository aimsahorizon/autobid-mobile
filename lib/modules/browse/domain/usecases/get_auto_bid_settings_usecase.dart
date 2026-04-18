import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for getting auto-bid settings from the server
class GetAutoBidSettingsUseCase {
  final AuctionDetailRepository repository;

  GetAutoBidSettingsUseCase(this.repository);

  Future<Either<Failure, Map<String, dynamic>?>> call({
    required String auctionId,
    required String userId,
  }) {
    return repository.getAutoBidSettings(auctionId: auctionId, userId: userId);
  }
}
