import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../../domain/entities/bid_history_entity.dart';
import '../../domain/entities/bid_queue_entity.dart';
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
import '../../domain/usecases/stream_auction_updates_usecase.dart';
import '../../domain/usecases/stream_bid_updates_usecase.dart';
import '../../domain/usecases/stream_qa_updates_usecase.dart';
import '../../domain/usecases/save_auto_bid_settings_usecase.dart';
import '../../domain/usecases/get_auto_bid_settings_usecase.dart';
import '../../domain/usecases/deactivate_auto_bid_usecase.dart';
import '../../domain/usecases/raise_hand_usecase.dart';
import '../../domain/usecases/lower_hand_usecase.dart';
import '../../domain/usecases/submit_turn_bid_usecase.dart';
import '../../domain/usecases/get_queue_status_usecase.dart';
import '../../domain/usecases/stream_queue_updates_usecase.dart';
import '../../domain/usecases/place_mystery_bid_usecase.dart';
import '../../domain/usecases/get_mystery_bid_status_usecase.dart';
import '../../domain/entities/mystery_bid_entity.dart';
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
  // ignore: unused_field — kept for future manual bid-increment persistence
  final UpsertBidIncrementUseCase _upsertBidIncrementUseCase;
  final ProcessDepositUseCase _processDepositUseCase;
  final ConsumeBiddingTokenUsecase _consumeBiddingTokenUsecase;
  final StreamAuctionUpdatesUseCase _streamAuctionUpdatesUseCase;
  final StreamBidUpdatesUseCase _streamBidUpdatesUseCase;
  final StreamQAUpdatesUseCase _streamQAUpdatesUseCase;
  final SaveAutoBidSettingsUseCase _saveAutoBidSettingsUseCase;
  final GetAutoBidSettingsUseCase _getAutoBidSettingsUseCase;
  final DeactivateAutoBidUseCase _deactivateAutoBidUseCase;
  final RaiseHandUseCase _raiseHandUseCase;
  final LowerHandUseCase _lowerHandUseCase;
  final SubmitTurnBidUseCase _submitTurnBidUseCase;
  final GetQueueStatusUseCase _getQueueStatusUseCase;
  final StreamQueueUpdatesUseCase _streamQueueUpdatesUseCase;
  final PlaceMysteryBidUseCase _placeMysteryBidUseCase;
  final GetMysteryBidStatusUseCase _getMysteryBidStatusUseCase;
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
    required StreamAuctionUpdatesUseCase streamAuctionUpdatesUseCase,
    required StreamBidUpdatesUseCase streamBidUpdatesUseCase,
    required StreamQAUpdatesUseCase streamQAUpdatesUseCase,
    required SaveAutoBidSettingsUseCase saveAutoBidSettingsUseCase,
    required GetAutoBidSettingsUseCase getAutoBidSettingsUseCase,
    required DeactivateAutoBidUseCase deactivateAutoBidUseCase,
    required RaiseHandUseCase raiseHandUseCase,
    required LowerHandUseCase lowerHandUseCase,
    required SubmitTurnBidUseCase submitTurnBidUseCase,
    required GetQueueStatusUseCase getQueueStatusUseCase,
    required StreamQueueUpdatesUseCase streamQueueUpdatesUseCase,
    required PlaceMysteryBidUseCase placeMysteryBidUseCase,
    required GetMysteryBidStatusUseCase getMysteryBidStatusUseCase,
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
       _streamAuctionUpdatesUseCase = streamAuctionUpdatesUseCase,
       _streamBidUpdatesUseCase = streamBidUpdatesUseCase,
       _streamQAUpdatesUseCase = streamQAUpdatesUseCase,
       _saveAutoBidSettingsUseCase = saveAutoBidSettingsUseCase,
       _getAutoBidSettingsUseCase = getAutoBidSettingsUseCase,
       _deactivateAutoBidUseCase = deactivateAutoBidUseCase,
       _raiseHandUseCase = raiseHandUseCase,
       _lowerHandUseCase = lowerHandUseCase,
       _submitTurnBidUseCase = submitTurnBidUseCase,
       _getQueueStatusUseCase = getQueueStatusUseCase,
       _streamQueueUpdatesUseCase = streamQueueUpdatesUseCase,
       _placeMysteryBidUseCase = placeMysteryBidUseCase,
       _getMysteryBidStatusUseCase = getMysteryBidStatusUseCase,
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
  double _bidIncrement = 100;
  StreamSubscription? _auctionSubscription;
  StreamSubscription? _bidSubscription;
  StreamSubscription? _qaSubscription;
  StreamSubscription? _queueSubscription;
  String? _subscribedAuctionId; // Track which auction we're subscribed to

  // Bid queue state
  BidQueueCycleEntity _queueStatus = BidQueueCycleEntity.idle();
  bool _hasRaisedHand = false;
  Timer? _queuePollTimer;

  // Mystery bid state
  MysteryBidStatusEntity? _mysteryBidStatus;
  bool _isLoadingMysteryStatus = false;

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
  double get bidIncrement => _bidIncrement;
  BidQueueCycleEntity get queueStatus => _queueStatus;
  bool get hasRaisedHand => _hasRaisedHand;
  MysteryBidStatusEntity? get mysteryBidStatus => _mysteryBidStatus;
  bool get isLoadingMysteryStatus => _isLoadingMysteryStatus;
  bool get isMysteryAuction => _auction?.biddingType == 'mystery';

  /// Whether it's currently this user's turn to bid (60s window)
  bool get isMyTurn {
    if (_userId == null) return false;
    return _queueStatus.activeTurnBidderId == _userId;
  }

  /// Milliseconds remaining in this user's turn (0 if not their turn)
  int get turnRemainingMs {
    if (!isMyTurn) return 0;
    return _queueStatus.turnRemainingMs;
  }

  /// Whether the user can currently raise their hand
  bool get canRaiseHand => !_isProcessing && !_hasRaisedHand;

  /// The user's position in the current queue (null if not in queue).
  /// Only counts entries with active statuses (pending or active_turn).
  int? get queuePosition {
    if (_userId == null) return null;
    final entry = _queueStatus.queue
        .where(
          (e) =>
              e.bidderId == _userId &&
              (e.status == 'pending' || e.status == 'active_turn'),
        )
        .toList();
    return entry.isNotEmpty ? entry.first.position : null;
  }

  /// Loads auction details and related data (bid history, Q&A)
  Future<void> loadAuctionDetail(String id, {bool isBackground = false}) async {
    if (!isBackground) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      // Get auction detail using UseCase
      final result = await _getAuctionDetailUseCase(
        auctionId: id,
        userId: _userId,
      );

      result.fold((failure) => throw Exception(failure.message), (
        auctionDetail,
      ) {
        _auction = auctionDetail;
        // Sync bid increment with seller-configured minimum
        _bidIncrement = auctionDetail.minBidIncrement;
      });

      // Load any saved user preference (persisted increment) if available
      if (_userId != null) {
        final incrementResult = await _getBidIncrementUseCase(
          auctionId: id,
          userId: _userId,
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

      // Load bid history, Q&A, auto-bid settings, and mystery status in parallel
      await Future.wait([
        _loadBidHistory(id),
        _loadQuestions(id),
        if (!isBackground) _loadAutoBidSettings(id),
        if (_auction?.biddingType == 'mystery') _loadMysteryBidStatus(id),
      ]);

      // Start Realtime Updates only once per auction (not on background reloads)
      if (_subscribedAuctionId != id) {
        _subscribeToRealtimeUpdates(id);
      }
    } catch (e) {
      // If background reload fails and auction already ended, mark as ended gracefully
      if (isBackground &&
          _auction != null &&
          _auction!.endTime.isBefore(DateTime.now())) {
        _auction = AuctionDetailEntity.copyWithStatus(_auction!, 'ended');
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to load auction details';
      }
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
      debugPrint('DEBUG: Loading bid history for auction: $auctionId');

      // Get bid history using UseCase
      final result = await _getBidHistoryUseCase(auctionId: auctionId);

      result.fold(
        (failure) {
          debugPrint('ERROR: Failed to load bid history: ${failure.message}');
          _bidHistory = [];
        },
        (bids) {
          _bidHistory = bids.map((bid) {
            // Set isCurrentUser flag based on bidderId
            return BidHistoryEntity(
              id: bid.id,
              auctionId: bid.auctionId,
              bidderId: bid.bidderId,
              amount: bid.amount,
              bidderName: bid.bidderName,
              username: bid.username,
              timestamp: bid.timestamp,
              isCurrentUser: _userId != null && bid.bidderId == _userId,
              isWinning: bid.isWinning,
            );
          }).toList();
          debugPrint('DEBUG: Loaded ${_bidHistory.length} bids');
        },
      );
    } catch (e, stackTrace) {
      // Log the error instead of silent fail
      debugPrint('ERROR: Failed to load bid history: $e');
      debugPrint('STACK: $stackTrace');
      _bidHistory = [];
    } finally {
      _isLoadingBidHistory = false;
    }
  }

  /// Loads Q&A questions for this auction
  Future<void> _loadQuestions(String auctionId) async {
    _isLoadingQA = true;
    try {
      debugPrint(
        'DEBUG [Controller]: ========================================',
      );
      debugPrint(
        'DEBUG [Controller]: Starting Q&A load for auction: $auctionId',
      );
      debugPrint('DEBUG [Controller]: User ID: $_userId');

      // Get questions using UseCase
      final result = await _getQuestionsUseCase(
        auctionId: auctionId,
        currentUserId: _userId,
      );

      result.fold(
        (failure) {
          debugPrint(
            'ERROR [Controller]: Failed to load Q&A: ${failure.message}',
          );
          _questions = [];
        },
        (questions) {
          _questions = questions;
          debugPrint('DEBUG [Controller]: Received response from UseCase');
          debugPrint(
            'DEBUG [Controller]: Questions count: ${_questions.length}',
          );

          if (_questions.isEmpty) {
            debugPrint('DEBUG [Controller]: ⚠️ NO QUESTIONS FOUND IN DATABASE');
            debugPrint('DEBUG [Controller]: This means:');
            debugPrint(
              'DEBUG [Controller]:   1. Q&A schema might not be run (migration 00045)',
            );
            debugPrint(
              'DEBUG [Controller]:   2. No questions have been asked yet for this listing',
            );
            debugPrint(
              'DEBUG [Controller]:   3. RLS policies might be blocking access',
            );
          }
        },
      );

      debugPrint(
        'DEBUG [Controller]: ========================================',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'ERROR [Controller]: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      );
      debugPrint('ERROR [Controller]: Failed to load Q&A: $e');
      debugPrint('STACK [Controller]: $stackTrace');
      debugPrint(
        'ERROR [Controller]: !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
      );
      _questions = [];
    } finally {
      _isLoadingQA = false;
    }
  }

  /// Posts a new question to the auction
  Future<void> askQuestion(String category, String question) async {
    if (_auction == null) return;

    debugPrint('DEBUG [Controller]: ========================================');
    debugPrint('DEBUG [Controller]: Attempting to ask question');
    debugPrint('DEBUG [Controller]: Auction ID: ${_auction!.id}');
    debugPrint('DEBUG [Controller]: Category: $category');
    debugPrint('DEBUG [Controller]: Question: $question');
    debugPrint('DEBUG [Controller]: User ID: $_userId');

    try {
      // Check authentication
      if (_userId == null) {
        debugPrint(
          'ERROR [Controller]: ❌ User not authenticated, cannot ask question',
        );
        return;
      }

      debugPrint('DEBUG [Controller]: Calling UseCase.postQuestion()...');

      // Post question using UseCase
      final result = await _postQuestionUseCase(
        auctionId: _auction!.id,
        userId: _userId,
        category: category,
        question: question,
      );

      result.fold(
        (failure) {
          debugPrint(
            'ERROR [Controller]: ❌ Failed to post question: ${failure.message}',
          );
        },
        (qa) {
          debugPrint(
            'DEBUG [Controller]: Question posted successfully: ${qa.id}',
          );
          debugPrint(
            'DEBUG [Controller]: ✅ Question posted successfully, reloading Q&A...',
          );
          _loadQuestions(_auction!.id).then((_) => notifyListeners());
        },
      );
    } catch (e, stackTrace) {
      debugPrint('ERROR [Controller]: ❌ Exception while asking question: $e');
      debugPrint('STACK [Controller]: $stackTrace');
    }
    debugPrint('DEBUG [Controller]: ========================================');
  }

  /// Toggles like on a question
  Future<void> toggleQuestionLike(String questionId) async {
    try {
      // Check authentication
      if (_userId == null) {
        debugPrint('ERROR: User not authenticated, cannot like question');
        return;
      }

      final q = _questions.firstWhere((q) => q.id == questionId);

      // Call appropriate UseCase
      if (q.isLikedByUser) {
        final result = await _unlikeQuestionUseCase(
          questionId: questionId,
          userId: _userId,
        );
        result.fold(
          (failure) => debugPrint(
            'ERROR: Failed to unlike question: ${failure.message}',
          ),
          (_) {},
        );
      } else {
        final result = await _likeQuestionUseCase(
          questionId: questionId,
          userId: _userId,
        );
        result.fold(
          (failure) =>
              debugPrint('ERROR: Failed to like question: ${failure.message}'),
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
      debugPrint('ERROR: Failed to toggle like: $e');
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

      // Client-side check: prevent bidding on private auctions without invite
      // (RLS enforces this server-side, but we give a friendlier message)
      if (_auction!.biddingType == 'private') {
        // If we can see the auction, we're likely invited — but verify deposit status
        // If the RPC fails, we'll catch the error and show a user-friendly message
        debugPrint(
          '[AuctionDetailController] Private auction — user must be invited to bid',
        );
      }

      // Enforce server-side: amount must be at least currentBid + minBidIncrement
      final current = _auction!.currentBid;
      final minInc = _auction!.minBidIncrement;
      if (amount < current + minInc) {
        _errorMessage =
            'Bid too low. Minimum increase is ₱${minInc.toStringAsFixed(0)}';
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

      // Place bid using UseCase
      // Auto-bid settings are already persisted server-side separately
      debugPrint('[AuctionDetailController] Placing bid: \$$amount');
      final result = await _placeBidUseCase(
        auctionId: _auction!.id,
        bidderId: effectiveUserId,
        amount: amount,
        isAutoBid: false, // Manual bid from user
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (_) {
          debugPrint(
            '[AuctionDetailController] Bid placed successfully, reloading auction data...',
          );
          // Reload auction to update current bid and bid history
          // This will also get the potentially extended end_time from snipe guard
          loadAuctionDetail(_auction!.id);
          debugPrint(
            '[AuctionDetailController] Auction data reloaded. New end time: ${_auction!.endTime}',
          );
          return true;
        },
      );
    } catch (e) {
      final errorStr = e.toString();
      if (_auction?.biddingType == 'private' &&
          (errorStr.contains('policy') ||
              errorStr.contains('permission') ||
              errorStr.contains('denied') ||
              errorStr.contains('RLS'))) {
        _errorMessage =
            'You are not invited to bid on this private auction. Please request an invite from the seller.';
      } else if (errorStr.contains('Failed to place bid')) {
        _errorMessage = errorStr.replaceFirst('Exception: ', '');
      } else {
        _errorMessage = 'Failed to place bid: $errorStr';
      }
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

  // ── Mystery Bid Methods ──────────────────────────────────────────────

  Future<void> _loadMysteryBidStatus(String auctionId) async {
    if (_userId == null) return;
    _isLoadingMysteryStatus = true;
    try {
      final result = await _getMysteryBidStatusUseCase(
        auctionId: auctionId,
        userId: _userId!,
      );
      result.fold(
        (failure) {
          debugPrint('Failed to load mystery bid status: ${failure.message}');
        },
        (data) {
          _mysteryBidStatus = MysteryBidStatusEntity.fromJson(data);
        },
      );
    } catch (e) {
      debugPrint('Error loading mystery bid status: $e');
    } finally {
      _isLoadingMysteryStatus = false;
    }
  }

  Future<bool> placeMysteryBid(double amount) async {
    if (_auction == null) return false;
    _isProcessing = true;
    notifyListeners();

    try {
      final effectiveUserId = _userId;
      if (effectiveUserId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      if (amount < _auction!.minimumBid) {
        _errorMessage =
            'Bid must be at least ₱${_auction!.minimumBid.toStringAsFixed(0)}';
        return false;
      }

      final hasToken = await _consumeBiddingTokenUsecase.call(
        userId: effectiveUserId,
        referenceId: _auction!.id,
      );
      if (!hasToken) {
        _errorMessage =
            'Insufficient bidding tokens. Please purchase more to continue bidding.';
        return false;
      }

      final result = await _placeMysteryBidUseCase(
        auctionId: _auction!.id,
        bidderId: effectiveUserId,
        amount: amount,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (_) {
          _loadMysteryBidStatus(_auction!.id).then((_) => notifyListeners());
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to place mystery bid: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Refreshes mystery bid status (used after auction ends for reveal)
  Future<void> refreshMysteryBidStatus() async {
    if (_auction == null) return;
    await _loadMysteryBidStatus(_auction!.id);
    notifyListeners();
  }

  // ── Queue-based Bidding Methods ──────────────────────────────────────

  /// Raises hand in the bid queue (queue-only — no bid amount).
  Future<bool> raiseHand() async {
    if (_auction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final effectiveUserId = _userId;
      if (effectiveUserId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      // Consume bidding token
      final hasToken = await _consumeBiddingTokenUsecase.call(
        userId: effectiveUserId,
        referenceId: _auction!.id,
      );

      if (!hasToken) {
        _errorMessage =
            'Insufficient bidding tokens. Please purchase more tokens or upgrade your subscription.';
        return false;
      }

      final result = await _raiseHandUseCase(
        auctionId: _auction!.id,
        bidderId: effectiveUserId,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (data) {
          _hasRaisedHand = true;
          debugPrint(
            '[AuctionDetailController] Hand raised! Position: ${data['position']}',
          );
          // Reload queue status immediately
          _loadQueueStatus(_auction!.id);
          // Start polling to catch cycle processing (grace period + turn assignment)
          _startQueuePolling();
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to raise hand: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Submit a bid during the user's active turn (60s window).
  /// Only works when [isMyTurn] is true.
  Future<bool> submitTurnBid({required double bidAmount}) async {
    if (_auction == null) return false;
    if (!isMyTurn) {
      _errorMessage = 'It is not your turn to bid.';
      notifyListeners();
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final effectiveUserId = _userId;
      if (effectiveUserId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      final result = await _submitTurnBidUseCase(
        auctionId: _auction!.id,
        bidderId: effectiveUserId,
        bidAmount: bidAmount,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (data) {
          _hasRaisedHand = false;
          debugPrint(
            '[AuctionDetailController] Turn bid placed: ₱${data['bid_amount']}',
          );
          // Reload auction + queue
          loadAuctionDetail(_auction!.id, isBackground: true);
          _loadQueueStatus(_auction!.id);
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to submit bid: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Lowers hand — withdraws from the bid queue.
  /// Buyer can back out at any time, even during their turn.
  Future<bool> lowerHand() async {
    if (_auction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final effectiveUserId = _userId;
      if (effectiveUserId == null) {
        _errorMessage = 'User not authenticated';
        return false;
      }

      final result = await _lowerHandUseCase(
        auctionId: _auction!.id,
        bidderId: effectiveUserId,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (data) {
          _hasRaisedHand = false;
          debugPrint('[AuctionDetailController] Hand lowered.');
          _stopQueuePolling();
          _loadQueueStatus(_auction!.id);
          return true;
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to lower hand: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Start periodic polling of queue status.
  /// Acts as a fallback in case realtime events are delayed or missed.
  /// Stops automatically when the user gets their turn or the cycle completes.
  void _startQueuePolling() {
    _stopQueuePolling();
    if (_auction == null) return;
    final auctionId = _auction!.id;
    _queuePollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await _loadQueueStatus(auctionId);
      // Stop polling once the user has their turn or is no longer in queue
      if (isMyTurn || !_hasRaisedHand) {
        _stopQueuePolling();
      }
    });
  }

  /// Stop queue polling.
  void _stopQueuePolling() {
    _queuePollTimer?.cancel();
    _queuePollTimer = null;
  }

  /// Load queue status from server
  Future<void> _loadQueueStatus(String auctionId) async {
    try {
      final result = await _getQueueStatusUseCase(auctionId: auctionId);
      result.fold(
        (failure) {
          debugPrint('Failed to load queue status: ${failure.message}');
        },
        (status) {
          _queueStatus = status;
          // Derive _hasRaisedHand from server data (survives tab switches)
          if (status.state == 'complete' || status.state == 'idle') {
            _hasRaisedHand = false;
          } else if (_userId != null) {
            _hasRaisedHand = status.queue.any(
              (e) =>
                  e.bidderId == _userId &&
                  (e.status == 'pending' || e.status == 'active_turn'),
            );
          }
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error loading queue status: $e');
    }
  }

  /// Sets auto-bid configuration and persists to server
  /// When active, system will automatically bid when outbid, up to maxBid amount
  /// Logic is handled server-side via process_auto_bids() PostgreSQL function
  Future<bool> setAutoBid(
    bool isActive,
    double? maxBid,
    double increment,
  ) async {
    if (_auction == null || _userId == null) return false;

    // Respect seller-configured minimum bid increment
    final minIncrement = _auction?.minBidIncrement ?? increment;
    final effectiveIncrement = increment < minIncrement
        ? minIncrement
        : increment;

    if (isActive && maxBid != null) {
      // Save auto-bid settings to server via RPC
      final result = await _saveAutoBidSettingsUseCase(
        auctionId: _auction!.id,
        userId: _userId,
        maxBidAmount: maxBid,
        bidIncrement: effectiveIncrement,
        isActive: true,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (_) {
          _isAutoBidActive = true;
          _maxAutoBid = maxBid;
          _bidIncrement = effectiveIncrement;
          notifyListeners();
          debugPrint(
            '[AutoBid] Activated: max=₱$maxBid, increment=₱$effectiveIncrement',
          );
          return true;
        },
      );
    } else {
      // Deactivate auto-bid on server
      final result = await _deactivateAutoBidUseCase(
        auctionId: _auction!.id,
        userId: _userId,
      );

      return result.fold(
        (failure) {
          _errorMessage = failure.message;
          notifyListeners();
          return false;
        },
        (_) {
          _isAutoBidActive = false;
          _maxAutoBid = null;
          notifyListeners();
          debugPrint('[AutoBid] Deactivated');
          return true;
        },
      );
    }
  }

  /// Load saved auto-bid settings from server
  Future<void> _loadAutoBidSettings(String auctionId) async {
    if (_userId == null) return;

    try {
      final result = await _getAutoBidSettingsUseCase(
        auctionId: auctionId,
        userId: _userId,
      );

      result.fold(
        (failure) {
          debugPrint('Failed to load auto-bid settings: ${failure.message}');
        },
        (settings) {
          if (settings != null) {
            _isAutoBidActive = settings['is_active'] == true;
            _maxAutoBid = (settings['max_bid_amount'] as num?)?.toDouble();
            final savedIncrement = (settings['bid_increment'] as num?)
                ?.toDouble();
            if (savedIncrement != null) {
              _bidIncrement = savedIncrement;
            }
            debugPrint(
              '[AutoBid] Loaded settings: active=$_isAutoBidActive, max=$_maxAutoBid, increment=$_bidIncrement',
            );
          } else {
            _isAutoBidActive = false;
            _maxAutoBid = null;
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading auto-bid settings: $e');
    }
  }

  /// Subscribe to realtime updates for auction, bids, and queue
  void _subscribeToRealtimeUpdates(String auctionId) {
    // Cancel existing subscriptions if any
    _auctionSubscription?.cancel();
    _bidSubscription?.cancel();
    _queueSubscription?.cancel();
    _subscribedAuctionId = auctionId;

    debugPrint(
      'DEBUG: Subscribing to realtime updates for auction: $auctionId',
    );

    // Subscribe to auction updates (price, end_time)
    _auctionSubscription = _streamAuctionUpdatesUseCase(auctionId: auctionId)
        .skip(1)
        .listen(
          (_) {
            debugPrint('DEBUG: Realtime auction update received');
            // Reload auction details quietly
            loadAuctionDetail(auctionId, isBackground: true);
          },
          onError: (e) {
            debugPrint('ERROR: Realtime auction subscription error: $e');
          },
        );

    // Subscribe to bid updates (new bids)
    _bidSubscription = _streamBidUpdatesUseCase(auctionId: auctionId)
        .skip(1)
        .listen(
          (_) {
            debugPrint('DEBUG: Realtime bid update received');
            // Reload full auction detail so top current bid stays in sync with latest bid.
            loadAuctionDetail(auctionId, isBackground: true);
          },
          onError: (e) {
            debugPrint('ERROR: Realtime bid subscription error: $e');
          },
        );

    // Subscribe to Q&A updates
    _qaSubscription =
        _streamQAUpdatesUseCase(
          auctionId: auctionId,
          currentUserId: _userId,
        ).listen(
          (questions) {
            debugPrint('DEBUG: Realtime Q&A update received');
            _questions = questions;
            notifyListeners();
          },
          onError: (e) {
            debugPrint('ERROR: Realtime Q&A subscription error: $e');
          },
        );

    // Subscribe to bid queue cycle updates
    _queueSubscription = _streamQueueUpdatesUseCase(auctionId: auctionId).listen(
      (status) {
        debugPrint(
          'DEBUG: Queue update received — state: ${status.state}, cycle: ${status.cycleNumber}',
        );
        _queueStatus = status;
        // Derive raised-hand state from server data.
        // MUST filter by active statuses — withdrawn/executed/expired/skipped
        // entries are still returned in the queue array from get_queue_status.
        if (status.state == 'complete' || status.state == 'idle') {
          _hasRaisedHand = false;
        } else if (_userId != null) {
          _hasRaisedHand = status.queue.any(
            (e) =>
                e.bidderId == _userId &&
                (e.status == 'pending' || e.status == 'active_turn'),
          );
        }
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ERROR: Queue subscription error: $e');
      },
    );

    // Initial queue status load
    _loadQueueStatus(auctionId);
  }

  @override
  void dispose() {
    _auctionSubscription?.cancel();
    _bidSubscription?.cancel();
    _qaSubscription?.cancel();
    _queueSubscription?.cancel();
    _stopQueuePolling();
    _subscribedAuctionId = null;
    super.dispose();
  }
}
