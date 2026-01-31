import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/qa_entity.dart';
import '../../domain/repositories/auction_detail_repository.dart';
import '../datasources/auction_detail_remote_datasource.dart';

/// Implementation of AuctionDetailRepository using remote data source
class AuctionDetailRepositoryImpl implements AuctionDetailRepository {
  final AuctionDetailRemoteDataSource remoteDataSource;

  AuctionDetailRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuctionDetailEntity>> getAuctionDetail({
    required String auctionId,
    String? userId,
  }) async {
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
  Future<Either<Failure, List<QAEntity>>> getQuestions({
    required String auctionId,
    String? currentUserId,
  }) async {
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
}
