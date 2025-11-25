import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../data/datasources/transaction_mock_datasource.dart';
import 'transaction_controller.dart';

/// Demo controller for seller transaction auto-play
/// Simulates seller actions: form submission, chat, confirmations
class SellerTransactionDemoController extends ChangeNotifier {
  final TransactionController transactionController;
  final String sellerId;
  final String sellerName;

  bool _isPlaying = false;
  String _currentStep = '';

  SellerTransactionDemoController(
    this.transactionController,
    this.sellerId,
    this.sellerName,
  );

  bool get isPlaying => _isPlaying;
  String get currentStep => _currentStep;

  /// Start demo auto-play sequence for seller
  Future<void> startDemo() async {
    if (_isPlaying) return;

    _isPlaying = true;
    _currentStep = 'Starting demo...';
    notifyListeners();

    try {
      // Step 1: Submit seller form
      await _submitSellerForm();
      await _delay(2000);

      // Step 2: Send chat message
      await _sendChatMessage('Hello! I just submitted my seller form.');
      await _delay(2000);

      // Step 3: Simulate buyer form submission
      await _submitBuyerForm();
      await _delay(2000);

      // Step 4: Send another message
      await _sendChatMessage('All forms are now submitted. Ready to proceed!');
      await _delay(2000);

      // Step 5: Confirm seller form
      await _confirmSellerForm();
      await _delay(2000);

      // Step 6: Submit to admin
      await _submitToAdmin();
      await _delay(2000);

      // Step 7: Simulate admin approval
      await _simulateAdminApproval();
      await _delay(2000);

      // Step 8: Start delivery - Preparing
      await _updateDelivery(DeliveryStatus.preparing);
      await _delay(2000);

      // Step 9: In Transit
      await _updateDelivery(DeliveryStatus.inTransit);
      await _delay(2000);

      // Step 10: Delivered
      await _updateDelivery(DeliveryStatus.delivered);
      await _delay(2000);

      // Step 11: Completed
      await _updateDelivery(DeliveryStatus.completed);
      await _delay(1500);

      _currentStep = 'Demo completed!';
      notifyListeners();

    } catch (e) {
      _currentStep = 'Demo error: $e';
      notifyListeners();
    } finally {
      await _delay(1500);
      _isPlaying = false;
      _currentStep = '';
      notifyListeners();
    }
  }

  Future<void> _submitSellerForm() async {
    _currentStep = 'Submitting seller form...';
    notifyListeners();

    final form = TransactionFormEntity(
      id: 'form_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionController.transaction?.id ?? '',
      role: FormRole.seller,
      status: FormStatus.submitted,
      agreedPrice: transactionController.transaction?.agreedPrice ?? 500000,
      paymentMethod: 'Bank Transfer',
      deliveryDate: DateTime.now().add(const Duration(days: 7)),
      deliveryLocation: 'Seller Location - Makati City',
      orCrVerified: true,
      deedsOfSaleReady: true,
      plateNumberConfirmed: true,
      registrationValid: true,
      noOutstandingLoans: true,
      mechanicalInspectionDone: true,
      additionalTerms: 'All documents ready for transfer',
      submittedAt: DateTime.now(),
    );

    await transactionController.submitForm(form);
  }

  Future<void> _submitBuyerForm() async {
    _currentStep = 'Simulating buyer form submission...';
    notifyListeners();

    final buyerForm = TransactionFormEntity(
      id: 'buyer_form_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionController.transaction?.id ?? '',
      role: FormRole.buyer,
      status: FormStatus.submitted,
      agreedPrice: transactionController.transaction?.agreedPrice ?? 500000,
      paymentMethod: 'Bank Transfer',
      deliveryDate: DateTime.now().add(const Duration(days: 7)),
      deliveryLocation: 'Buyer preferred location - QC',
      orCrVerified: true,
      deedsOfSaleReady: true,
      plateNumberConfirmed: true,
      registrationValid: true,
      noOutstandingLoans: true,
      mechanicalInspectionDone: true,
      additionalTerms: 'Ready for vehicle pickup',
      submittedAt: DateTime.now(),
    );

    await transactionController.submitForm(buyerForm);
  }

  Future<void> _sendChatMessage(String message) async {
    _currentStep = 'Sending message: "$message"';
    notifyListeners();
    await transactionController.sendMessage(sellerId, sellerName, message);
  }

  Future<void> _confirmSellerForm() async {
    _currentStep = 'Buyer confirming seller form...';
    notifyListeners();

    // Update seller form status to confirmed
    if (transactionController.myForm != null) {
      final confirmedForm = TransactionFormEntity(
        id: transactionController.myForm!.id,
        transactionId: transactionController.myForm!.transactionId,
        role: transactionController.myForm!.role,
        status: FormStatus.confirmed,
        agreedPrice: transactionController.myForm!.agreedPrice,
        paymentMethod: transactionController.myForm!.paymentMethod,
        deliveryDate: transactionController.myForm!.deliveryDate,
        deliveryLocation: transactionController.myForm!.deliveryLocation,
        orCrVerified: transactionController.myForm!.orCrVerified,
        deedsOfSaleReady: transactionController.myForm!.deedsOfSaleReady,
        plateNumberConfirmed: transactionController.myForm!.plateNumberConfirmed,
        registrationValid: transactionController.myForm!.registrationValid,
        noOutstandingLoans: transactionController.myForm!.noOutstandingLoans,
        mechanicalInspectionDone: transactionController.myForm!.mechanicalInspectionDone,
        additionalTerms: transactionController.myForm!.additionalTerms,
        submittedAt: transactionController.myForm!.submittedAt,
        reviewNotes: 'Confirmed by buyer',
      );
      await transactionController.submitForm(confirmedForm);
    }
  }

  Future<void> _submitToAdmin() async {
    _currentStep = 'Submitting to admin for approval...';
    notifyListeners();
    await transactionController.submitToAdmin();
  }

  Future<void> _simulateAdminApproval() async {
    _currentStep = 'Admin approving transaction...';
    notifyListeners();
    // Simulate admin approval via datasource (demo only)
    // In real scenario, admin would approve via admin panel
    if (transactionController.transaction != null) {
      final datasource = TransactionMockDataSource();
      await datasource.simulateAdminApproval(transactionController.transaction!.id);
      // Reload transaction to reflect changes
      await transactionController.loadTransaction(
        transactionController.transaction!.id,
        transactionController.transaction!.sellerId,
      );
    }
  }

  Future<void> _updateDelivery(DeliveryStatus status) async {
    final statusLabels = {
      DeliveryStatus.preparing: 'Preparing vehicle for delivery...',
      DeliveryStatus.inTransit: 'Vehicle in transit to buyer...',
      DeliveryStatus.delivered: 'Vehicle delivered to buyer...',
      DeliveryStatus.completed: 'Buyer confirmed - Transaction complete!',
    };

    _currentStep = statusLabels[status] ?? 'Updating delivery status...';
    notifyListeners();
    await transactionController.updateDeliveryStatus(status);
  }

  Future<void> _delay(int milliseconds) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  void stopDemo() {
    _isPlaying = false;
    _currentStep = '';
    notifyListeners();
  }

  @override
  void dispose() {
    stopDemo();
    super.dispose();
  }
}
