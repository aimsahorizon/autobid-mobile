import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/user_bid_entity.dart';
import '../../domain/usecases/get_user_bids_usecase.dart';
import '../../domain/usecases/stream_user_bids_usecase.dart';
import '../../../auth/domain/repositories/auth_repository.dart';

/// Controller for managing user's bid history state
/// Handles loading and categorizing bids by status (active, won, lost)
class BidsController extends ChangeNotifier {
  final GetUserBidsUseCase _getUserBidsUseCase;
  final StreamUserBidsUseCase _streamUserBidsUseCase;
  final AuthRepository _authRepository;

  BidsController(
    this._getUserBidsUseCase,
    this._streamUserBidsUseCase,
    this._authRepository,
  );

  // State properties - private with public getters
  List<UserBidEntity> _activeBids = [];
  List<UserBidEntity> _wonBids = [];
  List<UserBidEntity> _lostBids = [];
  List<UserBidEntity> _cancelledBids = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Polling mechanism and stream subscription
  Timer? _pollTimer;
  StreamSubscription? _bidsSubscription;

  // Public getters for accessing state
  List<UserBidEntity> get activeBids => _activeBids;
  List<UserBidEntity> get wonBids => _wonBids;
  List<UserBidEntity> get lostBids => _lostBids;
  List<UserBidEntity> get cancelledBids => _cancelledBids;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Loads all user bids from data source
  /// Categorizes them into active, won, and lost lists
  /// Called on page init and when user pulls to refresh
  /// Also starts polling to auto-refresh when active auctions end
  Future<void> loadUserBids() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get current user ID
      final userId = (await _authRepository.getCurrentUser()).fold(
        (l) => null,
        (r) => r?.id,
      );

      if (userId == null) {
        _errorMessage = 'User not authenticated';
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Fetch all bids using UseCase
      final result = await _getUserBidsUseCase.call(userId);

      result.fold(
        (failure) {
          _errorMessage = failure.message;
        },
        (bidsMap) {
          // Update state with categorized bids
          _activeBids = bidsMap['active'] ?? [];
          _wonBids = bidsMap['won'] ?? [];
          _lostBids = bidsMap['lost'] ?? [];
          _cancelledBids = bidsMap['cancelled'] ?? [];

          // Start polling if there are active bids
          if (_activeBids.isNotEmpty) {
            _startPolling();
          } else {
            _stopPolling();
          }

          // Start Realtime Subscription if not active
          if (_bidsSubscription == null) {
            _subscribeToBids(userId);
          }
        },
      );
    } catch (e) {
      // Handle unexpected error
      _errorMessage = 'Failed to load your bids. Please try again.';
    } finally {
      // Always set loading to false
      _isLoading = false;
      notifyListeners();
    }
  }

  void _subscribeToBids(String userId) {
    _bidsSubscription?.cancel();
    _bidsSubscription = _streamUserBidsUseCase(userId).listen(
      (_) {
        debugPrint('DEBUG: Realtime user bid update received');
        refreshActiveBids(); // Reuse existing refresh logic
      },
      onError: (e) {
        debugPrint('ERROR: Realtime user bid subscription error: $e');
      },
    );
  }

  /// Starts polling to check if active auctions have ended
  /// Polls every 10 seconds to refresh bid status
  void _startPolling() {
    _stopPolling(); // Cancel any existing timer

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final userId = (await _authRepository.getCurrentUser()).fold(
          (l) => null,
          (r) => r?.id,
        );
        if (userId == null) return;

        final result = await _getUserBidsUseCase.call(userId);

        result.fold(
          (failure) => null, // Silent fail on polling
          (bidsMap) {
            final newActiveBids = bidsMap['active'] ?? [];
            final newWonBids = bidsMap['won'] ?? [];
            final newLostBids = bidsMap['lost'] ?? [];
            final newCancelledBids = bidsMap['cancelled'] ?? [];

            // Only update if bids changed (avoid unnecessary rebuilds)
            if (newActiveBids.length != _activeBids.length ||
                newWonBids.length != _wonBids.length ||
                newLostBids.length != _lostBids.length ||
                newCancelledBids.length != _cancelledBids.length) {
              debugPrint(
                '[BidsController] Bids changed during polling - updating UI',
              );
              _activeBids = newActiveBids;
              _wonBids = newWonBids;
              _lostBids = newLostBids;
              _cancelledBids = newCancelledBids;
              notifyListeners();

              // Stop polling if no more active bids
              if (_activeBids.isEmpty) {
                _stopPolling();
              }
            }
          },
        );
      } catch (e) {
        debugPrint('[BidsController] Polling error: $e');
        // Silent fail - don't interrupt user experience
      }
    });
  }

  /// Stops the polling timer
  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _stopPolling();
    _bidsSubscription?.cancel();
    super.dispose();
  }

  /// Refreshes only active bids for real-time updates
  Future<void> refreshActiveBids() async {
    try {
      final userId = (await _authRepository.getCurrentUser()).fold(
        (l) => null,
        (r) => r?.id,
      );
      if (userId == null) return;

      final result = await _getUserBidsUseCase.call(userId);

      result.fold((failure) => null, (bidsMap) {
        _activeBids = bidsMap['active'] ?? [];
        notifyListeners();
      });
    } catch (e) {
      // Silent fail
    }
  }

  /// Clears error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Get total count of all user bids
  int get totalBidsCount =>
      _activeBids.length +
      _wonBids.length +
      _lostBids.length +
      _cancelledBids.length;

  /// Get count of bids where user is currently winning
  int get winningBidsCount =>
      _activeBids.where((bid) => bid.isHighestBidder).length;

  /// Get count of bids where user is being outbid
  int get outbidCount =>
      _activeBids.where((bid) => !bid.isHighestBidder).length;
}
