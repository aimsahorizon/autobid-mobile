import '../../domain/entities/user_bid_entity.dart';

abstract class BidsRemoteDataSource {
  Future<Map<String, List<UserBidEntity>>> getUserBids([String? userId]);
}
