import 'package:autobid_mobile/modules/browse/domain/entities/qa_entity.dart';
import 'package:autobid_mobile/modules/browse/domain/repositories/auction_detail_repository.dart';

class StreamQAUpdatesUseCase {
  final AuctionDetailRepository _repository;

  StreamQAUpdatesUseCase(this._repository);

  Stream<List<QAEntity>> call({
    required String auctionId,
    String? currentUserId,
  }) {
    return _repository.streamQAUpdates(
      auctionId: auctionId,
      currentUserId: currentUserId,
    );
  }
}
