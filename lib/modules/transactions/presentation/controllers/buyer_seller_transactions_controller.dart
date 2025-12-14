import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_status_entity.dart';
import '../../../bids/domain/entities/user_bid_entity.dart';
import '../../../bids/data/datasources/user_bids_supabase_datasource.dart';
import '../../../lists/domain/entities/seller_listing_entity.dart';
import '../../data/datasources/transaction_supabase_datasource.dart';

/// Controller for both buyer and seller transactions
/// Manages the Transactions page with dual perspective (buyer + seller)
class BuyerSellerTransactionsController extends ChangeNotifier {
  final TransactionSupabaseDataSource _sellerDataSource;
  final UserBidsSupabaseDataSource _buyerDataSource;
  final String _userId;

  // Buyer transactions (from bids module - won auctions in transaction status)
  Map<TransactionStatus, List<UserBidEntity>> _buyerTransactions = {};

  // Seller transactions (from transactions module - listings being transacted)
  Map<TransactionStatus, List<SellerListingEntity>> _sellerTransactions = {};

  bool _isLoading = false;
  String? _error;

  BuyerSellerTransactionsController(
    this._sellerDataSource,
    this._buyerDataSource,
    this._userId,
  );

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Get buyer transactions by status
  List<UserBidEntity> getBuyerTransactionsByStatus(TransactionStatus status) {
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
      // Load in parallel
      await Future.wait([_loadBuyerTransactions(), _loadSellerTransactions()]);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print(
        '[BuyerSellerTransactionsController] Error loading transactions: $e',
      );
    }
  }

  /// Load buyer transactions (from bids that moved to transaction status)
  Future<void> _loadBuyerTransactions() async {
    try {
      final bidsMap = await _buyerDataSource.getUserBids(_userId);

      // Buyer transactions: Show only WON bids (auction ended, buyer was highest bidder)
      // These appear in "Active" tab until transaction completes
      final wonBids = bidsMap['won'] ?? [];

      final result = <TransactionStatus, List<UserBidEntity>>{};

      // All won bids go to Active tab (includes waiting_for_seller and in_transaction)
      result[TransactionStatus.inTransaction] = wonBids;
      result[TransactionStatus.sold] = [];
      result[TransactionStatus.dealFailed] = [];

      _buyerTransactions = result;
    } catch (e) {
      print(
        '[BuyerSellerTransactionsController] Error loading buyer transactions: $e',
      );
      _buyerTransactions = {
        TransactionStatus.inTransaction: [],
        TransactionStatus.sold: [],
        TransactionStatus.dealFailed: [],
      };
    }
  }

  /// Load seller transactions (from seller listings)
  Future<void> _loadSellerTransactions() async {
    try {
      final Map<TransactionStatus, List<SellerListingEntity>> result = {};

      // Fetch active transactions (in_transaction status)
      try {
        final active = await _sellerDataSource.getActiveTransactions(_userId);
        result[TransactionStatus.inTransaction] = active
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        print(
          '[BuyerSellerTransactionsController] Error loading seller active: $e',
        );
        result[TransactionStatus.inTransaction] = [];
      }

      // Fetch completed transactions (sold status)
      try {
        final completed = await _sellerDataSource.getCompletedTransactions(
          _userId,
        );
        result[TransactionStatus.sold] = completed
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        print(
          '[BuyerSellerTransactionsController] Error loading seller completed: $e',
        );
        result[TransactionStatus.sold] = [];
      }

      // Fetch failed transactions (deal_failed status)
      try {
        final failed = await _sellerDataSource.getFailedTransactions(_userId);
        result[TransactionStatus.dealFailed] = failed
            .map((model) => model.toSellerListingEntity())
            .toList();
      } catch (e) {
        print(
          '[BuyerSellerTransactionsController] Error loading seller failed: $e',
        );
        result[TransactionStatus.dealFailed] = [];
      }

      _sellerTransactions = result;
    } catch (e) {
      print(
        '[BuyerSellerTransactionsController] Error loading seller transactions: $e',
      );
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
