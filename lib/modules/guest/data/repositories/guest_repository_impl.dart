import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/account_status_entity.dart';
import '../../domain/repositories/guest_repository.dart';
import '../datasources/guest_remote_datasource.dart';

/// Implementation of GuestRepository using remote data source
class GuestRepositoryImpl implements GuestRepository {
  final GuestRemoteDataSource remoteDataSource;

  GuestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AccountStatusEntity?>> checkAccountStatus(
    String email,
  ) async {
    try {
      final result = await remoteDataSource.checkAccountStatus(email);
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
}
