import '../../domain/repositories/auction_detail_repository.dart';

class StreamAuctionUpdatesUseCase {
  final AuctionDetailRepository repository;

  StreamAuctionUpdatesUseCase(this.repository);

  Stream<void> call({required String auctionId}) {
    return repository.streamAuctionUpdates(auctionId: auctionId);
  }
}
