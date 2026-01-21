import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/qa_entity.dart';
import '../../domain/usecases/get_auction_detail_usecase.dart';
import '../../domain/usecases/get_bid_history_usecase.dart';
import '../../domain/usecases/place_bid_usecase.dart';
import '../../domain/usecases/get_questions_usecase.dart';
import '../../domain/usecases/post_question_usecase.dart';
import '../../domain/usecases/like_question_usecase.dart';
import '../../domain/usecases/unlike_question_usecase.dart';
import '../../domain/usecases/get_bid_increment_usecase.dart';
import '../../domain/usecases/upsert_bid_increment_usecase.dart';
import '../../domain/usecases/process_deposit_usecase.dart';
import '../../../profile/domain/usecases/consume_bidding_token_usecase.dart';

/// Controller for managing auction detail page state
/// Handles loading auction details, bid history timeline, and Q&A
///
/// Note: User's global bids (Active/Won/Lost) are managed by BidsController
/// This controller only handles auction-specific bid history (timeline)
///
/// Refactored to use Clean Architecture with UseCases and Dependency Injection
class AuctionDetailController extends ChangeNotifier {
  final GetAuctionDetailUseCase _getAuctionDetailUseCase;
  final GetBidHistoryUseCase _getBidHistoryUseCase;
  final PlaceBidUseCase _placeBidUseCase;
  final GetQuestionsUseCase _getQuestionsUseCase;
  final PostQuestionUseCase _postQuestionUseCase;
  final LikeQuestionUseCase _likeQuestionUseCase;
  final UnlikeQuestionUseCase _unlikeQuestionUseCase;
  final GetBidIncrementUseCase _getBidIncrementUseCase;
  final UpsertBidIncrementUseCase _upsertBidIncrementUseCase;
  final ProcessDepositUseCase _processDepositUseCase;
  final ConsumeBiddingTokenUsecase _consumeBiddingTokenUsecase;
  final String? _userId;

  /// Create controller with UseCases via Dependency Injection
  AuctionDetailController({
    required GetAuctionDetailUseCase getAuctionDetailUseCase,
    required GetBidHistoryUseCase getBidHistoryUseCase,
    required PlaceBidUseCase placeBidUseCase,
    required GetQuestionsUseCase getQuestionsUseCase,
    required PostQuestionUseCase postQuestionUseCase,
    required LikeQuestionUseCase likeQuestionUseCase,
    required UnlikeQuestionUseCase unlikeQuestionUseCase,
    required GetBidIncrementUseCase getBidIncrementUseCase,
    required UpsertBidIncrementUseCase upsertBidIncrementUseCase,
    required ProcessDepositUseCase processDepositUseCase,
    required ConsumeBiddingTokenUsecase consumeBiddingTokenUsecase,
    String? userId,
  }) : _getAuctionDetailUseCase = getAuctionDetailUseCase,
       _getBidHistoryUseCase = getBidHistoryUseCase,
       _placeBidUseCase = placeBidUseCase,
       _getQuestionsUseCase = getQuestionsUseCase,
       _postQuestionUseCase = postQuestionUseCase,
       _likeQuestionUseCase = likeQuestionUseCase,
       _unlikeQuestionUseCase = unlikeQuestionUseCase,
       _getBidIncrementUseCase = getBidIncrementUseCase,
       _upsertBidIncrementUseCase = upsertBidIncrementUseCase,
       _processDepositUseCase = processDepositUseCase,
       _consumeBiddingTokenUsecase = consumeBiddingTokenUsecase,
       _userId = userId;

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
  Future<void> loadAuctionDetail(String id, {bool isBackground = false}) async {
    if (!isBackground) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final previousBid = _auction?.currentBid;

      // Get auction detail using UseCase
      final result = await _getAuctionDetailUseCase(
        auctionId: id,
        userId: _userId,
      );

      result.fold(
        (failure) => throw Exception(failure?.message ?? 'Unknown error'),
        (auctionDetail) {
          _auction = auctionDetail;
          // Sync bid increment with seller-configured minimum
          _bidIncrement = auctionDetail.minBidIncrement;
        },
      );

      // Load any saved user preference (persisted increment) if available
      if (_userId != null) {
        final incrementResult = await _getBidIncrementUseCase(
          auctionId: id,
          userId: _userId!,
        );

        incrementResult.fold(
          (failure) {
            // Ignore failure, just use default
          },
          (saved) {
            if (saved != null && saved >= _bidIncrement) {
              _bidIncrement = saved;
            }
          },
        );
      }

      // Load bid history and Q&A in parallel
      await Future.wait([_loadBidHistory(id), _loadQuestions(id)]);

      // Check if we've been outbid and auto-bid is active
      if (previousBid != null &&
          _auction != null &&
          _auction!.currentBid > previousBid &&
          _isAutoBidActive) {
        print(
          'DEBUG: Detected outbid - previous: $previousBid, current: ${_auction!.currentBid}',
        );
        // We've been outbid, trigger auto-bid check
        await _checkAndPlaceAutoBid();
      }
    } catch (e) {
      _errorMessage = 'Failed to load auction details';
    } finally {
      if (!isBackground) {
        _isLoading = false;
        notifyListeners();
      } else {
        // Background refresh: update UI without flashing loading states
        notifyListeners();
      }
    }
  }

  /// Loads bid history timeline for this specific auction
  /// Shows all bids placed on this auction by all users
  Future<void> _loadBidHistory(String auctionId) async {
    _isLoadingBidHistory = true;
    try {
      print('DEBUG: Loading bid history for auction: $auctionId');

      // Get bid history using UseCase
      final result = await _getBidHistoryUseCase(auctionId: auctionId);

      result.fold(
        (failure) {
          print(
            'ERROR: Failed to load bid history: ${failure?.message ?? "Unknown error"}',
          );
          _bidHistory = [];
        },
        (bids) {
          _bidHistory = bids.map((bid) {
            // Set isCurrentUser flag based on userId
            return BidHistoryEntity(
              id: bid.id,
              auctionId: bid.auctionId,
              amount: bid.amount,
              bidderName: bid.bidderName,
              timestamp: bid.timestamp,
              isCurrentUser: _userId != null && bid.id.contains(_userId!),
              isWinning: bid.isWinning,
            );
          }).toList();
          print('DEBUG: Loaded ${_bidHistory.length} bids');
        },
      );
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
      print('DEBUG [Controller]: ========================================');
      print('DEBUG [Controller]: Starting Q&A load for auction: $auctionId');
      print('DEBUG [Controller]: User ID: $_userId');

      // Get questions using UseCase
      final result = await _getQuestionsUseCase(
        auctionId: auctionId,
        currentUserId: _userId,
      );

      result.fold(
        (failure) {
          print(
            'ERROR [Controller]: Failed to load Q&A: ${failure?.message ?? "Unknown error"}',
          );
          _questions = [];
        },
        (questions) {
          _questions = questions;
          print('DEBUG [Controller]: Received response from UseCase');
          print('DEBUG [Controller]: Questions count: ${_questions.length}');

          if (_questions.isEmpty) {
            print('DEBUG [Controller]: ⚠️ NO QUESTIONS FOUND IN DATABASE');
            print('DEBUG [Controller]: This means:');
            print(
              'DEBUG [Controller]:   1. Q&A schema might not be run (migration 00045)',
            );
            print(
              'DEBUG [Controller]:   2. No questions have been asked yet for this listing',
            );
            print(
              'DEBUG [Controller]:   3. RLS policies might be blocking access',
            );
          }
        },
      );

      print('DEBUG [Controller]: ========================================');
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

    try {
      // Check authentication
      if (_userId == null) {
        print(
          'ERROR [Controller]: ❌ User not authenticated, cannot ask question',
        );
        return;
      }

      print('DEBUG [Controller]: Calling UseCase.postQuestion()...');

      // Post question using UseCase
      final result = await _postQuestionUseCase(
        auctionId: _auction!.id,
        userId: _userId!,
        category: category,
        question: question,
      );

      result.fold(
        (failure) {
          print(
            'ERROR [Controller]: ❌ Failed to post question: ${failure?.message ?? "Unknown error"}',
          );
        },
        (qa) {
          print('DEBUG [Controller]: Question posted successfully: ${qa.id}');
          print(
            'DEBUG [Controller]: ✅ Question posted successfully, reloading Q&A...',
          );
          _loadQuestions(_auction!.id).then((_) => notifyListeners());
        },
      );
    } catch (e, stackTrace) {
      print('ERROR [Controller]: ❌ Exception while asking question: $e');
      print('STACK [Controller]: $stackTrace');
    }
    print('DEBUG [Controller]: ========================================');
  }

  /// Toggles like on a question
  Future<void> toggleQuestionLike(String questionId) async {
    try {
      // Check authentication
      if (_userId == null) {
        print('ERROR: User not authenticated, cannot like question');
        return;
      }

      final q = _questions.firstWhere((q) => q.id == questionId);

      // Call appropriate UseCase
      if (q.isLikedByUser) {
        final result = await _unlikeQuestionUseCase(
          questionId: questionId,
          userId: _userId!,
        );
        result.fold(
          (failure) => print(
            'ERROR: Failed to unlike question: ${failure?.message ?? "Unknown error"}',
          ),
          (_) {},
        );
      } else {
        final result = await _likeQuestionUseCase(
          questionId: questionId,
          userId: _userId!,
        );
        result.fold(
          (failure) => print(
            'ERROR: Failed to like question: ${failure?.message ?? "Unknown error"}',
          ),
          (_) {},
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
            answers: q.answers,
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
      // Process deposit using UseCase
      final result = await _processDepositUseCase(auctionId: _auction!.id);

      result.fold(
        (failure) {
          _errorMessage = 'Failed to process deposit';
        },
        (_) {
          // Reload auction to get updated deposit status
          loadAuctionDetail(_auction!.id);
        },
      );
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

      if (effectiveUserId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      // Consume bidding token if available
      final hasToken = await _consumeBiddingTokenUsecase.call(
        userId: effectiveUserId,
        referenceId: _auction!.id,
      );

      if (!hasToken) {
        _errorMessage =
            'Insufficient bidding tokens. Please purchase more tokens or upgrade your subscription.';
        return false;
      }

      // Enforce server-side: amount must be at least currentBid + minBidIncrement
      final current = _auction!.currentBid;
      final minInc = _auction!.minBidIncrement;
      if (amount < current + minInc) {
        _errorMessage =
            'Bid too low. Minimum increase is ₱${minInc.toStringAsFixed(0)}';
        return false;
      }

      // Place bid using UseCase
      print('[AuctionDetailController] Placing bid: \$${amount}');
      final result = await _placeBidUseCase(
        auctionId: _auction!.id,
        bidderId: effectiveUserId,
        amount: amount,
        isAutoBid: _isAutoBidActive,
        maxAutoBid: _maxAutoBid,
        autoBidIncrement: _isAutoBidActive ? _bidIncrement : null,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure?.message ?? 'Unknown error';
          return false;
        },
        (_) {
          print(
            '[AuctionDetailController] Bid placed successfully, reloading auction data...',
          );
          // Reload auction to update current bid and bid history
          // This will also get the potentially extended end_time from snipe guard
          loadAuctionDetail(_auction!.id);
          print(
            '[AuctionDetailController] Auction data reloaded. New end time: ${_auction!.endTime}',
          );
          return true;
        },
      );
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
    // Respect seller-configured minimum bid increment
    final minIncrement = _auction?.minBidIncrement ?? increment;
    final effectiveIncrement = increment < minIncrement
        ? minIncrement
        : increment;

    _isAutoBidActive = isActive;
    _maxAutoBid = maxBid;
    _bidIncrement = effectiveIncrement;

    // Persist user preference for this auction (increment)
    if (_userId != null && _auction != null) {
      _upsertBidIncrementUseCase(
        auctionId: _auction!.id,
        userId: _userId!,
        increment: _bidIncrement,
      );
    }
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
      print(
        'DEBUG: Auto-bid check skipped - active: $_isAutoBidActive, maxBid: $_maxAutoBid, auction: ${_auction != null}',
      );
      return;
    }

    if (_isProcessing) {
      print('DEBUG: Auto-bid check skipped - already processing a bid');
      return;
    }

    // Check if we need to bid higher
    final currentBid = _auction!.currentBid;
    final nextBidAmount = currentBid + _bidIncrement;

    print(
      'DEBUG: Auto-bid check - currentBid: $currentBid, nextBid: $nextBidAmount, maxBid: $_maxAutoBid',
    );

    // Check if next bid is within our max limit
    if (nextBidAmount > _maxAutoBid!) {
      print(
        'DEBUG: Auto-bid limit reached - deactivating (nextBid $nextBidAmount > maxBid $_maxAutoBid)',
      );
      _isAutoBidActive = false;
      _stopPolling();
      _errorMessage =
          'Auto-bid limit reached. Maximum bid: ₱${_maxAutoBid!.toStringAsFixed(0)}';
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
        loadAuctionDetail(_auction!.id, isBackground: true);
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
