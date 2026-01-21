import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/usecases/get_transaction_usecases.dart';
import '../../domain/usecases/manage_transaction_usecases.dart';

/// Controller for managing transaction state and actions
/// Handles chat, forms, timeline, and transaction lifecycle
class TransactionController extends ChangeNotifier {
  final GetTransactionUseCase _getTransactionUseCase;
  final GetChatMessagesUseCase _getChatMessagesUseCase;
  final GetTransactionFormUseCase _getTransactionFormUseCase;
  final GetTimelineUseCase _getTimelineUseCase;
  final SendMessageUseCase _sendMessageUseCase;
  final SubmitFormUseCase _submitFormUseCase;
  final ConfirmFormUseCase _confirmFormUseCase;
  final SubmitToAdminUseCase _submitToAdminUseCase;
  final UpdateDeliveryStatusUseCase _updateDeliveryStatusUseCase;
  final AcceptVehicleUseCase _acceptVehicleUseCase;
  final RejectVehicleUseCase _rejectVehicleUseCase;

  TransactionController({
    required GetTransactionUseCase getTransactionUseCase,
    required GetChatMessagesUseCase getChatMessagesUseCase,
    required GetTransactionFormUseCase getTransactionFormUseCase,
    required GetTimelineUseCase getTimelineUseCase,
    required SendMessageUseCase sendMessageUseCase,
    required SubmitFormUseCase submitFormUseCase,
    required ConfirmFormUseCase confirmFormUseCase,
    required SubmitToAdminUseCase submitToAdminUseCase,
    required UpdateDeliveryStatusUseCase updateDeliveryStatusUseCase,
    required AcceptVehicleUseCase acceptVehicleUseCase,
    required RejectVehicleUseCase rejectVehicleUseCase,
  }) : _getTransactionUseCase = getTransactionUseCase,
       _getChatMessagesUseCase = getChatMessagesUseCase,
       _getTransactionFormUseCase = getTransactionFormUseCase,
       _getTimelineUseCase = getTimelineUseCase,
       _sendMessageUseCase = sendMessageUseCase,
       _submitFormUseCase = submitFormUseCase,
       _confirmFormUseCase = confirmFormUseCase,
       _submitToAdminUseCase = submitToAdminUseCase,
       _updateDeliveryStatusUseCase = updateDeliveryStatusUseCase,
       _acceptVehicleUseCase = acceptVehicleUseCase,
       _rejectVehicleUseCase = rejectVehicleUseCase;

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
      final result = await _getTransactionUseCase.call(transactionId);
      
      await result.fold(
        (failure) async {
          _errorMessage = failure.message;
        },
        (transaction) async {
          _transaction = transaction;
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
        }
      );
    } catch (e) {
      _errorMessage = 'Failed to load transaction: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadChatMessages(String transactionId) async {
    final result = await _getChatMessagesUseCase.call(transactionId);
    result.fold(
      (failure) => null,
      (messages) => _chatMessages = messages,
    );
  }

  Future<void> _loadMyForm(String transactionId, FormRole role) async {
    final result = await _getTransactionFormUseCase.call(transactionId, role);
    result.fold(
      (failure) => null,
      (form) => _myForm = form,
    );
  }

  Future<void> _loadOtherPartyForm(String transactionId, FormRole role) async {
    final result = await _getTransactionFormUseCase.call(transactionId, role);
    result.fold(
      (failure) => null,
      (form) => _otherPartyForm = form,
    );
  }

  Future<void> _loadTimeline(String transactionId) async {
    final result = await _getTimelineUseCase.call(transactionId);
    result.fold(
      (failure) => null,
      (timeline) => _timeline = timeline,
    );
  }

  /// Send chat message
  Future<void> sendMessage(String userId, String userName, String message) async {
    if (_transaction == null || message.trim().isEmpty) return;

    _isProcessing = true;
    notifyListeners();

    try {
      final result = await _sendMessageUseCase.call(
        _transaction!.id,
        userId,
        userName,
        message,
      );
      
      result.fold(
        (failure) => _errorMessage = failure.message,
        (success) {
          if (success) _loadChatMessages(_transaction!.id);
        }
      );
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
      final result = await _submitFormUseCase.call(form);
      return await result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) async {
          if (success) {
            await loadTransaction(
              _transaction!.id,
              form.role == FormRole.seller ? _transaction!.sellerId : _transaction!.buyerId,
            );
          }
          return success;
        }
      );
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
      final result = await _confirmFormUseCase.call(_transaction!.id, otherPartyRole);
      return await result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) async {
          if (success) {
            final userId = otherPartyRole == FormRole.buyer ? _transaction!.sellerId : _transaction!.buyerId;
            await loadTransaction(_transaction!.id, userId);
          }
          return success;
        }
      );
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
    if (_transaction == null || !_transaction!.readyForAdminReview) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final result = await _submitToAdminUseCase.call(_transaction!.id);
      return await result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) async {
          if (success) {
            await loadTransaction(_transaction!.id, _transaction!.sellerId);
          }
          return success;
        }
      );
    } catch (e) {
      _errorMessage = 'Failed to submit to admin';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update delivery status (seller only)
  Future<bool> updateDeliveryStatus(DeliveryStatus status) async {
    if (_transaction == null) return false;

    _isProcessing = true;
    notifyListeners();

    try {
      final result = await _updateDeliveryStatusUseCase.call(
        _transaction!.id,
        _transaction!.sellerId,
        status,
      );
      return await result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) async {
          if (success) {
            await loadTransaction(_transaction!.id, _transaction!.sellerId);
          }
          return success;
        }
      );
    } catch (e) {
      _errorMessage = 'Failed to update delivery status';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Buyer accepts the vehicle
  Future<bool> acceptVehicle(String buyerId) async {
    if (_transaction == null) return false;
    if (!_transaction!.canBuyerRespond) {
      _errorMessage = 'Cannot accept at this stage';
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final result = await _acceptVehicleUseCase.call(_transaction!.id, buyerId);
      return await result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) async {
          if (success) {
            await loadTransaction(_transaction!.id, _transaction!.sellerId);
          }
          return success;
        }
      );
    } catch (e) {
      _errorMessage = 'Failed to accept vehicle';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Buyer rejects the vehicle
  Future<bool> rejectVehicle(String buyerId, String reason) async {
    if (_transaction == null) return false;
    if (!_transaction!.canBuyerRespond) {
      _errorMessage = 'Cannot reject at this stage';
      return false;
    }

    _isProcessing = true;
    notifyListeners();

    try {
      final result = await _rejectVehicleUseCase.call(_transaction!.id, buyerId, reason);
      return await result.fold(
        (failure) {
          _errorMessage = failure.message;
          return false;
        },
        (success) async {
          if (success) {
            await loadTransaction(_transaction!.id, _transaction!.sellerId);
          }
          return success;
        }
      );
    } catch (e) {
      _errorMessage = 'Failed to reject vehicle';
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}