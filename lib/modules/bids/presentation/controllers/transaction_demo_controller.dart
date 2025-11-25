import 'package:flutter/material.dart';
import '../../domain/entities/buyer_transaction_entity.dart';
import 'buyer_transaction_controller.dart';

/// Demo controller that auto-plays the entire transaction flow
/// Simulates buyer actions: form submission, chat messages, confirmations
class TransactionDemoController extends ChangeNotifier {
  final BuyerTransactionController transactionController;
  bool _isPlaying = false;
  String _currentStep = '';

  TransactionDemoController(this.transactionController);

  bool get isPlaying => _isPlaying;
  String get currentStep => _currentStep;

  /// Starts the demo auto-play sequence
  Future<void> startDemo() async {
    if (_isPlaying) return;

    _isPlaying = true;
    _currentStep = 'Starting demo...';
    notifyListeners();

    try {
      // Step 1: Submit buyer form
      await _submitBuyerForm();
      await _delay(2000);

      // Step 2: Send chat message
      await _sendChatMessage('Hi! I just submitted my form.');
      await _delay(2000);

      // Step 3: Simulate seller form submission
      await _submitSellerForm();
      await _delay(2000);

      // Step 4: Send another message
      await _sendChatMessage('Looking forward to the vehicle pickup!');
      await _delay(2000);

      // Step 5: Confirm buyer form (simulates seller confirming)
      await _confirmBuyerForm();
      await _delay(2000);

      // Step 6: Send final message
      await _sendChatMessage('Thank you! All forms completed.');
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

  Future<void> _submitBuyerForm() async {
    _currentStep = 'Submitting buyer form...';
    notifyListeners();

    final form = BuyerTransactionFormEntity(
      id: 'form_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionController.transaction?.id ?? '',
      role: FormRole.buyer,
      fullName: 'Juan Dela Cruz',
      email: 'juan@email.com',
      phone: '09171234567',
      address: '123 Main St',
      city: 'Quezon City',
      province: 'Metro Manila',
      zipCode: '1100',
      idType: "Driver's License",
      idNumber: '1234-5678-9012',
      paymentMethod: 'Bank Transfer',
      deliveryMethod: 'Pickup',
      agreedToTerms: true,
      submittedAt: DateTime.now(),
      isConfirmed: false,
    );

    await transactionController.submitForm(form);
  }

  Future<void> _submitSellerForm() async {
    _currentStep = 'Simulating seller form submission...';
    notifyListeners();

    final sellerForm = BuyerTransactionFormEntity(
      id: 'seller_form_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionController.transaction?.id ?? '',
      role: FormRole.seller,
      fullName: 'Maria Santos',
      email: 'maria@email.com',
      phone: '09187654321',
      address: '456 Oak Ave',
      city: 'Makati',
      province: 'Metro Manila',
      zipCode: '1200',
      idType: "Driver's License",
      idNumber: '9876-5432-1098',
      paymentMethod: 'Bank Transfer',
      deliveryMethod: 'Pickup',
      bankName: 'BDO',
      accountNumber: '1234567890',
      agreedToTerms: true,
      submittedAt: DateTime.now(),
      isConfirmed: false,
    );

    await transactionController.submitForm(sellerForm);
  }

  Future<void> _sendChatMessage(String message) async {
    _currentStep = 'Sending message: "$message"';
    notifyListeners();
    await transactionController.sendMessage(
      'buyer_current',
      'You',
      message,
    );
  }

  Future<void> _confirmBuyerForm() async {
    _currentStep = 'Seller confirming buyer form...';
    notifyListeners();

    // Update buyer form as confirmed
    if (transactionController.myForm != null) {
      final confirmedForm = BuyerTransactionFormEntity(
        id: transactionController.myForm!.id,
        transactionId: transactionController.myForm!.transactionId,
        role: transactionController.myForm!.role,
        fullName: transactionController.myForm!.fullName,
        email: transactionController.myForm!.email,
        phone: transactionController.myForm!.phone,
        address: transactionController.myForm!.address,
        city: transactionController.myForm!.city,
        province: transactionController.myForm!.province,
        zipCode: transactionController.myForm!.zipCode,
        idType: transactionController.myForm!.idType,
        idNumber: transactionController.myForm!.idNumber,
        paymentMethod: transactionController.myForm!.paymentMethod,
        deliveryMethod: transactionController.myForm!.deliveryMethod,
        agreedToTerms: transactionController.myForm!.agreedToTerms,
        submittedAt: transactionController.myForm!.submittedAt,
        isConfirmed: true,
      );
      await transactionController.submitForm(confirmedForm);
    }
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
