import '../../domain/repositories/bids_repository.dart';

class StreamUserBidsUseCase {
  final BidsRepository repository;

  StreamUserBidsUseCase(this.repository);

  Stream<void> call(String userId) {
    return repository.streamUserBids(userId);
  }
}
