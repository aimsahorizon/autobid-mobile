import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/user_bid_entity.dart';

/// Abstract data source interface for user bids
/// Allows switching between mock and Supabase implementations
abstract class IUserBidsDataSource {
  Future<Map<String, List<UserBidEntity>>> getUserBids([String? userId]);
}

/// Controller for managing user's bid history state
/// Handles loading and categorizing bids by status (active, won, lost)
///
/// State management pattern: ChangeNotifier for reactive UI updates
/// Usage: Inject into BidsPage and listen for state changes
class BidsController extends ChangeNotifier {
  // Data source dependency - can be mock or Supabase implementation
  final IUserBidsDataSource _dataSource;

  BidsController(this._dataSource);

  // State properties - private with public getters
  List<UserBidEntity> _activeBids = [];
  List<UserBidEntity> _wonBids = [];
  List<UserBidEntity> _lostBids = [];
  List<UserBidEntity> _cancelledBids = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Polling mechanism for auto-refresh when auctions end
  Timer? _pollTimer;

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
      // Get current user ID for Supabase queries
      final userId = SupabaseConfig.client.auth.currentUser?.id;

      // Fetch all bids grouped by status from data source
      final bidsMap = await _dataSource.getUserBids(userId);

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
    } catch (e) {
      // Handle error - show user-friendly message
      _errorMessage = 'Failed to load your bids. Please try again.';
    } finally {
      // Always set loading to false, even on error
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Starts polling to check if active auctions have ended
  /// Polls every 10 seconds to refresh bid status
  void _startPolling() {
    _stopPolling(); // Cancel any existing timer

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      try {
        final userId = SupabaseConfig.client.auth.currentUser?.id;
        if (userId == null) return;

        final bidsMap = await _dataSource.getUserBids(userId);
        final newActiveBids = bidsMap['active'] ?? [];
        final newWonBids = bidsMap['won'] ?? [];
        final newLostBids = bidsMap['lost'] ?? [];
        final newCancelledBids = bidsMap['cancelled'] ?? [];

        // Only update if bids changed (avoid unnecessary rebuilds)
        if (newActiveBids.length != _activeBids.length ||
            newWonBids.length != _wonBids.length ||
            newLostBids.length != _lostBids.length ||
            newCancelledBids.length != _cancelledBids.length) {
          print('[BidsController] Bids changed during polling - updating UI');
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
      } catch (e) {
        print('[BidsController] Polling error: $e');
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
    super.dispose();
  }

  /// Refreshes only active bids for real-time updates
  /// Useful for background polling without full reload
  Future<void> refreshActiveBids() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      final bidsMap = await _dataSource.getUserBids(userId);
      _activeBids = bidsMap['active'] ?? [];
      notifyListeners();
    } catch (e) {
      // Silent fail - don't interrupt user experience
      // Log error in production for debugging
    }
  }

  /// Clears error message
  /// Called when user dismisses error banner or retries
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
