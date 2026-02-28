import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/bid_queue_entity.dart';
import '../../domain/entities/qa_entity.dart';

/// Remote data source interface for auction detail operations
abstract class AuctionDetailRemoteDataSource {
  /// Get detailed auction information
  Future<AuctionDetailEntity> getAuctionDetail({
    required String auctionId,
    String? userId,
  });

  /// Get bid history timeline for a specific auction
  Future<List<BidHistoryEntity>> getBidHistory({required String auctionId});

  /// Place a bid on an auction
  Future<void> placeBid({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  });

  /// Save or update auto-bid settings on the server
  Future<void> saveAutoBidSettings({
    required String auctionId,
    required String userId,
    required double maxBidAmount,
    double? bidIncrement,
    bool isActive = true,
  });

  /// Get auto-bid settings for a user on a specific auction
  Future<Map<String, dynamic>?> getAutoBidSettings({
    required String auctionId,
    required String userId,
  });

  /// Deactivate auto-bid for a user on a specific auction
  Future<void> deactivateAutoBid({
    required String auctionId,
    required String userId,
  });

  /// Get Q&A questions for an auction
  Future<List<QAEntity>> getQuestions({
    required String auctionId,
    String? currentUserId,
  });

  /// Post a new question to an auction
  Future<QAEntity> postQuestion({
    required String auctionId,
    required String userId,
    required String category,
    required String question,
  });

  /// Like a question
  Future<void> likeQuestion({
    required String questionId,
    required String userId,
  });

  /// Unlike a question
  Future<void> unlikeQuestion({
    required String questionId,
    required String userId,
  });

  /// Get user's saved bid increment preference for an auction
  Future<double?> getBidIncrement({
    required String auctionId,
    required String userId,
  });

  /// Save user's bid increment preference for an auction
  Future<void> upsertBidIncrement({
    required String auctionId,
    required String userId,
    required double increment,
  });

  /// Process deposit payment for auction participation
  Future<void> processDeposit({required String auctionId});

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
  Future<Map<String, dynamic>> raiseHand({
    required String auctionId,
    required String bidderId,
  });

  /// Submit a bid during the user's active turn (60s window)
  Future<Map<String, dynamic>> submitTurnBid({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
  });

  /// Lower hand (withdraw from bid queue)
  Future<Map<String, dynamic>> lowerHand({
    required String auctionId,
    required String bidderId,
  });

  /// Get current queue status for an auction
  Future<BidQueueCycleEntity> getQueueStatus({required String auctionId});

  /// Stream real-time queue cycle updates
  Stream<BidQueueCycleEntity> streamQueueUpdates({required String auctionId});
}
