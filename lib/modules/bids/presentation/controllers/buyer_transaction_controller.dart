import 'package:flutter/material.dart';
import '../../domain/entities/buyer_transaction_entity.dart';
import '../../data/datasources/buyer_transaction_mock_datasource.dart';

/// Controller for buyer's transaction in won auctions
/// Manages transaction state, chat, forms, and timeline
class BuyerTransactionController extends ChangeNotifier {
  final BuyerTransactionMockDataSource _dataSource;

  BuyerTransactionController(this._dataSource);

  // State
  BuyerTransactionEntity? _transaction;
  List<TransactionChatMessage> _chatMessages = [];
  BuyerTransactionFormEntity? _myForm;
  BuyerTransactionFormEntity? _sellerForm;
  List<TransactionTimelineEvent> _timeline = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Getters
  BuyerTransactionEntity? get transaction => _transaction;
  List<TransactionChatMessage> get chatMessages => _chatMessages;
  BuyerTransactionFormEntity? get myForm => _myForm;
  BuyerTransactionFormEntity? get sellerForm => _sellerForm;
  List<TransactionTimelineEvent> get timeline => _timeline;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load transaction and all related data
  Future<void> loadTransaction(String transactionId, String buyerId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transaction = await _dataSource.getTransaction(transactionId);
      if (_transaction == null) {
        _errorMessage = 'Transaction not found';
        return;
      }

      // Load all data in parallel
      await Future.wait([
        _loadChatMessages(transactionId),
        _loadMyForm(transactionId),
        _loadSellerForm(transactionId),
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

  Future<void> _loadMyForm(String transactionId) async {
    _myForm = await _dataSource.getTransactionForm(transactionId, FormRole.buyer);
  }

  Future<void> _loadSellerForm(String transactionId) async {
    _sellerForm = await _dataSource.getTransactionForm(transactionId, FormRole.seller);
  }

  Future<void> _loadTimeline(String transactionId) async {
    _timeline = await _dataSource.getTimeline(transactionId);
  }

  /// Send chat message
  Future<void> sendMessage(String senderId, String senderName, String message) async {
    if (_transaction == null || message.trim().isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.sendMessage(
        _transaction!.id,
        senderId,
        senderName,
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

  /// Submit buyer's transaction form
  Future<bool> submitForm(BuyerTransactionFormEntity form) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.submitForm(form);
      if (success) {
        await loadTransaction(_transaction!.id, _transaction!.buyerId);
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

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
