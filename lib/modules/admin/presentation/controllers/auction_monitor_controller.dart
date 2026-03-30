import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/auction_monitor_supabase_datasource.dart';
import '../../domain/entities/auction_monitor_entity.dart';

/// Controller for admin auction monitoring
/// Provides real-time tracking of active auctions and bid activity
class AuctionMonitorController extends ChangeNotifier {
  final AuctionMonitorSupabaseDataSource _datasource;

  AuctionMonitorController(this._datasource);

  List<AuctionMonitorEntity> _auctions = [];
  List<BidMonitorEntity> _selectedAuctionBids = [];
  String? _selectedAuctionId;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<AuctionMonitorEntity>>? _auctionsSub;
  StreamSubscription<List<BidMonitorEntity>>? _bidsSub;

  // Getters
  List<AuctionMonitorEntity> get auctions => _auctions;
  List<BidMonitorEntity> get selectedAuctionBids => _selectedAuctionBids;
  String? get selectedAuctionId => _selectedAuctionId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Get critical auctions (ending soon or high activity)
  List<AuctionMonitorEntity> get criticalAuctions =>
      _auctions.where((a) => a.isFinalTwoMinutes || a.hasHighActivity).toList();

  /// Initialize monitoring with real-time updates
  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Initial load
      _auctions = await _datasource.getActiveAuctions();

      // Subscribe to real-time updates
      _auctionsSub = _datasource.streamActiveAuctions().listen(
        (auctions) {
          _auctions = auctions;
          notifyListeners();
        },
        onError: (error) {
          debugPrint('[AuctionMonitorController] Stream error: $error');
          _errorMessage = 'Failed to load auction updates';
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to initialize monitoring: $e';
      debugPrint('[AuctionMonitorController] Init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select an auction to view detailed bid history
  Future<void> selectAuction(String auctionId) async {
    if (_selectedAuctionId == auctionId) return;

    _selectedAuctionId = auctionId;
    _selectedAuctionBids = [];
    notifyListeners();

    try {
      // Cancel previous bid subscription
      await _bidsSub?.cancel();

      // Load bids for selected auction
      _selectedAuctionBids = await _datasource.getAuctionBids(auctionId);

      // Subscribe to real-time bid updates
      _bidsSub = _datasource
          .streamAuctionBids(auctionId)
          .listen(
            (bids) {
              _selectedAuctionBids = bids;
              notifyListeners();
            },
            onError: (error) {
              debugPrint('[AuctionMonitorController] Bid stream error: $error');
            },
          );

      notifyListeners();
    } catch (e) {
      debugPrint('[AuctionMonitorController] Error selecting auction: $e');
      _errorMessage = 'Failed to load auction bids';
      notifyListeners();
    }
  }

  /// Deselect current auction
  void deselectAuction() {
    _selectedAuctionId = null;
    _selectedAuctionBids = [];
    _bidsSub?.cancel();
    _bidsSub = null;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _auctions = await _datasource.getActiveAuctions();

      // Refresh selected auction bids if any
      if (_selectedAuctionId != null) {
        _selectedAuctionBids = await _datasource.getAuctionBids(
          _selectedAuctionId!,
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to refresh: $e';
      debugPrint('[AuctionMonitorController] Refresh error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter auctions by search query
  List<AuctionMonitorEntity> searchAuctions(String query) {
    if (query.isEmpty) return _auctions;

    final lowerQuery = query.toLowerCase();
    return _auctions.where((auction) {
      return auction.title.toLowerCase().contains(lowerQuery) ||
          auction.vehicleMake.toLowerCase().contains(lowerQuery) ||
          auction.vehicleModel.toLowerCase().contains(lowerQuery) ||
          auction.sellerName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get auction statistics
  Map<String, dynamic> getStatistics() {
    final endingSoon = _auctions.where((a) => a.minutesRemaining <= 30).length;
    final highActivity = _auctions.where((a) => a.totalBids > 10).length;
    final totalBids = _auctions.fold<int>(0, (sum, a) => sum + a.totalBids);

    return {
      'totalActive': _auctions.length,
      'endingSoon': endingSoon,
      'highActivity': highActivity,
      'totalBids': totalBids,
      'avgBidsPerAuction': _auctions.isEmpty
          ? 0.0
          : totalBids / _auctions.length,
    };
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _auctionsSub?.cancel();
    _bidsSub?.cancel();
    super.dispose();
  }
}
