import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/user_bid_entity.dart';
import 'package:autobid_mobile/modules/bids/domain/repositories/bids_repository.dart';

class GetUserBidsUseCase {
  final BidsRepository repository;

  GetUserBidsUseCase(this.repository);

  Future<Either<Failure, Map<String, List<UserBidEntity>>>> call(String userId) {
    return repository.getUserBids(userId);
  }
}
