import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_status_entity.dart';
import '../../../lists/domain/entities/seller_listing_entity.dart';
import '../../data/datasources/transaction_supabase_datasource.dart';

/// Controller for both buyer and seller transactions
/// Manages the Transactions page with dual perspective (buyer + seller)
class BuyerSellerTransactionsController extends ChangeNotifier {
  final TransactionSupabaseDataSource _dataSource;
  final String _userId;

  // Buyer transactions (where user is buyer_id in auction_transactions)
  Map<TransactionStatus, List<SellerListingEntity>> _buyerTransactions = {};

  // Seller transactions (where user is seller_id in auction_transactions)
  Map<TransactionStatus, List<SellerListingEntity>> _sellerTransactions = {};

  bool _isLoading = false;
  String? _error;

  BuyerSellerTransactionsController(
    this._dataSource,
    dynamic _, // Keep signature compatible, ignore old buyer datasource
    this._userId,
  );

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get buyer transactions by status
  List<SellerListingEntity> getBuyerTransactionsByStatus(
    TransactionStatus status,
  ) {
    return _buyerTransactions[status] ?? [];
  }

  /// Get seller transactions by status
  List<SellerListingEntity> getSellerTransactionsByStatus(
    TransactionStatus status,
  ) {
    return _sellerTransactions[status] ?? [];
  }

  /// Get buyer transaction count by status
  int getBuyerCountByStatus(TransactionStatus status) {
    return _buyerTransactions[status]?.length ?? 0;
  }

  /// Get seller transaction count by status
  int getSellerCountByStatus(TransactionStatus status) {
    return _sellerTransactions[status]?.length ?? 0;
  }

  /// Load both buyer and seller transactions
  Future<void> loadTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadBuyerTransactions(), _loadSellerTransactions()]);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      debugPrint('[BuyerSellerTransactionsController] Error: $e');
    }
  }

  /// Load buyer transactions (from auction_transactions where buyer_id = userId)
  Future<void> _loadBuyerTransactions() async {
    debugPrint('[DEBUG] Loading BUYER transactions for userId: $_userId');
    try {
      final Map<TransactionStatus, List<SellerListingEntity>> result = {};

      // Active buyer transactions
      try {
        final active = await _dataSource.getActiveBuyerTransactions(_userId);
        debugPrint('[DEBUG] BUYER active raw count: ${active.length}');
        for (final m in active) {
          debugPrint(
            '[DEBUG] BUYER active: id=${m.id}, car=${m.brand} ${m.model}, sellerId=${m.sellerId}',
          );
        }
        result[TransactionStatus.inTransaction] =
            active.map((m) => m.toSellerListingEntity()).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('[DEBUG] Error loading buyer active: $e');
        result[TransactionStatus.inTransaction] = [];
      }

      // Completed buyer transactions
      try {
        final completed = await _dataSource.getCompletedBuyerTransactions(
          _userId,
        );
        debugPrint('[DEBUG] BUYER completed raw count: ${completed.length}');
        for (final m in completed) {
          debugPrint(
            '[DEBUG] BUYER completed: id=${m.id}, sellerId=${m.sellerId}',
          );
        }
        result[TransactionStatus.sold] =
            completed.map((m) => m.toSellerListingEntity()).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('[DEBUG] Error loading buyer completed: $e');
        result[TransactionStatus.sold] = [];
      }

      // Failed buyer transactions
      try {
        final failed = await _dataSource.getFailedBuyerTransactions(_userId);
        debugPrint('[DEBUG] BUYER failed raw count: ${failed.length}');
        for (final m in failed) {
          debugPrint(
            '[DEBUG] BUYER failed: id=${m.id}, sellerId=${m.sellerId}',
          );
        }
        result[TransactionStatus.dealFailed] =
            failed.map((m) => m.toSellerListingEntity()).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('[DEBUG] Error loading buyer failed: $e');
        result[TransactionStatus.dealFailed] = [];
      }

      _buyerTransactions = result;
      debugPrint(
        '[DEBUG] BUYER final: inTx=${result[TransactionStatus.inTransaction]?.length}, sold=${result[TransactionStatus.sold]?.length}, failed=${result[TransactionStatus.dealFailed]?.length}',
      );
    } catch (e) {
      debugPrint('[DEBUG] Error loading buyer transactions: $e');
      _buyerTransactions = {
        TransactionStatus.inTransaction: [],
        TransactionStatus.sold: [],
        TransactionStatus.dealFailed: [],
      };
    }
  }

  /// Load seller transactions (from auction_transactions where seller_id = userId)
  Future<void> _loadSellerTransactions() async {
    debugPrint('[DEBUG] Loading SELLER transactions for userId: $_userId');
    try {
      final Map<TransactionStatus, List<SellerListingEntity>> result = {};

      // Active seller transactions
      try {
        final active = await _dataSource.getActiveTransactions(_userId);
        debugPrint('[DEBUG] SELLER active raw count: ${active.length}');
        for (final m in active) {
          debugPrint(
            '[DEBUG] SELLER active: id=${m.id}, car=${m.brand} ${m.model}, sellerId=${m.sellerId}',
          );
        }
        result[TransactionStatus.inTransaction] =
            active.map((m) => m.toSellerListingEntity()).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('[DEBUG] Error loading seller active: $e');
        result[TransactionStatus.inTransaction] = [];
      }

      // Completed seller transactions
      try {
        final completed = await _dataSource.getCompletedTransactions(_userId);
        debugPrint('[DEBUG] SELLER completed raw count: ${completed.length}');
        for (final m in completed) {
          debugPrint(
            '[DEBUG] SELLER completed: id=${m.id}, sellerId=${m.sellerId}',
          );
        }
        result[TransactionStatus.sold] =
            completed.map((m) => m.toSellerListingEntity()).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('[DEBUG] Error loading seller completed: $e');
        result[TransactionStatus.sold] = [];
      }

      // Failed seller transactions
      try {
        final failed = await _dataSource.getFailedTransactions(_userId);
        debugPrint('[DEBUG] SELLER failed raw count: ${failed.length}');
        for (final m in failed) {
          debugPrint(
            '[DEBUG] SELLER failed: id=${m.id}, sellerId=${m.sellerId}',
          );
        }
        result[TransactionStatus.dealFailed] =
            failed.map((m) => m.toSellerListingEntity()).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } catch (e) {
        debugPrint('[DEBUG] Error loading seller failed: $e');
        result[TransactionStatus.dealFailed] = [];
      }

      _sellerTransactions = result;
      debugPrint(
        '[DEBUG] SELLER final: inTx=${result[TransactionStatus.inTransaction]?.length}, sold=${result[TransactionStatus.sold]?.length}, failed=${result[TransactionStatus.dealFailed]?.length}',
      );
    } catch (e) {
      debugPrint('[DEBUG] Error loading seller transactions: $e');
      _sellerTransactions = {
        TransactionStatus.inTransaction: [],
        TransactionStatus.sold: [],
        TransactionStatus.dealFailed: [],
      };
    }
  }

  /// Refresh all transactions
  Future<void> refresh() => loadTransactions();
}
