import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auction_detail_repository.dart';

typedef AutoBidEligibilityChecker = Future<bool> Function(String userId);

/// UseCase for saving auto-bid settings to the server
class SaveAutoBidSettingsUseCase {
  final AuctionDetailRepository repository;
  final AutoBidEligibilityChecker? canUseAutoBid;

  SaveAutoBidSettingsUseCase(this.repository, {this.canUseAutoBid});

  Future<Either<Failure, void>> call({
    required String auctionId,
    required String userId,
    required double maxBidAmount,
    double? bidIncrement,
    bool isActive = true,
  }) async {
    if (isActive && canUseAutoBid != null) {
      final isEligible = await canUseAutoBid!(userId);
      if (!isEligible) {
        return const Left(
          PermissionFailure('Auto-bid is available for Gold subscribers only.'),
        );
      }
    }

    return repository.saveAutoBidSettings(
      auctionId: auctionId,
      userId: userId,
      maxBidAmount: maxBidAmount,
      bidIncrement: bidIncrement,
      isActive: isActive,
    );
  }
}
