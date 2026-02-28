import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/auction_detail_entity.dart';
import '../entities/bid_history_entity.dart';
import '../entities/bid_queue_entity.dart';
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

  /// Save or update auto-bid settings on the server
  Future<Either<Failure, void>> saveAutoBidSettings({
    required String auctionId,
    required String userId,
    required double maxBidAmount,
    double? bidIncrement,
    bool isActive = true,
  });

  /// Get auto-bid settings for a user on a specific auction
  Future<Either<Failure, Map<String, dynamic>?>> getAutoBidSettings({
    required String auctionId,
    required String userId,
  });

  /// Deactivate auto-bid for a user on a specific auction
  Future<Either<Failure, void>> deactivateAutoBid({
    required String auctionId,
    required String userId,
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

  /// Stream Q&A updates
  Stream<List<QAEntity>> streamQAUpdates({
    required String auctionId,
    String? currentUserId,
  });

  /// Raise hand in the bid queue (queue-only — no bid amount)
  Future<Either<Failure, Map<String, dynamic>>> raiseHand({
    required String auctionId,
    required String bidderId,
  });

  /// Submit a bid during the user's active turn (60s window)
  Future<Either<Failure, Map<String, dynamic>>> submitTurnBid({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
  });

  /// Lower hand (withdraw from bid queue)
  Future<Either<Failure, Map<String, dynamic>>> lowerHand({
    required String auctionId,
    required String bidderId,
  });

  /// Get current queue status for an auction
  Future<Either<Failure, BidQueueCycleEntity>> getQueueStatus({
    required String auctionId,
  });

  /// Stream real-time queue cycle updates
  Stream<BidQueueCycleEntity> streamQueueUpdates({required String auctionId});
}
