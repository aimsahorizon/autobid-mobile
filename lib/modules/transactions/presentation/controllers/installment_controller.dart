import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/installment_supabase_datasource.dart';
import '../../domain/entities/installment_plan_entity.dart';
import '../../domain/entities/installment_payment_entity.dart';
import '../../domain/entities/payment_attempt_entity.dart';

/// Controller for managing installment plan state and operations
class InstallmentController extends ChangeNotifier {
  final InstallmentSupabaseDatasource _datasource;

  InstallmentController({InstallmentSupabaseDatasource? datasource})
    : _datasource = datasource ?? InstallmentSupabaseDatasource();

  // State
  InstallmentPlanEntity? _plan;
  List<InstallmentPaymentEntity> _payments = [];
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _errorMessage;

  // Streams
  StreamSubscription? _planSubscription;
  StreamSubscription? _paymentsSubscription;

  // Getters
  InstallmentPlanEntity? get plan => _plan;
  List<InstallmentPaymentEntity> get payments => _payments;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;
  bool get hasPlan => _plan != null;

  /// Next pending payment (for buyer)
  InstallmentPaymentEntity? get nextPendingPayment {
    try {
      return _payments.firstWhere(
        (p) =>
            p.status == InstallmentPaymentStatus.pending ||
            p.status == InstallmentPaymentStatus.rejected,
      );
    } catch (_) {
      return null;
    }
  }

  /// Payments awaiting seller confirmation
  List<InstallmentPaymentEntity> get pendingConfirmation {
    return _payments
        .where((p) => p.status == InstallmentPaymentStatus.submitted)
        .toList();
  }

  /// Confirmed payments
  List<InstallmentPaymentEntity> get confirmedPayments {
    return _payments
        .where((p) => p.status == InstallmentPaymentStatus.confirmed)
        .toList();
  }

  /// Check if all installments are completed
  bool get isCompleted => _plan?.status == InstallmentPlanStatus.completed;

  // =========================================================================
  // Load & Stream
  // =========================================================================

  /// Load installment plan and payments for a transaction
  Future<void> loadInstallmentPlan(String transactionId) async {
    _errorMessage = null;

    // Only show spinner on initial load (no plan yet)
    if (!hasPlan) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final plan = await _datasource.getInstallmentPlan(transactionId);
      _plan = plan;

      if (plan != null) {
        _payments = await _datasource.getPayments(plan.id);
        debugPrint(
          '[InstallmentController] Loaded plan ${plan.id} with ${_payments.length} payments',
        );

        // Recovery: if plan exists but has no payments, regenerate schedule
        if (_payments.isEmpty) {
          debugPrint(
            '[InstallmentController] Plan has 0 payments — regenerating schedule',
          );
          try {
            await _datasource.generatePaymentSchedule(
              planId: plan.id,
              downPayment: plan.downPayment,
              remaining: plan.remainingAmount,
              numInstallments: plan.numInstallments,
              frequency: plan.frequency,
              startDate: plan.startDate,
            );
            _payments = await _datasource.getPayments(plan.id);
            debugPrint(
              '[InstallmentController] Regenerated ${_payments.length} payments',
            );
          } catch (e) {
            debugPrint(
              '[InstallmentController] Failed to regenerate payments: $e',
            );
          }
        }

        _subscribeToRealtime(transactionId, plan.id);
      } else {
        debugPrint(
          '[InstallmentController] No plan found for transaction $transactionId',
        );
      }
    } catch (e) {
      _errorMessage = 'Failed to load installment plan: $e';
      debugPrint('[InstallmentController] $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribe to realtime updates
  void _subscribeToRealtime(String transactionId, String planId) {
    _planSubscription?.cancel();
    _paymentsSubscription?.cancel();

    _planSubscription = _datasource.streamInstallmentPlan(transactionId).listen(
      (plan) {
        if (plan != null) {
          _plan = plan;
          notifyListeners();
        }
      },
      onError: (e) => debugPrint('[InstallmentController] Plan stream error: $e'),
    );

    _paymentsSubscription = _datasource.streamPayments(planId).listen((
      payments,
    ) {
      // Don't overwrite loaded payments with empty stream emission
      if (payments.isEmpty && _payments.isNotEmpty) return;
      debugPrint('[InstallmentController] Stream emitted ${payments.length} payments');
      _payments = payments;
      notifyListeners();
    },
    onError: (e) => debugPrint('[InstallmentController] Payments stream error: $e'),
    );
  }

  // =========================================================================
  // Create Plan
  // =========================================================================

  /// Create a new installment plan
  Future<bool> createPlan({
    required String transactionId,
    required double totalAmount,
    required double downPayment,
    required int numInstallments,
    required String frequency,
    required DateTime startDate,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plan = await _datasource.createInstallmentPlan(
        transactionId: transactionId,
        totalAmount: totalAmount,
        downPayment: downPayment,
        numInstallments: numInstallments,
        frequency: frequency,
        startDate: startDate,
      );

      if (_plan != null) {
        _payments = await _datasource.getPayments(_plan!.id);
        notifyListeners(); // Notify immediately so listeners see payments
        _subscribeToRealtime(transactionId, _plan!.id);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to create plan: $e';
      debugPrint('[InstallmentController] $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Update an existing plan (regenerates schedule)
  Future<bool> updatePlan({
    required String transactionId,
    required double totalAmount,
    required double downPayment,
    required int numInstallments,
    required String frequency,
  }) async {
    if (_plan == null) return false;
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _plan = await _datasource.updateInstallmentPlan(
        planId: _plan!.id,
        transactionId: transactionId,
        totalAmount: totalAmount,
        downPayment: downPayment,
        numInstallments: numInstallments,
        frequency: frequency,
      );
      if (_plan != null) {
        _payments = await _datasource.getPayments(_plan!.id);
        notifyListeners(); // Notify immediately so listeners see payments
      }
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update plan: $e';
      debugPrint('[InstallmentController] $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  // =========================================================================
  // Payment Operations
  // =========================================================================

  /// Buyer submits a payment
  Future<bool> submitPayment({
    required String paymentId,
    required double amount,
    String? proofImagePath,
  }) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _datasource.submitPayment(
        paymentId: paymentId,
        amount: amount,
        proofImagePath: proofImagePath,
      );
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit payment: $e';
      debugPrint('[InstallmentController] $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Seller confirms a payment
  Future<bool> confirmPayment(String paymentId) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _datasource.confirmPayment(paymentId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to confirm payment: $e';
      debugPrint('[InstallmentController] $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Seller rejects a payment
  Future<bool> rejectPayment(String paymentId, String reason) async {
    _isProcessing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _datasource.rejectPayment(paymentId, reason);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject payment: $e';
      debugPrint('[InstallmentController] $e');
      return false;
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  /// Get payment attempt history for a specific payment
  Future<List<PaymentAttemptEntity>> getPaymentAttempts(
    String paymentId,
  ) async {
    try {
      return await _datasource.getPaymentAttempts(paymentId);
    } catch (e) {
      debugPrint('[InstallmentController] Error fetching attempts: $e');
      return [];
    }
  }

  // =========================================================================
  // Cleanup
  // =========================================================================

  @override
  void dispose() {
    _planSubscription?.cancel();
    _paymentsSubscription?.cancel();
    super.dispose();
  }
}
