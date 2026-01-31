import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
    debugPrint(
      '[TransactionRealtimeController] ========================================',
    );
    debugPrint(
      '[TransactionRealtimeController] Loading transaction: $transactionId',
    );
    debugPrint('[TransactionRealtimeController] User ID: $userId');

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
        debugPrint('[TransactionRealtimeController] ❌ Transaction not found');
        return;
      }

      debugPrint(
        '[TransactionRealtimeController] ✅ Transaction loaded: ${_transaction!.id}',
      );
      debugPrint(
        '[TransactionRealtimeController] Seller: ${_transaction!.sellerId}',
      );
      debugPrint('[TransactionRealtimeController] Buyer: ${_transaction!.buyerId}');
      debugPrint(
        '[TransactionRealtimeController] Status: ${_transaction!.status.label}',
      );

      final role = getUserRole(userId);
      final otherRole = role == FormRole.seller
          ? FormRole.buyer
          : FormRole.seller;

      debugPrint('[TransactionRealtimeController] Current user role: ${role.name}');

      // For cancelled/failed transactions, don't load extra data
      // The page will show a special UI for cancelled/failed status
      // Note: 'deal_failed' from DB is mapped to TransactionStatus.cancelled
      if (_transaction!.status != TransactionStatus.cancelled) {
        // Load all data in parallel with individual error handling
        await Future.wait([
          _loadChatMessagesSafe(_transaction!.id),
          _loadMyFormSafe(_transaction!.id, role),
          _loadOtherPartyFormSafe(_transaction!.id, otherRole),
          _loadTimelineSafe(_transaction!.id),
        ]);

        // Subscribe to real-time updates only for active transactions
        _subscribeToRealtime(_transaction!.id);
      } else {
        debugPrint(
          '[TransactionRealtimeController] Skipping extra data for cancelled transaction',
        );
      }

      debugPrint(
        '[TransactionRealtimeController] Loaded ${_chatMessages.length} messages',
      );
      debugPrint(
        '[TransactionRealtimeController] Loaded ${_timeline.length} timeline events',
      );
      debugPrint(
        '[TransactionRealtimeController] ✅ Transaction loaded successfully',
      );
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load transaction: $e';
      debugPrint('[TransactionRealtimeController] ❌ Error: $e');
      debugPrint('[TransactionRealtimeController] Stack: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint(
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
        debugPrint(
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
      debugPrint('[TransactionRealtimeController] 🔄 Transaction updated');
      // Reload transaction to get fresh data
      if (_currentUserId != null) {
        await loadTransaction(transactionId, _currentUserId!);
      }
    });
  }

  Future<void> _loadTimeline(String transactionId) async {
    _timeline = await _dataSource.getTimeline(transactionId);
  }

  // Safe wrappers that don't throw exceptions
  Future<void> _loadChatMessagesSafe(String transactionId) async {
    try {
      _chatMessages = await _dataSource.getChatMessages(transactionId);
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Warning: Failed to load chat messages: $e',
      );
      _chatMessages = [];
    }
  }

  Future<void> _loadMyFormSafe(String transactionId, FormRole role) async {
    try {
      _myForm = await _dataSource.getTransactionForm(transactionId, role);
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Warning: Failed to load my form: $e',
      );
      _myForm = null;
    }
  }

  Future<void> _loadOtherPartyFormSafe(
    String transactionId,
    FormRole role,
  ) async {
    try {
      _otherPartyForm = await _dataSource.getTransactionForm(
        transactionId,
        role,
      );
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Warning: Failed to load other party form: $e',
      );
      _otherPartyForm = null;
    }
  }

  Future<void> _loadTimelineSafe(String transactionId) async {
    try {
      _timeline = await _dataSource.getTimeline(transactionId);
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Warning: Failed to load timeline: $e',
      );
      _timeline = [];
    }
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
        debugPrint('[TransactionRealtimeController] ✅ Message sent');
      }
    } catch (e) {
      _errorMessage = 'Failed to send message';
      debugPrint('[TransactionRealtimeController] ❌ Error sending message: $e');
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
        debugPrint('[TransactionRealtimeController] ✅ Form submitted');
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit form';
      debugPrint('[TransactionRealtimeController] ❌ Error submitting form: $e');
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
        debugPrint('[TransactionRealtimeController] ✅ Form confirmed');
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to confirm form';
      debugPrint('[TransactionRealtimeController] ❌ Error confirming form: $e');
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
        debugPrint('[TransactionRealtimeController] ✅ Confirmation withdrawn');
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to withdraw confirmation';
      debugPrint(
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
    debugPrint('[TransactionRealtimeController] buyerCancelDeal called');
    debugPrint('[TransactionRealtimeController] Transaction: ${_transaction?.id}');
    debugPrint('[TransactionRealtimeController] Current user: $_currentUserId');

    if (_transaction == null) {
      debugPrint('[TransactionRealtimeController] ❌ No transaction loaded');
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      debugPrint(
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
        debugPrint('[TransactionRealtimeController] ✅ Deal cancelled by buyer');
      } else {
        debugPrint(
          '[TransactionRealtimeController] ❌ buyerCancelDeal returned false',
        );
      }
      return success;
    } catch (e, stackTrace) {
      _errorMessage = 'Failed to cancel deal';
      debugPrint('[TransactionRealtimeController] ❌ Error cancelling deal: $e');
      debugPrint('[TransactionRealtimeController] Stack trace: $stackTrace');
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
      debugPrint('[TransactionRealtimeController] ❌ Error offering next bidder: $e');
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
      debugPrint('[TransactionRealtimeController] ❌ Error relisting auction: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Delete the auction entirely
  Future<bool> deleteAuction() async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.deleteAuction(_transaction!.id);

      if (success) {
        debugPrint('[TransactionRealtimeController] ✅ Auction deleted');
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete auction';
      debugPrint('[TransactionRealtimeController] ❌ Error deleting auction: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Get all bidders for the current auction
  Future<List<Map<String, dynamic>>> getAuctionBidders() async {
    if (_transaction == null) return [];

    try {
      return await _dataSource.getAuctionBidders(_transaction!.id);
    } catch (e) {
      debugPrint('[TransactionRealtimeController] ❌ Error getting bidders: $e');
      return [];
    }
  }

  /// Offer to a specific bidder
  Future<bool> offerToSpecificBidder(String bidderId, double bidAmount) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.offerToSpecificBidder(
        _transaction!.id,
        bidderId,
        bidAmount,
      );

      if (success && _currentUserId != null) {
        await loadTransaction(_transaction!.id, _currentUserId!);
      }

      return success;
    } catch (e) {
      _errorMessage = 'Failed to offer to bidder';
      debugPrint('[TransactionRealtimeController] ❌ Error offering to bidder: $e');
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
