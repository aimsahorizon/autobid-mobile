import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../entities/user_bid_entity.dart';
import '../repositories/bids_repository.dart';

class GetUserBidsUseCase {
  final BidsRepository repository;

  GetUserBidsUseCase(this.repository);

  Future<Either<Failure, Map<String, List<UserBidEntity>>>> call(String userId) {
    return repository.getUserBids(userId);
  }
}
