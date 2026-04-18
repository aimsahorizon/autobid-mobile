import 'package:autobid_mobile/modules/browse/domain/repositories/auction_repository.dart';

class StreamActiveAuctionsUseCase {
  final AuctionRepository repository;

  StreamActiveAuctionsUseCase(this.repository);

  Stream<void> call() {
    return repository.streamActiveAuctions();
  }
}
