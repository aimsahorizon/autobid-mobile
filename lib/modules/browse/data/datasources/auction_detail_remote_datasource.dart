import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
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
}
