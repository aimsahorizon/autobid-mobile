import 'package:flutter/material.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/qa_entity.dart';
import '../../data/datasources/auction_detail_mock_datasource.dart';
import '../../data/datasources/bid_history_mock_datasource.dart';
import '../../data/datasources/qa_mock_datasource.dart';

/// Controller for managing auction detail page state
/// Handles loading auction details, bid history timeline, and Q&A
///
/// Note: User's global bids (Active/Won/Lost) are managed by BidsController
/// This controller only handles auction-specific bid history (timeline)
class AuctionDetailController extends ChangeNotifier {
  final AuctionDetailMockDataSource _dataSource;
  final BidHistoryMockDataSource _bidHistoryDataSource;
  final QAMockDataSource _qaDataSource;

  AuctionDetailController(this._dataSource)
      : _bidHistoryDataSource = BidHistoryMockDataSource(),
        _qaDataSource = QAMockDataSource();

  // State properties
  AuctionDetailEntity? _auction;
  List<BidHistoryEntity> _bidHistory = []; // Auction-specific bid timeline
  List<QAEntity> _questions = [];
  bool _isLoading = false;
  bool _isLoadingBidHistory = false;
  bool _isLoadingQA = false;
  bool _isProcessing = false;
  String? _errorMessage;

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

  /// Loads auction details and related data (bid history, Q&A)
  Future<void> loadAuctionDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auction = await _dataSource.getAuctionDetail(id);
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
      _bidHistory = await _bidHistoryDataSource.getBidHistory(auctionId);
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
      _questions = await _qaDataSource.getQuestions(auctionId);
    } catch (e) {
      // Silent fail - Q&A is secondary
    } finally {
      _isLoadingQA = false;
    }
  }

  /// Posts a new question to the auction
  Future<void> askQuestion(String category, String question) async {
    if (_auction == null) return;

    final success = await _qaDataSource.postQuestion(
      _auction!.id,
      category,
      question,
    );

    if (success) {
      await _loadQuestions(_auction!.id);
      notifyListeners();
    }
  }

  /// Toggles like on a question (optimistic update)
  Future<void> toggleQuestionLike(String questionId) async {
    await _qaDataSource.toggleLike(questionId);
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
      final success = await _dataSource.processDeposit(_auction!.id);
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
  Future<bool> placeBid(double amount) async {
    if (_auction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.placeBid(_auction!.id, amount);
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
}
