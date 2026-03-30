import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/account_status_entity.dart';
import '../../domain/repositories/guest_repository.dart';
import '../datasources/guest_remote_datasource.dart';

/// Implementation of GuestRepository using remote data source
class GuestRepositoryImpl implements GuestRepository {
  final GuestRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  GuestRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AccountStatusEntity?>> checkAccountStatus(
    String identifier,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.checkAccountStatus(identifier);
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Failed to check account status: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getGuestAuctionListings({
    int limit = 20,
    int offset = 0,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getGuestAuctionListings(
        limit: limit,
        offset: offset,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to fetch auctions: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> submitKycAppeal(
    String userId,
    String appealReason,
  ) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.submitKycAppeal(userId, appealReason);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to submit appeal: ${e.toString()}'));
    }
  }
}
