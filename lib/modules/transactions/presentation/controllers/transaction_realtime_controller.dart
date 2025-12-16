import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../data/datasources/transaction_realtime_datasource.dart';

/// Controller for real-time transaction management
/// Supports live chat updates between buyer and seller
class TransactionRealtimeController extends ChangeNotifier {
  final TransactionRealtimeDataSource _dataSource;

  // Subscriptions
  StreamSubscription<ChatMessageEntity>? _chatSubscription;
  StreamSubscription<Map<String, dynamic>>? _transactionSubscription;

  TransactionRealtimeController(this._dataSource);

  // State
  TransactionEntity? _transaction;
  List<ChatMessageEntity> _chatMessages = [];
  TransactionFormEntity? _myForm;
  TransactionFormEntity? _otherPartyForm;
  List<TransactionTimelineEntity> _timeline = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _currentUserId;

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
  String? get currentUserId => _currentUserId;

  // Determine user's role (seller or buyer)
  FormRole getUserRole(String userId) {
    if (_transaction == null) return FormRole.seller;
    return _transaction!.sellerId == userId ? FormRole.seller : FormRole.buyer;
  }

  /// Load transaction and subscribe to real-time updates
  Future<void> loadTransaction(String transactionId, String userId) async {
    print(
      '[TransactionRealtimeController] ========================================',
    );
    print(
      '[TransactionRealtimeController] Loading transaction: $transactionId',
    );
    print('[TransactionRealtimeController] User ID: $userId');

    _isLoading = true;
    _errorMessage = null;
    _currentUserId = userId;
    notifyListeners();

    try {
      // Try to load transaction (could be transaction ID or auction ID)
      _transaction = await _dataSource.getTransaction(transactionId);

      if (_transaction == null) {
        _errorMessage =
            'Transaction not found. The seller may not have started the transaction yet.';
        print('[TransactionRealtimeController] ❌ Transaction not found');
        return;
      }

      print(
        '[TransactionRealtimeController] ✅ Transaction loaded: ${_transaction!.id}',
      );
      print(
        '[TransactionRealtimeController] Seller: ${_transaction!.sellerId}',
      );
      print('[TransactionRealtimeController] Buyer: ${_transaction!.buyerId}');
      print(
        '[TransactionRealtimeController] Status: ${_transaction!.status.label}',
      );

      final role = getUserRole(userId);
      final otherRole = role == FormRole.seller
          ? FormRole.buyer
          : FormRole.seller;

      print('[TransactionRealtimeController] Current user role: ${role.name}');

      // Load all data in parallel
      await Future.wait([
        _loadChatMessages(_transaction!.id),
        _loadMyForm(_transaction!.id, role),
        _loadOtherPartyForm(_transaction!.id, otherRole),
        _loadTimeline(_transaction!.id),
      ]);

      // Subscribe to real-time updates
      _subscribeToRealtime(_transaction!.id);

      print(
        '[TransactionRealtimeController] Loaded ${_chatMessages.length} messages',
      );
      print(
        '[TransactionRealtimeController] Loaded ${_timeline.length} timeline events',
      );
      print(
        '[TransactionRealtimeController] ✅ Transaction loaded successfully',
      );
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load transaction: $e';
      print('[TransactionRealtimeController] ❌ Error: $e');
      print('[TransactionRealtimeController] Stack: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
      print(
        '[TransactionRealtimeController] ========================================',
      );
    }
  }

  void _subscribeToRealtime(String transactionId) {
    // Subscribe to chat messages
    _chatSubscription?.cancel();
    _dataSource.subscribeToChat(transactionId);
    _chatSubscription = _dataSource.chatStream.listen((message) {
      // Only add if not already in list (avoid duplicates)
      if (!_chatMessages.any((m) => m.id == message.id)) {
        _chatMessages.add(message);
        notifyListeners();
        print(
          '[TransactionRealtimeController] 📨 New message received: ${message.message}',
        );
      }
    });

    // Subscribe to transaction updates
    _transactionSubscription?.cancel();
    _dataSource.subscribeToTransaction(transactionId);
    _transactionSubscription = _dataSource.transactionUpdateStream.listen((
      data,
    ) async {
      print('[TransactionRealtimeController] 🔄 Transaction updated');
      // Reload transaction to get fresh data
      if (_currentUserId != null) {
        await loadTransaction(transactionId, _currentUserId!);
      }
    });
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

  /// Send chat message (real-time)
  Future<void> sendMessage(
    String userId,
    String userName,
    String message,
  ) async {
    if (_transaction == null || message.trim().isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final newMessage = await _dataSource.sendMessage(
        _transaction!.id,
        userId,
        userName,
        message.trim(),
      );

      if (newMessage != null) {
        // Add locally immediately for instant feedback
        // Real-time subscription will handle sync with other user
        if (!_chatMessages.any((m) => m.id == newMessage.id)) {
          _chatMessages.add(newMessage);
        }
        print('[TransactionRealtimeController] ✅ Message sent');
      }
    } catch (e) {
      _errorMessage = 'Failed to send message';
      print('[TransactionRealtimeController] ❌ Error sending message: $e');
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
      final updatedForm = await _dataSource.submitForm(form);

      if (updatedForm != null) {
        _myForm = updatedForm;

        // Reload timeline
        await _loadTimeline(_transaction!.id);

        // Reload transaction to update flags
        if (_currentUserId != null) {
          _transaction = await _dataSource.getTransaction(_transaction!.id);
        }

        notifyListeners();
        print('[TransactionRealtimeController] ✅ Form submitted');
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit form';
      print('[TransactionRealtimeController] ❌ Error submitting form: $e');
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
      final success = await _dataSource.confirmForm(
        _transaction!.id,
        otherPartyRole,
      );

      if (success) {
        // Reload to get updated state
        if (_currentUserId != null) {
          await loadTransaction(_transaction!.id, _currentUserId!);
        }
        print('[TransactionRealtimeController] ✅ Form confirmed');
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to confirm form';
      print('[TransactionRealtimeController] ❌ Error confirming form: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Withdraw confirmation of other party's form
  /// Allows user to cancel their confirmation and request changes
  Future<bool> withdrawConfirmation(FormRole otherPartyRole) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.withdrawConfirmation(
        _transaction!.id,
        otherPartyRole,
      );

      if (success) {
        // Reload to get updated state
        if (_currentUserId != null) {
          await loadTransaction(_transaction!.id, _currentUserId!);
        }
        print('[TransactionRealtimeController] ✅ Confirmation withdrawn');
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to withdraw confirmation';
      print(
        '[TransactionRealtimeController] ❌ Error withdrawing confirmation: $e',
      );
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Buyer cancels the deal
  /// Returns true if cancellation was successful
  Future<bool> buyerCancelDeal({String reason = ''}) async {
    print('[TransactionRealtimeController] buyerCancelDeal called');
    print('[TransactionRealtimeController] Transaction: ${_transaction?.id}');
    print('[TransactionRealtimeController] Current user: $_currentUserId');

    if (_transaction == null) {
      print('[TransactionRealtimeController] ❌ No transaction loaded');
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      print(
        '[TransactionRealtimeController] Calling datasource.buyerCancelDeal with ID: ${_transaction!.id}',
      );
      final success = await _dataSource.buyerCancelDeal(
        _transaction!.id,
        reason: reason,
      );

      if (success) {
        // Reload to get updated state
        if (_currentUserId != null) {
          await loadTransaction(_transaction!.id, _currentUserId!);
        }
        print('[TransactionRealtimeController] ✅ Deal cancelled by buyer');
      } else {
        print(
          '[TransactionRealtimeController] ❌ buyerCancelDeal returned false',
        );
      }
      return success;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to cancel deal';
      print('[TransactionRealtimeController] ❌ Error cancelling deal: $e');
      print('[TransactionRealtimeController] Stack trace: $stackTrace');
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

  /// Offer the transaction to the next highest bidder
  Future<bool> offerToNextHighestBidder() async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.offerToNextHighestBidder(
        _transaction!.id,
      );

      if (success && _currentUserId != null) {
        await loadTransaction(_transaction!.id, _currentUserId!);
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to offer to next bidder';
      print('[TransactionRealtimeController] ❌ Error offering next bidder: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Relist the auction for a new bidding round
  Future<bool> relistAuction() async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.relistAuction(_transaction!.id);

      if (success && _currentUserId != null) {
        await loadTransaction(_transaction!.id, _currentUserId!);
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to relist auction';
      print('[TransactionRealtimeController] ❌ Error relisting auction: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    if (_transaction != null && _currentUserId != null) {
      await loadTransaction(_transaction!.id, _currentUserId!);
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _transactionSubscription?.cancel();
    _dataSource.dispose();
    super.dispose();
  }
}
