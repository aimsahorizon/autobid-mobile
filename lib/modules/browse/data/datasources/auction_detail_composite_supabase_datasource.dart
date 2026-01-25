import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/qa_entity.dart';
import 'auction_detail_remote_datasource.dart';
import 'auction_supabase_datasource.dart';
import 'bid_supabase_datasource.dart';
import 'qa_supabase_datasource.dart';
import 'user_preferences_supabase_datasource.dart';
import 'deposit_supabase_datasource.dart';

/// Composite data source that aggregates existing specialized data sources
/// Following the pattern from TransactionCompositeSupabaseDataSource
/// This delegates calls to existing datasources without rewriting SQL logic
class AuctionDetailCompositeSupabaseDataSource
    implements AuctionDetailRemoteDataSource {
  final AuctionSupabaseDataSource _auctionDataSource;
  final BidSupabaseDataSource _bidDataSource;
  final QASupabaseDataSource _qaDataSource;
  final UserPreferencesSupabaseDatasource _userPreferencesDataSource;
  final DepositSupabaseDataSource _depositDataSource;

  AuctionDetailCompositeSupabaseDataSource({
    required AuctionSupabaseDataSource auctionDataSource,
    required BidSupabaseDataSource bidDataSource,
    required QASupabaseDataSource qaDataSource,
    required UserPreferencesSupabaseDatasource userPreferencesDataSource,
    required DepositSupabaseDataSource depositDataSource,
  }) : _auctionDataSource = auctionDataSource,
       _bidDataSource = bidDataSource,
       _qaDataSource = qaDataSource,
       _userPreferencesDataSource = userPreferencesDataSource,
       _depositDataSource = depositDataSource;

  @override
  Future<AuctionDetailEntity> getAuctionDetail({
    required String auctionId,
    String? userId,
  }) {
    return _auctionDataSource.getAuctionDetail(auctionId, userId);
  }

  @override
  Future<List<BidHistoryEntity>> getBidHistory({
    required String auctionId,
  }) async {
    // Get bid history from Supabase
    final bidsData = await _bidDataSource.getBidHistory(auctionId);

    // Convert to BidHistoryEntity
    return bidsData.map((bidData) {
      // Extract bidder username from nested users data
      String bidderName = 'Bidder';
      final bidderData = bidData['bidder'] as Map<String, dynamic>?;
      if (bidderData != null) {
        final displayName = bidderData['display_name'] as String?;
        final username = bidderData['username'] as String?;
        // Prefer display_name if available, fallback to username
        if (displayName != null && displayName.isNotEmpty) {
          bidderName = displayName;
        } else if (username != null && username.isNotEmpty) {
          bidderName = username;
        }
      }

      return BidHistoryEntity(
        id: bidData['id'] as String,
        auctionId: auctionId,
        amount: (bidData['bid_amount'] as num).toDouble(),
        bidderName: bidderName,
        timestamp: DateTime.parse(bidData['created_at'] as String),
        isCurrentUser: false, // Will be set by repository/usecase if needed
        isWinning: false, // Will be set based on current auction state
      );
    }).toList();
  }

  @override
  Future<void> placeBid({
    required String auctionId,
    required String bidderId,
    required double amount,
    bool isAutoBid = false,
    double? maxAutoBid,
    double? autoBidIncrement,
  }) {
    return _bidDataSource.placeBid(
      auctionId: auctionId,
      bidderId: bidderId,
      amount: amount,
      isAutoBid: isAutoBid,
      maxAutoBid: maxAutoBid,
      autoBidIncrement: autoBidIncrement,
    );
  }

  @override
  Future<List<QAEntity>> getQuestions({
    required String auctionId,
    String? currentUserId,
  }) {
    return _qaDataSource.getQuestions(auctionId, currentUserId: currentUserId);
  }

  @override
  Future<QAEntity> postQuestion({
    required String auctionId,
    required String userId,
    required String category,
    required String question,
  }) {
    return _qaDataSource.postQuestion(
      auctionId: auctionId,
      userId: userId,
      category: category,
      question: question,
    );
  }

  @override
  Future<void> likeQuestion({
    required String questionId,
    required String userId,
  }) {
    return _qaDataSource.likeQuestion(questionId: questionId, userId: userId);
  }

  @override
  Future<void> unlikeQuestion({
    required String questionId,
    required String userId,
  }) {
    return _qaDataSource.unlikeQuestion(questionId: questionId, userId: userId);
  }

  @override
  Future<double?> getBidIncrement({
    required String auctionId,
    required String userId,
  }) {
    return _userPreferencesDataSource.getBidIncrement(
      auctionId: auctionId,
      userId: userId,
    );
  }

  @override
  Future<void> upsertBidIncrement({
    required String auctionId,
    required String userId,
    required double increment,
  }) {
    return _userPreferencesDataSource.upsertBidIncrement(
      auctionId: auctionId,
      userId: userId,
      increment: increment,
    );
  }

  @override
  Future<void> processDeposit({required String auctionId}) {
    return _depositDataSource.processDeposit(auctionId);
  }
}
