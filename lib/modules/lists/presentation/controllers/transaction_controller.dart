import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../data/datasources/transaction_mock_datasource.dart';

/// Controller for managing transaction state and actions
/// Handles chat, forms, timeline, and transaction lifecycle
class TransactionController extends ChangeNotifier {
  final TransactionMockDataSource _dataSource;

  TransactionController(this._dataSource);

  // State
  TransactionEntity? _transaction;
  List<ChatMessageEntity> _chatMessages = [];
  TransactionFormEntity? _myForm;
  TransactionFormEntity? _otherPartyForm;
  List<TransactionTimelineEntity> _timeline = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Getters
  TransactionEntity? get transaction => _transaction;
  List<ChatMessageEntity> get chatMessages => _chatMessages;
  TransactionFormEntity? get myForm => _myForm;
  TransactionFormEntity? get otherPartyForm => _otherPartyForm;
  List<TransactionTimelineEntity> get timeline => _timeline;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  // Determine user's role (seller or buyer)
  FormRole getUserRole(String userId) {
    if (_transaction == null) return FormRole.seller;
    return _transaction!.sellerId == userId ? FormRole.seller : FormRole.buyer;
  }

  /// Load transaction and all related data
  Future<void> loadTransaction(String transactionId, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transaction = await _dataSource.getTransaction(transactionId);
      if (_transaction == null) {
        _errorMessage = 'Transaction not found';
        return;
      }

      final role = getUserRole(userId);
      final otherRole = role == FormRole.seller ? FormRole.buyer : FormRole.seller;

      // Load all data in parallel
      await Future.wait([
        _loadChatMessages(transactionId),
        _loadMyForm(transactionId, role),
        _loadOtherPartyForm(transactionId, otherRole),
        _loadTimeline(transactionId),
      ]);
    } catch (e) {
      _errorMessage = 'Failed to load transaction';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadChatMessages(String transactionId) async {
    _chatMessages = await _dataSource.getChatMessages(transactionId);
  }

  Future<void> _loadMyForm(String transactionId, FormRole role) async {
    _myForm = await _dataSource.getTransactionForm(transactionId, role);
  }

  Future<void> _loadOtherPartyForm(String transactionId, FormRole role) async {
    _otherPartyForm = await _dataSource.getTransactionForm(transactionId, role);
  }

  Future<void> _loadTimeline(String transactionId) async {
    _timeline = await _dataSource.getTimeline(transactionId);
  }

  /// Send chat message
  Future<void> sendMessage(String userId, String userName, String message) async {
    if (_transaction == null || message.trim().isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.sendMessage(
        _transaction!.id,
        userId,
        userName,
        message,
      );

      if (success) {
        await _loadChatMessages(_transaction!.id);
      }
    } catch (e) {
      _errorMessage = 'Failed to send message';
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Submit transaction form
  Future<bool> submitForm(TransactionFormEntity form) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.submitForm(form);
      if (success) {
        await loadTransaction(_transaction!.id,
          form.role == FormRole.seller ? _transaction!.sellerId : _transaction!.buyerId);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to submit form';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Confirm other party's form
  Future<bool> confirmForm(FormRole otherPartyRole) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.confirmForm(_transaction!.id, otherPartyRole);
      if (success) {
        // Reload transaction to update status
        final userId = otherPartyRole == FormRole.buyer
          ? _transaction!.sellerId
          : _transaction!.buyerId;
        await loadTransaction(_transaction!.id, userId);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to confirm form';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Submit to admin for approval
  Future<bool> submitToAdmin() async {
    if (_transaction == null || !_transaction!.readyForAdminReview) {
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.submitToAdmin(_transaction!.id);
      if (success) {
        await loadTransaction(_transaction!.id, _transaction!.sellerId);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to submit to admin';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update delivery status (seller only)
  /// Progresses through: preparing -> inTransit -> delivered -> completed
  Future<bool> updateDeliveryStatus(DeliveryStatus status) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.updateDeliveryStatus(
        _transaction!.id,
        status,
      );
      if (success) {
        await loadTransaction(_transaction!.id, _transaction!.sellerId);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update delivery status';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
