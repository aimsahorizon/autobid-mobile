import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

class StreamBidUpdatesUseCase {
  final AuctionDetailRepository repository;

  StreamBidUpdatesUseCase(this.repository);

  Stream<void> call({required String auctionId}) {
    return repository.streamBidUpdates(auctionId: auctionId);
  }
}
