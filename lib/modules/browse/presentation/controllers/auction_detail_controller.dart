import 'package:flutter/material.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/qa_entity.dart';
import '../../data/datasources/auction_detail_mock_datasource.dart';
import '../../data/datasources/auction_supabase_datasource.dart';
import '../../data/datasources/bid_history_mock_datasource.dart';
import '../../data/datasources/bid_supabase_datasource.dart';
import '../../data/datasources/qa_mock_datasource.dart';
import '../../data/datasources/qa_supabase_datasource.dart';
import '../../../profile/domain/usecases/consume_bidding_token_usecase.dart';

/// Controller for managing auction detail page state
/// Handles loading auction details, bid history timeline, and Q&A
///
/// Note: User's global bids (Active/Won/Lost) are managed by BidsController
/// This controller only handles auction-specific bid history (timeline)
class AuctionDetailController extends ChangeNotifier {
  final AuctionDetailMockDataSource? _mockDataSource;
  final AuctionSupabaseDataSource? _supabaseDataSource;
  final BidHistoryMockDataSource? _mockBidHistoryDataSource;
  final BidSupabaseDataSource? _supabaseBidHistoryDataSource;
  final QAMockDataSource? _mockQADataSource;
  final QASupabaseDataSource? _supabaseQADataSource;
  final ConsumeBiddingTokenUsecase? _consumeBiddingTokenUsecase;
  final bool _useMockData;
  final String? _userId;

  /// Create controller with mock datasources
  AuctionDetailController.mock(
    AuctionDetailMockDataSource dataSource, {
    ConsumeBiddingTokenUsecase? consumeBiddingTokenUsecase,
  })  : _mockDataSource = dataSource,
        _supabaseDataSource = null,
        _mockBidHistoryDataSource = BidHistoryMockDataSource(),
        _supabaseBidHistoryDataSource = null,
        _mockQADataSource = QAMockDataSource(),
        _supabaseQADataSource = null,
        _consumeBiddingTokenUsecase = consumeBiddingTokenUsecase,
        _useMockData = true,
        _userId = null;

  /// Create controller with Supabase datasources
  AuctionDetailController.supabase({
    required AuctionSupabaseDataSource auctionDataSource,
    required BidSupabaseDataSource bidDataSource,
    required QASupabaseDataSource qaDataSource,
    required ConsumeBiddingTokenUsecase consumeBiddingTokenUsecase,
    String? userId,
  })  : _mockDataSource = null,
        _supabaseDataSource = auctionDataSource,
        _mockBidHistoryDataSource = null,
        _supabaseBidHistoryDataSource = bidDataSource,
        _mockQADataSource = null,
        _supabaseQADataSource = qaDataSource,
        _consumeBiddingTokenUsecase = consumeBiddingTokenUsecase,
        _useMockData = false,
        _userId = userId;

  /// Legacy constructor for backward compatibility
  AuctionDetailController(
    AuctionDetailMockDataSource dataSource, {
    ConsumeBiddingTokenUsecase? consumeBiddingTokenUsecase,
  })  : _mockDataSource = dataSource,
        _supabaseDataSource = null,
        _mockBidHistoryDataSource = BidHistoryMockDataSource(),
        _supabaseBidHistoryDataSource = null,
        _mockQADataSource = QAMockDataSource(),
        _supabaseQADataSource = null,
        _consumeBiddingTokenUsecase = consumeBiddingTokenUsecase,
        _useMockData = true,
        _userId = null;

  // State properties
  AuctionDetailEntity? _auction;
  List<BidHistoryEntity> _bidHistory = []; // Auction-specific bid timeline
  List<QAEntity> _questions = [];
  bool _isLoading = false;
  bool _isLoadingBidHistory = false;
  bool _isLoadingQA = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Auto-bid state
  bool _isAutoBidActive = false;
  double? _maxAutoBid;
  double _bidIncrement = 1000;

  // Public getters
  AuctionDetailEntity? get auction => _auction;
  List<BidHistoryEntity> get bidHistory => _bidHistory;
  List<QAEntity> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get isLoadingBidHistory => _isLoadingBidHistory;
  bool get isLoadingQA => _isLoadingQA;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get isAutoBidActive => _isAutoBidActive;
  double? get maxAutoBid => _maxAutoBid;

  /// Loads auction details and related data (bid history, Q&A)
  Future<void> loadAuctionDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_useMockData) {
        _auction = await _mockDataSource!.getAuctionDetail(id);
      } else {
        final auctionDetailModel = await _supabaseDataSource!.getAuctionDetail(id, _userId);
        _auction = auctionDetailModel; // AuctionDetailModel extends AuctionDetailEntity
      }
      // Load bid history and Q&A in parallel
      await Future.wait([
        _loadBidHistory(id),
        _loadQuestions(id),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to load auction details';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads bid history timeline for this specific auction
  /// Shows all bids placed on this auction by all users
  Future<void> _loadBidHistory(String auctionId) async {
    _isLoadingBidHistory = true;
    try {
      if (_useMockData) {
        _bidHistory = await _mockBidHistoryDataSource!.getBidHistory(auctionId);
      } else {
        // TODO: Implement bid history from Supabase
        // For now, use empty list or mock data
        _bidHistory = [];
      }
    } catch (e) {
      // Silent fail - bid history is secondary
    } finally {
      _isLoadingBidHistory = false;
    }
  }

  /// Loads Q&A questions for this auction
  Future<void> _loadQuestions(String auctionId) async {
    _isLoadingQA = true;
    try {
      if (_useMockData) {
        _questions = await _mockQADataSource!.getQuestions(auctionId);
      } else {
        // TODO: Implement Q&A from Supabase
        // For now, use empty list or mock data
        _questions = [];
      }
    } catch (e) {
      // Silent fail - Q&A is secondary
    } finally {
      _isLoadingQA = false;
    }
  }

  /// Posts a new question to the auction
  Future<void> askQuestion(String category, String question) async {
    if (_auction == null) return;

    bool success;
    if (_useMockData) {
      success = await _mockQADataSource!.postQuestion(
        _auction!.id,
        category,
        question,
      );
    } else {
      // TODO: Implement Q&A post to Supabase
      success = false;
    }

    if (success) {
      await _loadQuestions(_auction!.id);
      notifyListeners();
    }
  }

  /// Toggles like on a question (optimistic update)
  Future<void> toggleQuestionLike(String questionId) async {
    if (_useMockData) {
      await _mockQADataSource!.toggleLike(questionId);
    } else {
      // TODO: Implement like toggle in Supabase
    }
    // Optimistically update UI
    _questions = _questions.map((q) {
      if (q.id == questionId) {
        return QAEntity(
          id: q.id,
          auctionId: q.auctionId,
          category: q.category,
          question: q.question,
          askedBy: q.askedBy,
          askedAt: q.askedAt,
          answer: q.answer,
          answeredAt: q.answeredAt,
          likesCount: q.isLikedByUser ? q.likesCount - 1 : q.likesCount + 1,
          isLikedByUser: !q.isLikedByUser,
        );
      }
      return q;
    }).toList();
    notifyListeners();
  }

  /// Processes deposit payment for auction participation
  Future<void> processDeposit() async {
    if (_auction == null) return;

    _isProcessing = true;
    notifyListeners();

    try {
      bool success;
      if (_useMockData) {
        success = await _mockDataSource!.processDeposit(_auction!.id);
      } else {
        // TODO: Implement deposit processing in Supabase
        success = false;
      }
      if (success) {
        // Reload auction to get updated deposit status
        await loadAuctionDetail(_auction!.id);
      }
    } catch (e) {
      _errorMessage = 'Failed to process deposit';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Places a bid on the auction
  /// Reloads auction detail and bid history on success
  Future<bool> placeBid(double amount, {String? userId}) async {
    if (_auction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      // Consume bidding token if usecase is available (Supabase mode)
      if (_consumeBiddingTokenUsecase != null && !_useMockData && userId != null) {
        final hasToken = await _consumeBiddingTokenUsecase.call(
          userId: userId,
          referenceId: _auction!.id,
        );

        if (!hasToken) {
          _errorMessage = 'Insufficient bidding tokens. Please purchase more tokens or upgrade your subscription.';
          return false;
        }
      }

      bool success;
      if (_useMockData) {
        success = await _mockDataSource!.placeBid(_auction!.id, amount);
      } else {
        // TODO: Implement bid placement in Supabase
        success = false;
      }
      if (success) {
        // Reload auction to update current bid and bid history
        await loadAuctionDetail(_auction!.id);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to place bid';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Sets auto-bid configuration
  /// When active, system will automatically bid when outbid, up to maxBid amount
  void setAutoBid(bool isActive, double? maxBid, double increment) {
    _isAutoBidActive = isActive;
    _maxAutoBid = maxBid;
    _bidIncrement = increment;
    notifyListeners();

    // If auto-bid is active and we're not currently the highest bidder, place initial bid
    if (isActive && maxBid != null && _auction != null) {
      _checkAndPlaceAutoBid();
    }
  }

  /// Internal method to check if auto-bid should trigger and place bid
  Future<void> _checkAndPlaceAutoBid() async {
    if (!_isAutoBidActive || _maxAutoBid == null || _auction == null) return;

    // Check if we're outbid and can still auto-bid
    final nextBidAmount = _auction!.currentBid + _bidIncrement;

    // Only auto-bid if:
    // 1. Next bid amount is within our max auto-bid limit
    // 2. We're not already processing a bid
    if (nextBidAmount <= _maxAutoBid! && !_isProcessing) {
      // Place automatic bid (userId is passed through from constructor)
      await placeBid(nextBidAmount, userId: _userId);
    } else if (nextBidAmount > _maxAutoBid!) {
      // Max limit reached, deactivate auto-bid
      _isAutoBidActive = false;
      notifyListeners();
    }
  }
}
