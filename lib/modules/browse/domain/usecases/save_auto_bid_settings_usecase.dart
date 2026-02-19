import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

/// UseCase for saving auto-bid settings to the server
class SaveAutoBidSettingsUseCase {
  final AuctionDetailRepository repository;

  SaveAutoBidSettingsUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String auctionId,
    required String userId,
    required double maxBidAmount,
    double? bidIncrement,
    bool isActive = true,
  }) {
    return repository.saveAutoBidSettings(
      auctionId: auctionId,
      userId: userId,
      maxBidAmount: maxBidAmount,
      bidIncrement: bidIncrement,
      isActive: isActive,
    );
  }
}
