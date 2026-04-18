import 'package:autobid_mobile/modules/browse/domain/entities/bid_queue_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

/// UseCase for streaming real-time queue cycle updates for an auction.
///
/// Listens to changes on the bid_queue_cycles table via Supabase Realtime.
class StreamQueueUpdatesUseCase {
  final AuctionDetailRepository repository;

  StreamQueueUpdatesUseCase(this.repository);

  Stream<BidQueueCycleEntity> call({required String auctionId}) {
    return repository.streamQueueUpdates(auctionId: auctionId);
  }
}
