import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import '../../domain/entities/user_bid_entity.dart';
import '../../domain/repositories/bids_repository.dart';
import '../datasources/bids_remote_datasource.dart';

class BidsRepositoryImpl implements BidsRepository {
  final BidsRemoteDataSource remoteDataSource;

  BidsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, Map<String, List<UserBidEntity>>>> getUserBids(String userId) async {
    try {
      final result = await remoteDataSource.getUserBids(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
