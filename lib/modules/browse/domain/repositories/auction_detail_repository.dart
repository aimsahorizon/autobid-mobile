import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auction_detail_entity.dart';
import '../entities/bid_history_entity.dart';
import '../entities/qa_entity.dart';

/// Repository interface for auction detail operations
/// Handles detailed auction data, bidding, Q&A, and user preferences
abstract class AuctionDetailRepository {
  /// Get detailed auction information
  Future<Either<Failure, AuctionDetailEntity>> getAuctionDetail({
    required String auctionId,
    String? userId,
  });

  /// Get bid history timeline for a specific auction
  Future<Either<Failure, List<BidHistoryEntity>>> getBidHistory({
    required String auctionId,
  });

  /// Place a bid on an auction
  Future<Either<Failure, void>> placeBid({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  });

  /// Get Q&A questions for an auction
  Future<Either<Failure, List<QAEntity>>> getQuestions({
    required String auctionId,
    String? currentUserId,
  });

  /// Post a new question to an auction
  Future<Either<Failure, QAEntity>> postQuestion({
    required String auctionId,
    required String userId,
    required String category,
    required String question,
  });

  /// Like a question
  Future<Either<Failure, void>> likeQuestion({
    required String questionId,
    required String userId,
  });

  /// Unlike a question
  Future<Either<Failure, void>> unlikeQuestion({
    required String questionId,
    required String userId,
  });

  /// Get user's saved bid increment preference for an auction
  Future<Either<Failure, double?>> getBidIncrement({
    required String auctionId,
    required String userId,
  });

  /// Save user's bid increment preference for an auction
  Future<Either<Failure, void>> upsertBidIncrement({
    required String auctionId,
    required String userId,
    required double increment,
  });

  /// Process deposit payment for auction participation
  Future<Either<Failure, void>> processDeposit({required String auctionId});

  /// Stream auction updates
  Stream<void> streamAuctionUpdates({required String auctionId});

  /// Stream bid updates
  Stream<void> streamBidUpdates({required String auctionId});
}
