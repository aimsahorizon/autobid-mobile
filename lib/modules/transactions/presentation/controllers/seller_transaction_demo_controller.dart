import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/transaction_entity.dart';
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

    debugPrint(
      'DEBUG [DemoController]: ========================================',
    );
    debugPrint('DEBUG [DemoController]: Starting demo auto-play');

    try {
      // Step 1: Submit seller form
      debugPrint('DEBUG [DemoController]: Step 1 - Submitting seller form');
      await _submitSellerForm();
      await _delay(3000); // Increased delay to ensure UI updates

      // Step 2: Send chat message
      debugPrint('DEBUG [DemoController]: Step 2 - Sending chat message');
      await _sendChatMessage('Hello! I just submitted my seller form.');
      await _delay(2000);

      // Step 3: Simulate buyer form submission
      debugPrint(
        'DEBUG [DemoController]: Step 3 - Simulating buyer form submission',
      );
      await _submitBuyerForm();
      await _delay(3000); // Increased delay

      // Step 4: Send another message
      debugPrint(
        'DEBUG [DemoController]: Step 4 - Sending confirmation message',
      );
      await _sendChatMessage('All forms are now submitted. Ready to proceed!');
      await _delay(2000);

      // Step 5: Confirm seller form
      debugPrint('DEBUG [DemoController]: Step 5 - Confirming seller form');
      await _confirmSellerForm();
      await _delay(3000); // Increased delay

      // Step 6: Submit to admin
      debugPrint('DEBUG [DemoController]: Step 6 - Submitting to admin');
      await _submitToAdmin();
      await _delay(3000); // Increased delay

      // Step 7: Simulate admin approval
      debugPrint('DEBUG [DemoController]: Step 7 - Simulating admin approval');
      await _simulateAdminApproval();
      await _delay(3000); // Increased delay

      // Step 8: Start delivery - Preparing
      debugPrint('DEBUG [DemoController]: Step 8 - Delivery: Preparing');
      await _updateDelivery(DeliveryStatus.preparing);
      await _delay(3000); // Increased delay

      // Step 9: In Transit
      debugPrint('DEBUG [DemoController]: Step 9 - Delivery: In Transit');
      await _updateDelivery(DeliveryStatus.inTransit);
      await _delay(3000); // Increased delay

      // Step 10: Delivered
      debugPrint('DEBUG [DemoController]: Step 10 - Delivery: Delivered');
      await _updateDelivery(DeliveryStatus.delivered);
      await _delay(3000); // Increased delay

      // Step 11: Completed
      debugPrint('DEBUG [DemoController]: Step 11 - Delivery: Completed');
      await _updateDelivery(DeliveryStatus.completed);
      await _delay(2000);

      _currentStep = 'Demo completed!';
      debugPrint('DEBUG [DemoController]: ✅ Demo completed successfully');
      notifyListeners();
    } catch (e, stackTrace) {
      _currentStep = 'Demo error: $e';
      debugPrint('ERROR [DemoController]: ❌ Demo failed: $e');
      debugPrint('STACK [DemoController]: $stackTrace');
      notifyListeners();
    } finally {
      await _delay(2000);
      _isPlaying = false;
      _currentStep = '';
      debugPrint(
        'DEBUG [DemoController]: ========================================',
      );
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
      preferredDate: DateTime.now().add(const Duration(days: 7)),
      contactNumber: '09171234567',
      additionalNotes: 'All documents ready for transfer',
      paymentMethod: 'Bank Transfer',
      handoverLocation: 'Seller Location - Makati City',
      handoverTimeSlot: 'Afternoon',
      orCrOriginalAvailable: true,
      deedOfSaleReady: true,
      registrationValid: true,
      noLiensEncumbrances: true,
      conditionMatchesListing: true,
      reviewedVehicleCondition: true,
      understoodAuctionTerms: true,
      willArrangeInsurance: true,
      acceptsAsIsCondition: true,
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
      preferredDate: DateTime.now().add(const Duration(days: 7)),
      contactNumber: '09181234567',
      additionalNotes: 'Ready for vehicle pickup',
      paymentMethod: 'Bank Transfer',
      pickupOrDelivery: 'Delivery',
      deliveryAddress: 'Buyer preferred location - QC',
      handoverLocation: 'Buyer preferred location - QC',
      handoverTimeSlot: 'Afternoon',
      reviewedVehicleCondition: true,
      understoodAuctionTerms: true,
      willArrangeInsurance: true,
      acceptsAsIsCondition: true,
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
        preferredDate: transactionController.myForm!.preferredDate,
        contactNumber: transactionController.myForm!.contactNumber,
        additionalNotes: transactionController.myForm!.additionalNotes,
        paymentMethod: transactionController.myForm!.paymentMethod,
        pickupOrDelivery: transactionController.myForm!.pickupOrDelivery,
        deliveryAddress: transactionController.myForm!.deliveryAddress,
        handoverLocation: transactionController.myForm!.handoverLocation,
        handoverTimeSlot: transactionController.myForm!.handoverTimeSlot,
        orCrOriginalAvailable:
            transactionController.myForm!.orCrOriginalAvailable,
        deedOfSaleReady: transactionController.myForm!.deedOfSaleReady,
        releaseOfMortgage: transactionController.myForm!.releaseOfMortgage,
        registrationValid: transactionController.myForm!.registrationValid,
        noLiensEncumbrances: transactionController.myForm!.noLiensEncumbrances,
        conditionMatchesListing:
            transactionController.myForm!.conditionMatchesListing,
        newIssuesDisclosure: transactionController.myForm!.newIssuesDisclosure,
        fuelLevel: transactionController.myForm!.fuelLevel,
        accessoriesIncluded: transactionController.myForm!.accessoriesIncluded,
        reviewedVehicleCondition:
            transactionController.myForm!.reviewedVehicleCondition,
        understoodAuctionTerms:
            transactionController.myForm!.understoodAuctionTerms,
        willArrangeInsurance:
            transactionController.myForm!.willArrangeInsurance,
        acceptsAsIsCondition:
            transactionController.myForm!.acceptsAsIsCondition,
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
      debugPrint(
        'WARNING: Admin approval simulation requires backend interaction.',
      );
      // Removed MockDataSource dependency.
      // Ideally this should call an endpoint or be handled manually in Supabase.
      
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
