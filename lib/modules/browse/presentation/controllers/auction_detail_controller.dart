import 'dart:async';
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
  Timer? _pollingTimer;

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
      final previousBid = _auction?.currentBid;

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

      // Check if we've been outbid and auto-bid is active
      if (previousBid != null &&
          _auction != null &&
          _auction!.currentBid > previousBid &&
          _isAutoBidActive) {
        print('DEBUG: Detected outbid - previous: $previousBid, current: ${_auction!.currentBid}');
        // We've been outbid, trigger auto-bid check
        await _checkAndPlaceAutoBid();
      }
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
        print('DEBUG: Loaded ${_bidHistory.length} bids from mock data');
      } else {
        print('DEBUG: Loading bid history for auction: $auctionId');

        // Get bid history from Supabase
        final bidsData = await _supabaseBidHistoryDataSource!.getBidHistory(auctionId);
        print('DEBUG: Received ${bidsData.length} bids from Supabase');
        print('DEBUG: Raw bids data: $bidsData');

        // Convert to BidHistoryEntity
        _bidHistory = bidsData.map((bidData) {
          print('DEBUG: Processing bid - ID: ${bidData['id']}, Amount: ${bidData['amount']}');

          return BidHistoryEntity(
            id: bidData['id'] as String,
            auctionId: auctionId,
            amount: (bidData['amount'] as num).toDouble(),
            bidderName: 'Bidder ${bidData['bidder_id'].toString().substring(0, 8)}', // Show partial ID
            timestamp: DateTime.parse(bidData['created_at'] as String),
            isCurrentUser: _userId != null && bidData['bidder_id'] == _userId,
            isWinning: false, // Will be set based on current auction state
          );
        }).toList();

        print('DEBUG: Converted to ${_bidHistory.length} BidHistoryEntity objects');
      }
    } catch (e, stackTrace) {
      // Log the error instead of silent fail
      print('ERROR: Failed to load bid history: $e');
      print('STACK: $stackTrace');
      _bidHistory = [];
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
        // Get questions from Supabase
        print('DEBUG [Controller]: ========================================');
        print('DEBUG [Controller]: Starting Q&A load for auction: $auctionId');
        print('DEBUG [Controller]: User ID: $_userId');
        print('DEBUG [Controller]: QA DataSource exists: ${_supabaseQADataSource != null}');

        final questionsData = await _supabaseQADataSource!.getQuestions(auctionId, userId: _userId);

        print('DEBUG [Controller]: ========================================');
        print('DEBUG [Controller]: Received response from datasource');
        print('DEBUG [Controller]: Questions count: ${questionsData.length}');
        print('DEBUG [Controller]: Raw Q&A data: $questionsData');

        if (questionsData.isEmpty) {
          print('DEBUG [Controller]: ⚠️ NO QUESTIONS FOUND IN DATABASE');
          print('DEBUG [Controller]: This means:');
          print('DEBUG [Controller]:   1. Q&A schema might not be run (sql/11_qa_schema.sql)');
          print('DEBUG [Controller]:   2. No questions have been asked yet for this listing');
          print('DEBUG [Controller]:   3. RLS policies might be blocking access');
        }

        _questions = questionsData.map((qData) {
          print('DEBUG [Controller]: Processing question - ID: ${qData['id']}, Question: ${qData['question']}');
          return QAEntity(
            id: qData['id'] as String,
            auctionId: auctionId,
            category: qData['category'] as String? ?? 'general',
            question: qData['question'] as String,
            askedBy: 'User ${qData['asker_id'].toString().substring(0, 8)}',
            askedAt: DateTime.parse(qData['created_at'] as String),
            answer: qData['answer'] as String?,
            answeredAt: qData['answered_at'] != null
                ? DateTime.parse(qData['answered_at'] as String)
                : null,
            likesCount: qData['likes_count'] as int? ?? 0,
            isLikedByUser: qData['user_has_liked'] as bool? ?? false,
          );
        }).toList();
        print('DEBUG [Controller]: Converted to ${_questions.length} QAEntity objects');
        print('DEBUG [Controller]: ========================================');
      }
    } catch (e, stackTrace) {
      print('ERROR [Controller]: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('ERROR [Controller]: Failed to load Q&A: $e');
      print('STACK [Controller]: $stackTrace');
      print('ERROR [Controller]: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      _questions = [];
    } finally {
      _isLoadingQA = false;
    }
  }

  /// Posts a new question to the auction
  Future<void> askQuestion(String category, String question) async {
    if (_auction == null) return;

    print('DEBUG [Controller]: ========================================');
    print('DEBUG [Controller]: Attempting to ask question');
    print('DEBUG [Controller]: Auction ID: ${_auction!.id}');
    print('DEBUG [Controller]: Category: $category');
    print('DEBUG [Controller]: Question: $question');
    print('DEBUG [Controller]: User ID: $_userId');

    bool success = false;
    try {
      if (_useMockData) {
        success = await _mockQADataSource!.postQuestion(
          _auction!.id,
          category,
          question,
        );
      } else {
        // Post question to Supabase
        if (_userId == null) {
          print('ERROR [Controller]: ❌ User not authenticated, cannot ask question');
          return;
        }

        print('DEBUG [Controller]: Calling datasource.askQuestion()...');
        success = await _supabaseQADataSource!.askQuestion(
          listingId: _auction!.id,
          askerId: _userId!,
          category: category,
          question: question,
        );
        print('DEBUG [Controller]: Question posted, success: $success');
      }

      if (success) {
        print('DEBUG [Controller]: ✅ Question posted successfully, reloading Q&A...');
        await _loadQuestions(_auction!.id);
        notifyListeners();
      } else {
        print('ERROR [Controller]: ❌ Failed to post question (returned false)');
      }
    } catch (e, stackTrace) {
      print('ERROR [Controller]: ❌ Exception while asking question: $e');
      print('STACK [Controller]: $stackTrace');
    }
    print('DEBUG [Controller]: ========================================');
  }

  /// Toggles like on a question
  Future<void> toggleQuestionLike(String questionId) async {
    try {
      if (_useMockData) {
        await _mockQADataSource!.toggleLike(questionId);
      } else {
        // Toggle like in Supabase
        if (_userId == null) {
          print('ERROR: User not authenticated, cannot like question');
          return;
        }

        await _supabaseQADataSource!.toggleQuestionLike(
          questionId: questionId,
          userId: _userId!,
        );
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
    } catch (e) {
      print('ERROR: Failed to toggle like: $e');
    }
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
      // Use provided userId or fallback to controller's userId
      final effectiveUserId = userId ?? _userId;

      if (effectiveUserId == null && !_useMockData) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      // Consume bidding token if usecase is available (Supabase mode)
      if (_consumeBiddingTokenUsecase != null && !_useMockData && effectiveUserId != null) {
        final hasToken = await _consumeBiddingTokenUsecase.call(
          userId: effectiveUserId,
          referenceId: _auction!.id,
        );

        if (!hasToken) {
          _errorMessage = 'Insufficient bidding tokens. Please purchase more tokens or upgrade your subscription.';
          return false;
        }
      }

      bool success = true;
      if (_useMockData) {
        success = await _mockDataSource!.placeBid(_auction!.id, amount);
      } else {
        // Place bid in Supabase
        await _supabaseBidHistoryDataSource!.placeBid(
          auctionId: _auction!.id,
          bidderId: effectiveUserId!,
          amount: amount,
          isAutoBid: _isAutoBidActive,
          maxAutoBid: _maxAutoBid,
          autoBidIncrement: _isAutoBidActive ? _bidIncrement : null,
        );
      }

      if (success) {
        // Reload auction to update current bid and bid history
        await loadAuctionDetail(_auction!.id);
      }
      return success;
    } catch (e) {
      _errorMessage = e.toString().contains('Failed to place bid')
          ? e.toString().replaceFirst('Exception: ', '')
          : 'Failed to place bid: ${e.toString()}';
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

    // If auto-bid is active, start polling and place initial bid
    if (isActive && maxBid != null && _auction != null) {
      _startPolling();
      _checkAndPlaceAutoBid();
    } else {
      _stopPolling();
    }
  }

  /// Internal method to check if auto-bid should trigger and place bid
  Future<void> _checkAndPlaceAutoBid() async {
    if (!_isAutoBidActive || _maxAutoBid == null || _auction == null) {
      print('DEBUG: Auto-bid check skipped - active: $_isAutoBidActive, maxBid: $_maxAutoBid, auction: ${_auction != null}');
      return;
    }

    if (_isProcessing) {
      print('DEBUG: Auto-bid check skipped - already processing a bid');
      return;
    }

    // Check if we need to bid higher
    final currentBid = _auction!.currentBid;
    final nextBidAmount = currentBid + _bidIncrement;

    print('DEBUG: Auto-bid check - currentBid: $currentBid, nextBid: $nextBidAmount, maxBid: $_maxAutoBid');

    // Check if next bid is within our max limit
    if (nextBidAmount > _maxAutoBid!) {
      print('DEBUG: Auto-bid limit reached - deactivating (nextBid $nextBidAmount > maxBid $_maxAutoBid)');
      _isAutoBidActive = false;
      _stopPolling();
      _errorMessage = 'Auto-bid limit reached. Maximum bid: ₱${_maxAutoBid!.toStringAsFixed(0)}';
      notifyListeners();
      return;
    }

    // Check if we're already the highest bidder by checking bid history
    if (_bidHistory.isNotEmpty) {
      final highestBid = _bidHistory.first;
      if (highestBid.isCurrentUser && highestBid.amount >= currentBid) {
        print('DEBUG: Already highest bidder - no auto-bid needed');
        return;
      }
    }

    // Place automatic bid
    print('DEBUG: Placing auto-bid of ₱$nextBidAmount');
    final success = await placeBid(nextBidAmount, userId: _userId);

    if (success) {
      print('DEBUG: Auto-bid successful at ₱$nextBidAmount');
    } else {
      print('DEBUG: Auto-bid failed - ${_errorMessage ?? "unknown error"}');
      // If bid fails, deactivate auto-bid to prevent infinite loops
      _isAutoBidActive = false;
      _stopPolling();
      notifyListeners();
    }
  }

  /// Starts polling timer to periodically check for auction updates
  /// Runs every 5 seconds when auto-bid is active
  void _startPolling() {
    _stopPolling(); // Cancel any existing timer

    print('DEBUG: Starting auto-bid polling (5s interval)');
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_auction != null && _isAutoBidActive) {
        print('DEBUG: Polling for auction updates...');
        loadAuctionDetail(_auction!.id);
      }
    });
  }

  /// Stops the polling timer
  void _stopPolling() {
    if (_pollingTimer != null) {
      print('DEBUG: Stopping auto-bid polling');
      _pollingTimer?.cancel();
      _pollingTimer = null;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
