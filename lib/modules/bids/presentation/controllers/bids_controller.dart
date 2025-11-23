import 'package:flutter/material.dart';
import '../../domain/entities/user_bid_entity.dart';
import '../../data/datasources/user_bids_mock_datasource.dart';

/// Controller for managing user's bid history state
/// Handles loading and categorizing bids by status (active, won, lost)
///
/// State management pattern: ChangeNotifier for reactive UI updates
/// Usage: Inject into BidsPage and listen for state changes
class BidsController extends ChangeNotifier {
  // Data source dependency - can be swapped with real implementation
  final UserBidsMockDataSource _dataSource;

  BidsController(this._dataSource);

  // State properties - private with public getters
  List<UserBidEntity> _activeBids = [];
  List<UserBidEntity> _wonBids = [];
  List<UserBidEntity> _lostBids = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Public getters for accessing state
  List<UserBidEntity> get activeBids => _activeBids;
  List<UserBidEntity> get wonBids => _wonBids;
  List<UserBidEntity> get lostBids => _lostBids;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Loads all user bids from data source
  /// Categorizes them into active, won, and lost lists
  /// Called on page init and when user pulls to refresh
  Future<void> loadUserBids() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Fetch all bids grouped by status from data source
      final bidsMap = await _dataSource.getUserBids();

      // Update state with categorized bids
      _activeBids = bidsMap['active'] ?? [];
      _wonBids = bidsMap['won'] ?? [];
      _lostBids = bidsMap['lost'] ?? [];
    } catch (e) {
      // Handle error - show user-friendly message
      _errorMessage = 'Failed to load your bids. Please try again.';
    } finally {
      // Always set loading to false, even on error
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes only active bids for real-time updates
  /// Useful for background polling without full reload
  Future<void> refreshActiveBids() async {
    try {
      _activeBids = await _dataSource.getActiveBids();
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
  int get totalBidsCount => _activeBids.length + _wonBids.length + _lostBids.length;

  /// Get count of bids where user is currently winning
  int get winningBidsCount => _activeBids.where((bid) => bid.isHighestBidder).length;

  /// Get count of bids where user is being outbid
  int get outbidCount => _activeBids.where((bid) => !bid.isHighestBidder).length;
}
