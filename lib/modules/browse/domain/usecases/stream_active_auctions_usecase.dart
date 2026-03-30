import '../repositories/auction_repository.dart';

class StreamActiveAuctionsUseCase {
  final AuctionRepository repository;

  StreamActiveAuctionsUseCase(this.repository);

  Stream<void> call() {
    return repository.streamActiveAuctions();
  }
}
