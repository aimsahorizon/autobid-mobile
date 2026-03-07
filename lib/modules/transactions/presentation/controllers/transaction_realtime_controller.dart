import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_review_entity.dart';
import '../../data/datasources/transaction_realtime_datasource.dart';
import '../../domain/entities/agreement_field_entity.dart';

/// Controller for real-time transaction management
// ... (omitting lines for brevity in explanation, but including them in actual call)

/// Supports live chat updates between buyer and seller
class TransactionRealtimeController extends ChangeNotifier {
  final TransactionRealtimeDataSource _dataSource;

  // Subscriptions
  StreamSubscription<ChatMessageEntity>? _chatSubscription;
  StreamSubscription<Map<String, dynamic>>? _transactionSubscription;
  String? _subscribedTransactionId; // Track to avoid re-subscribing

  TransactionRealtimeController(this._dataSource);

  // State
  TransactionEntity? _transaction;
  List<ChatMessageEntity> _chatMessages = [];
  TransactionFormEntity? _myForm;
  TransactionFormEntity? _otherPartyForm;
  TransactionReviewEntity? _myReview;
  List<TransactionTimelineEntity> _timeline = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _currentUserId;
  List<AgreementFieldEntity> _agreementFields = [];

  // Getters
  TransactionEntity? get transaction => _transaction;
  List<ChatMessageEntity> get chatMessages => _chatMessages;
  TransactionFormEntity? get myForm => _myForm;
  TransactionFormEntity? get otherPartyForm => _otherPartyForm;
  TransactionReviewEntity? get myReview => _myReview;
  List<TransactionTimelineEntity> get timeline => _timeline;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  String? get currentUserId => _currentUserId;
  List<AgreementFieldEntity> get agreementFields => _agreementFields;

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
      debugPrint(
        '[TransactionRealtimeController] Buyer: ${_transaction!.buyerId}',
      );
      debugPrint(
        '[TransactionRealtimeController] Status: ${_transaction!.status.label}',
      );

      final role = getUserRole(userId);
      final otherRole = role == FormRole.seller
          ? FormRole.buyer
          : FormRole.seller;

      debugPrint(
        '[TransactionRealtimeController] Current user role: ${role.name}',
      );

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
          _loadReviewSafe(_transaction!.id, userId),
          _loadAgreementFieldsSafe(_transaction!.id),
        ]);

        // Finalization now happens immediately when both confirm (no grace period)

        // Subscribe to real-time updates only once per transaction
        if (_subscribedTransactionId != _transaction!.id) {
          _subscribeToRealtime(_transaction!.id);
        }
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
    // Cancel existing subscriptions
    _chatSubscription?.cancel();
    _transactionSubscription?.cancel();
    _subscribedTransactionId = transactionId;

    // Subscribe to chat messages
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

    // Subscribe to transaction updates (auction_transactions row changes)
    _dataSource.subscribeToTransaction(transactionId);

    // Subscribe to form changes (transaction_forms INSERT/UPDATE)
    _dataSource.subscribeToForms(transactionId);

    // Subscribe to timeline changes (transaction_timeline INSERT)
    _dataSource.subscribeToTimeline(transactionId);

    // Subscribe to agreement field changes
    _dataSource.subscribeToAgreementFields(transactionId);

    _transactionSubscription = _dataSource.transactionUpdateStream.listen((
      data,
    ) async {
      debugPrint('[TransactionRealtimeController] 🔄 Transaction updated');
      // Reload data quietly without re-subscribing to avoid infinite loop
      if (_currentUserId != null) {
        await _reloadTransactionData(transactionId, _currentUserId!);
      }
    });
  }

  /// Reload transaction data without re-subscribing to realtime
  Future<void> _reloadTransactionData(
    String transactionId,
    String userId,
  ) async {
    try {
      _transaction = await _dataSource.getTransaction(transactionId);

      if (_transaction == null) return;

      final role = getUserRole(userId);
      final otherRole = role == FormRole.seller
          ? FormRole.buyer
          : FormRole.seller;

      if (_transaction!.status != TransactionStatus.cancelled) {
        await Future.wait([
          _loadChatMessagesSafe(_transaction!.id),
          _loadMyFormSafe(_transaction!.id, role),
          _loadOtherPartyFormSafe(_transaction!.id, otherRole),
          _loadTimelineSafe(_transaction!.id),
          _loadReviewSafe(_transaction!.id, userId),
          _loadAgreementFieldsSafe(_transaction!.id),
        ]);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[TransactionRealtimeController] Error reloading data: $e');
    }
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

  Future<void> _loadReviewSafe(String transactionId, String userId) async {
    try {
      _myReview = await _dataSource.getReview(transactionId, userId);
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Warning: Failed to load review: $e',
      );
      _myReview = null;
    }
  }

  /// Submit a review
  Future<bool> submitReview({
    required int rating,
    int? ratingCommunication,
    int? ratingReliability,
    String? comment,
  }) async {
    if (_transaction == null || _currentUserId == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final role = getUserRole(_currentUserId!);
      final revieweeId = role == FormRole.seller
          ? _transaction!.buyerId
          : _transaction!.sellerId;

      final review = await _dataSource.submitReview(
        transactionId: _transaction!.id,
        reviewerId: _currentUserId!,
        revieweeId: revieweeId,
        rating: rating,
        ratingCommunication: ratingCommunication,
        ratingReliability: ratingReliability,
        comment: comment,
      );

      if (review != null) {
        _myReview = review;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to submit review';
      debugPrint('[TransactionRealtimeController] Error: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
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

  /// Cancel the deal (Buyer or Seller)
  /// Returns true if cancellation was successful
  Future<bool> cancelDeal({String reason = ''}) async {
    debugPrint('[TransactionRealtimeController] cancelDeal called');
    debugPrint(
      '[TransactionRealtimeController] Transaction: ${_transaction?.id}',
    );
    debugPrint('[TransactionRealtimeController] Current user: $_currentUserId');

    if (_transaction == null || _currentUserId == null) {
      debugPrint(
        '[TransactionRealtimeController] ❌ No transaction loaded or user not set',
      );
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final role = getUserRole(_currentUserId!);
      debugPrint('[TransactionRealtimeController] Cancelling as role: $role');

      debugPrint(
        '[TransactionRealtimeController] Calling datasource.cancelDeal with ID: ${_transaction!.id}',
      );
      final success = await _dataSource.cancelDeal(
        _transaction!.id,
        role,
        reason: reason,
      );

      if (success) {
        // Reload to get updated state
        if (_currentUserId != null) {
          await loadTransaction(_transaction!.id, _currentUserId!);
        }
        debugPrint('[TransactionRealtimeController] ✅ Deal cancelled');
      } else {
        debugPrint(
          '[TransactionRealtimeController] ❌ cancelDeal returned false',
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
      debugPrint(
        '[TransactionRealtimeController] ❌ Error offering next bidder: $e',
      );
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
      debugPrint(
        '[TransactionRealtimeController] ❌ Error relisting auction: $e',
      );
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
      debugPrint(
        '[TransactionRealtimeController] ❌ Error deleting auction: $e',
      );
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
      debugPrint(
        '[TransactionRealtimeController] ❌ Error offering to bidder: $e',
      );
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update delivery status (Seller) - without photo (legacy)
  Future<bool> updateDeliveryStatus(DeliveryStatus status) async {
    if (_transaction == null || _currentUserId == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.updateDeliveryStatus(
        _transaction!.id,
        _currentUserId!,
        status,
      );

      if (success) {
        await loadTransaction(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update delivery status';
      debugPrint('[TransactionRealtimeController] Error: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update delivery status with photo proof (Seller)
  Future<bool> updateDeliveryStatusWithPhoto(
    DeliveryStatus status,
    File photo,
  ) async {
    if (_transaction == null || _currentUserId == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.updateDeliveryStatusWithPhoto(
        _transaction!.id,
        _currentUserId!,
        status,
        photo,
      );

      if (success) {
        await loadTransaction(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to update delivery: $e';
      debugPrint(
        '[TransactionRealtimeController] Error updating delivery with photo: $e',
      );
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Upload buyer delivery confirmation photo
  Future<bool> uploadBuyerDeliveryPhoto(File photo) async {
    if (_transaction == null || _currentUserId == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.uploadBuyerDeliveryPhoto(
        _transaction!.id,
        photo,
      );

      if (success) {
        await _reloadTransactionData(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to upload photo';
      debugPrint('[TransactionRealtimeController] Error: $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Respond to delivery (Buyer)
  Future<bool> respondToDelivery({
    required bool accepted,
    String? rejectionReason,
    List<File>? rejectionPhotos,
  }) async {
    if (_transaction == null || _currentUserId == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final success = await _dataSource.respondToDelivery(
        transactionId: _transaction!.id,
        buyerId: _currentUserId!,
        accepted: accepted,
        rejectionReason: rejectionReason,
        rejectionPhotos: rejectionPhotos,
      );

      if (success) {
        await loadTransaction(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to submit response';
      debugPrint('[TransactionRealtimeController] Error: $e');
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

  // ============================================================================
  // AGREEMENT FIELDS
  // ============================================================================

  Future<void> _loadAgreementFieldsSafe(String transactionId) async {
    try {
      _agreementFields = await _dataSource.getAgreementFields(transactionId);
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Warning: Failed to load agreement fields: $e',
      );
      _agreementFields = [];
    }
  }

  Future<bool> addAgreementField({
    required String label,
    String value = '',
    String fieldType = 'text',
    String category = 'general',
    String? options,
  }) async {
    if (_transaction == null) return false;
    try {
      final field = await _dataSource.addAgreementField(
        transactionId: _transaction!.id,
        label: label,
        value: value,
        fieldType: fieldType,
        category: category,
        options: options,
      );
      if (field != null) {
        _agreementFields.add(field);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[TransactionRealtimeController] Error adding field: $e');
      return false;
    }
  }

  Future<bool> updateAgreementField(String fieldId, String value) async {
    try {
      final success = await _dataSource.updateAgreementField(fieldId, value);
      if (success) {
        final idx = _agreementFields.indexWhere((f) => f.id == fieldId);
        if (idx != -1) {
          _agreementFields[idx] = _agreementFields[idx].copyWith(value: value);
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      debugPrint('[TransactionRealtimeController] Error updating field: $e');
      return false;
    }
  }

  Future<bool> deleteAgreementField(String fieldId) async {
    try {
      final success = await _dataSource.deleteAgreementField(fieldId);
      if (success) {
        _agreementFields.removeWhere((f) => f.id == fieldId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('[TransactionRealtimeController] Error deleting field: $e');
      return false;
    }
  }

  // ============================================================================
  // LOCK / CONFIRM / FINALIZE
  // ============================================================================

  Future<bool> lockAgreement() async {
    if (_transaction == null || _currentUserId == null) return false;
    _isProcessing = true;
    notifyListeners();
    try {
      final role = getUserRole(_currentUserId!);
      final success = await _dataSource.lockAgreement(_transaction!.id, role);
      if (success) {
        await _reloadTransactionData(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to lock agreement';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> unlockAgreement() async {
    if (_transaction == null || _currentUserId == null) return false;
    _isProcessing = true;
    notifyListeners();
    try {
      final role = getUserRole(_currentUserId!);
      final success = await _dataSource.unlockAgreement(_transaction!.id, role);
      if (success) {
        await _reloadTransactionData(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to unlock agreement';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> confirmAgreement() async {
    if (_transaction == null || _currentUserId == null) return false;
    _isProcessing = true;
    notifyListeners();
    try {
      final role = getUserRole(_currentUserId!);
      final success = await _dataSource.confirmAgreement(
        _transaction!.id,
        role,
      );
      if (success) {
        await _reloadTransactionData(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to confirm agreement';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  Future<bool> withdrawAgreementConfirmation() async {
    if (_transaction == null || _currentUserId == null) return false;
    _isProcessing = true;
    notifyListeners();
    try {
      final role = getUserRole(_currentUserId!);
      final success = await _dataSource.withdrawAgreementConfirmation(
        _transaction!.id,
        role,
      );
      if (success) {
        await _reloadTransactionData(_transaction!.id, _currentUserId!);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to withdraw confirmation';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Toggle installment payment method on/off
  Future<void> toggleInstallment(bool enabled) async {
    if (_transaction == null) return;
    final method = enabled ? 'installment' : 'full_payment';
    try {
      await _dataSource.updatePaymentMethod(_transaction!.id, method);
      _transaction = _transaction!.copyWith(paymentMethod: method);
      notifyListeners();
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeController] Error toggling installment: $e',
      );
    }
  }

  @override
  void dispose() {
    _chatSubscription?.cancel();
    _transactionSubscription?.cancel();
    _subscribedTransactionId = null;
    // Only unsubscribe this controller's detail channels.
    // Do NOT call _dataSource.dispose() — it's a shared singleton
    // and closing its streams kills realtime for the entire app.
    _dataSource.unsubscribeDetailChannels();
    super.dispose();
  }
}
