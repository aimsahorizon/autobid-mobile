import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_status_entity.dart';
import '../../../lists/domain/entities/seller_listing_entity.dart';
import '../../data/datasources/transaction_supabase_datasource.dart';
import '../../data/datasources/transaction_realtime_datasource.dart';

/// Controller for status-based transactions (in_transaction, sold, deal_failed)
/// Manages listing transactions in the Transactions bottom nav tab
class TransactionsStatusController extends ChangeNotifier {
  final TransactionSupabaseDataSource _dataSource;
  final TransactionRealtimeDataSource _realtimeDataSource;
  final String _userId;

  Map<TransactionStatus, List<SellerListingEntity>> _transactions = {};
  bool _isLoading = false;
  String? _error;
  StreamSubscription<void>? _realtimeSubscription;

  TransactionsStatusController(
    this._dataSource,
    this._realtimeDataSource,
    this._userId,
  ) {
    _subscribeToRealtimeUpdates();
  }

  void _subscribeToRealtimeUpdates() {
    _realtimeDataSource.subscribeToUserTransactions(_userId);
    _realtimeSubscription = _realtimeDataSource.userTransactionsUpdateStream.listen((_) {
      debugPrint('[TransactionsStatusController] Realtime update received, reloading...');
      _reloadQuietly();
    });
  }

  /// Reload data quietly without showing loading state (for realtime updates)
  Future<void> _reloadQuietly() async {
    try {
      final Map<TransactionStatus, List<SellerListingEntity>> result = {};

      try {
        final active = await _dataSource.getActiveTransactions(_userId);
        result[TransactionStatus.inTransaction] = active
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        result[TransactionStatus.inTransaction] = [];
      }

      try {
        final completed = await _dataSource.getCompletedTransactions(_userId);
        result[TransactionStatus.sold] = completed
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        result[TransactionStatus.sold] = [];
      }

      try {
        final failed = await _dataSource.getFailedTransactions(_userId);
        result[TransactionStatus.dealFailed] = failed
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        result[TransactionStatus.dealFailed] = [];
      }

      _transactions = result;
      notifyListeners();
    } catch (e) {
      debugPrint('[TransactionsStatusController] Error reloading: $e');
    }
  }

  @override
  void dispose() {
    _realtimeSubscription?.cancel();
    super.dispose();
  }

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get transactions by status
  List<SellerListingEntity> getTransactionsByStatus(TransactionStatus status) {
    return _transactions[status] ?? [];
  }

  /// Get count by status
  int getCountByStatus(TransactionStatus status) {
    return _transactions[status]?.length ?? 0;
  }

  /// Load all transactions
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Map<TransactionStatus, List<SellerListingEntity>> result = {};

      // Fetch active transactions (in_transaction status)
      try {
        final active = await _dataSource.getActiveTransactions(_userId);
        result[TransactionStatus.inTransaction] = active
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('[TransactionsStatusController] Error loading active: $e');
        result[TransactionStatus.inTransaction] = [];
      }

      // Fetch completed transactions (sold status)
      try {
        final completed = await _dataSource.getCompletedTransactions(_userId);
        result[TransactionStatus.sold] = completed
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint(
          '[TransactionsStatusController] Error loading completed: $e',
        );
        result[TransactionStatus.sold] = [];
      }

      // Fetch failed transactions (deal_failed status)
      try {
        final failed = await _dataSource.getFailedTransactions(_userId);
        result[TransactionStatus.dealFailed] = failed
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        debugPrint('[TransactionsStatusController] Error loading failed: $e');
        result[TransactionStatus.dealFailed] = [];
      }

      _transactions = result;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint(
        '[TransactionsStatusController] Error loading transactions: $e',
      );
    }
  }

  /// Refresh transactions (reload)
  Future<void> refresh() async {
    await loadTransactions();
  }
}
