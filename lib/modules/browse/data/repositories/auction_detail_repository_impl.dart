import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/qa_entity.dart';
import '../../domain/repositories/auction_detail_repository.dart';
import '../datasources/auction_detail_remote_datasource.dart';

/// Implementation of AuctionDetailRepository using remote data source
class AuctionDetailRepositoryImpl implements AuctionDetailRepository {
  final AuctionDetailRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuctionDetailRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, AuctionDetailEntity>> getAuctionDetail({
    required String auctionId,
    String? userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getAuctionDetail(
        auctionId: auctionId,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get auction detail: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<BidHistoryEntity>>> getBidHistory({
    required String auctionId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getBidHistory(auctionId: auctionId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to get bid history: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> placeBid({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.placeBid(
        auctionId: auctionId,
        bidderId: bidderId,
        amount: amount,
        isAutoBid: isAutoBid,
        maxAutoBid: maxAutoBid,
        autoBidIncrement: autoBidIncrement,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to place bid: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAutoBidSettings({
    required String auctionId,
    required String userId,
    required double maxBidAmount,
    double? bidIncrement,
    bool isActive = true,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.saveAutoBidSettings(
        auctionId: auctionId,
        userId: userId,
        maxBidAmount: maxBidAmount,
        bidIncrement: bidIncrement,
        isActive: isActive,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Failed to save auto-bid settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>?>> getAutoBidSettings({
    required String auctionId,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getAutoBidSettings(
        auctionId: auctionId,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get auto-bid settings: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deactivateAutoBid({
    required String auctionId,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.deactivateAutoBid(
        auctionId: auctionId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Failed to deactivate auto-bid: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<QAEntity>>> getQuestions({
    required String auctionId,
    String? currentUserId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getQuestions(
        auctionId: auctionId,
        currentUserId: currentUserId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to get questions: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, QAEntity>> postQuestion({
    required String auctionId,
    required String userId,
    required String category,
    required String question,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.postQuestion(
        auctionId: auctionId,
        userId: userId,
        category: category,
        question: question,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure('Failed to post question: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> likeQuestion({
    required String questionId,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.likeQuestion(
        questionId: questionId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to like question: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> unlikeQuestion({
    required String questionId,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.unlikeQuestion(
        questionId: questionId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to unlike question: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double?>> getBidIncrement({
    required String auctionId,
    required String userId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      final result = await remoteDataSource.getBidIncrement(
        auctionId: auctionId,
        userId: userId,
      );
      return Right(result);
    } catch (e) {
      return Left(
        ServerFailure('Failed to get bid increment: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> upsertBidIncrement({
    required String auctionId,
    required String userId,
    required double increment,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.upsertBidIncrement(
        auctionId: auctionId,
        userId: userId,
        increment: increment,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        ServerFailure('Failed to save bid increment: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> processDeposit({
    required String auctionId,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure('No internet connection'));
    }
    try {
      await remoteDataSource.processDeposit(auctionId: auctionId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Failed to process deposit: ${e.toString()}'));
    }
  }

  @override
  Stream<void> streamAuctionUpdates({required String auctionId}) {
    return remoteDataSource.streamAuctionUpdates(auctionId: auctionId);
  }

  @override
  Stream<void> streamBidUpdates({required String auctionId}) {
    return remoteDataSource.streamBidUpdates(auctionId: auctionId);
  }

  @override
  Stream<List<QAEntity>> streamQAUpdates({
    required String auctionId,
    String? currentUserId,
  }) {
    return remoteDataSource.streamQAUpdates(
      auctionId: auctionId,
      currentUserId: currentUserId,
    );
  }
}
