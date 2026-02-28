import 'package:flutter/foundation.dart';
import '../../data/datasources/admin_transaction_datasource.dart';
import '../../domain/entities/admin_transaction_entity.dart';

/// Controller for admin transaction management
class AdminTransactionController extends ChangeNotifier {
  final AdminTransactionDataSource _dataSource;

  AdminTransactionController(this._dataSource);

  // State
  List<AdminTransactionEntity> _transactions = [];
  List<AdminTransactionEntity> _pendingReview = [];
  AdminTransactionStats? _stats;
  AdminTransactionEntity? _selectedTransaction;
  List<AdminTransactionFormEntity> _selectedForms = [];

  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  String _selectedFilter = 'all';

  // Getters
  List<AdminTransactionEntity> get transactions => _transactions;
  List<AdminTransactionEntity> get pendingReview => _pendingReview;
  AdminTransactionStats? get stats => _stats;
  AdminTransactionEntity? get selectedTransaction => _selectedTransaction;
  List<AdminTransactionFormEntity> get selectedForms => _selectedForms;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;

  /// Get seller form from selected forms
  AdminTransactionFormEntity? get sellerForm {
    try {
      return _selectedForms.firstWhere((f) => f.role == 'seller');
    } catch (_) {
      return null;
    }
  }

  /// Get buyer form from selected forms
  AdminTransactionFormEntity? get buyerForm {
    try {
      return _selectedForms.firstWhere((f) => f.role == 'buyer');
    } catch (_) {
      return null;
    }
  }

  /// Load all data
  Future<void> loadAll() async {
    await Future.wait([loadStats(), loadPendingReview()]);
  }

  /// Load statistics
  Future<void> loadStats() async {
    try {
      _stats = await _dataSource.getStats();
      notifyListeners();
    } catch (e) {
      debugPrint('[AdminTransactionController] Error loading stats: $e');
    }
  }

  /// Load pending review transactions
  Future<void> loadPendingReview() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _pendingReview = await _dataSource.getPendingReviewTransactions();
      _error = null;
    } catch (e) {
      _error = 'Failed to load pending reviews: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load transactions with filter
  Future<void> loadTransactions({String? statusFilter}) async {
    _isLoading = true;
    _error = null;
    if (statusFilter != null) {
      _selectedFilter = statusFilter;
    }
    notifyListeners();

    try {
      if (_selectedFilter == 'pending_review') {
        _transactions = await _dataSource.getPendingReviewTransactions();
      } else {
        _transactions = await _dataSource.getTransactions(
          statusFilter: _selectedFilter == 'all'
              ? null
              : _mapFilterToStatus(_selectedFilter),
        );
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load transactions: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _mapFilterToStatus(String filter) {
    switch (filter) {
      case 'in_transaction':
        return 'in_transaction';
      case 'sold':
        return 'sold';
      case 'deal_failed':
        return 'deal_failed';
      default:
        return null;
    }
  }

  /// Load transaction details for review
  Future<void> loadTransactionDetails(String transactionId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedTransaction = await _dataSource.getTransactionById(
        transactionId,
      );
      if (_selectedTransaction != null) {
        _selectedForms = await _dataSource.getTransactionForms(transactionId);
      }
      _error = null;
    } catch (e) {
      _error = 'Failed to load transaction details: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve transaction
  Future<bool> approveTransaction({String? notes}) async {
    if (_selectedTransaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.approveTransaction(
        _selectedTransaction!.id,
        adminNotes: notes,
      );

      if (success) {
        // Reload data
        await loadTransactionDetails(_selectedTransaction!.id);
        await loadStats();
        await loadPendingReview();
      }

      return success;
    } catch (e) {
      _error = 'Failed to approve: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Reject transaction
  Future<bool> rejectTransaction({required String reason}) async {
    if (_selectedTransaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.rejectTransaction(
        _selectedTransaction!.id,
        reason: reason,
      );

      if (success) {
        // Reload data
        await loadTransactionDetails(_selectedTransaction!.id);
        await loadStats();
        await loadPendingReview();
      }

      return success;
    } catch (e) {
      _error = 'Failed to reject: $e';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear selected transaction
  void clearSelection() {
    _selectedTransaction = null;
    _selectedForms = [];
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadAll();
    if (_selectedFilter == 'pending_review') {
      _transactions = _pendingReview;
    } else {
      await loadTransactions();
    }
  }

}
