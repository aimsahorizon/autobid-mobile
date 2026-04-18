import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/guest/domain/repositories/guest_repository.dart';

/// UseCase for getting guest auction listings
class GetGuestAuctionListingsUseCase {
  final GuestRepository repository;

  GetGuestAuctionListingsUseCase(this.repository);

  Future<Either<Failure, List<Map<String, dynamic>>>> call({
    int limit = 20,
    int offset = 0,
  }) {
    return repository.getGuestAuctionListings(limit: limit, offset: offset);
  }
}
