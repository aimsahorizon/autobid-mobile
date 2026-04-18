import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/user_bid_entity.dart';

abstract class BidsRepository {
  Future<Either<Failure, Map<String, List<UserBidEntity>>>> getUserBids(String userId);
  Stream<void> streamUserBids(String userId);
}
