import 'package:fpdart/fpdart.dart';
import 'package:autobid_mobile/core/error/failures.dart';
import 'package:autobid_mobile/core/network/network_info.dart';
import '../../domain/entities/user_bid_entity.dart';
import '../../domain/repositories/bids_repository.dart';
import '../datasources/bids_remote_datasource.dart';

class BidsRepositoryImpl implements BidsRepository {
  final BidsRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  BidsRepositoryImpl(this.remoteDataSource, this.networkInfo);

  @override
  Future<Either<Failure, Map<String, List<UserBidEntity>>>> getUserBids(String userId) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getUserBids(userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<void> streamUserBids(String userId) {
    return remoteDataSource.streamUserBids(userId);
  }
}
