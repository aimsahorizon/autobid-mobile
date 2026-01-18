import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Buyer Form Tab - Role-specific form for vehicle buyers
/// Focuses on payment details, pickup preferences, and acknowledgments
class BuyerFormTab extends StatefulWidget {
  final TransactionRealtimeController controller;
  final String userId;

  const BuyerFormTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<BuyerFormTab> createState() => _BuyerFormTabState();
}

class _BuyerFormTabState extends State<BuyerFormTab> {
  final _formKey = GlobalKey<FormState>();

  // Payment Details
  String _paymentMethod = 'Bank Transfer';
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNumberController = TextEditingController();

  // Pickup/Delivery Preference
  String _pickupOrDelivery = 'Pickup';
  final _deliveryAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 3));
  String _preferredTimeSlot = 'Afternoon';

  // Acknowledgments
  bool _reviewedVehicleCondition = false;
  bool _understoodAuctionTerms = false;
  bool _willArrangeInsurance = false;
  bool _acceptsAsIsCondition = false;

  final _additionalNotesController = TextEditingController();

  static const _paymentMethods = [
    'Bank Transfer',
    'Cash on Pickup',
    'Bank Financing',
    'GCash/Maya',
  ];
  static const _timeSlots = [
    'Morning (8AM-12PM)',
    'Afternoon (12PM-5PM)',
    'Evening (5PM-8PM)',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _populateFromExisting(),
    );
  }

  void _populateFromExisting() {
    final form = widget.controller.myForm;
    if (form != null && form.role == FormRole.buyer) {
      setState(() {
        _paymentMethod = form.paymentMethod;
        _bankNameController.text = form.bankName ?? '';
        _accountNameController.text = form.accountName ?? '';
        _accountNumberController.text = form.accountNumber ?? '';
        _pickupOrDelivery = form.pickupOrDelivery;
        _deliveryAddressController.text = form.deliveryAddress ?? '';
        _contactNumberController.text = form.contactNumber;
        _preferredDate = form.preferredDate;
        _preferredTimeSlot = form.handoverTimeSlot;
        _reviewedVehicleCondition = form.reviewedVehicleCondition;
        _understoodAuctionTerms = form.understoodAuctionTerms;
        _willArrangeInsurance = form.willArrangeInsurance;
        _acceptsAsIsCondition = form.acceptsAsIsCondition;
        _additionalNotesController.text = form.additionalNotes;
      });
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _deliveryAddressController.dispose();
    _contactNumberController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  bool get _areAcknowledgmentsComplete =>
      _reviewedVehicleCondition &&
      _understoodAuctionTerms &&
      _willArrangeInsurance &&
      _acceptsAsIsCondition;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_areAcknowledgmentsComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all acknowledgment checkboxes'),
          backgroundColor: ColorConstants.error,
        ),
      );
      return;
    }

    final transaction = widget.controller.transaction;
    if (transaction == null) return;

    final form = TransactionFormEntity(
      id: widget.controller.myForm?.id ?? '',
      transactionId: transaction.id,
      role: FormRole.buyer,
      status: FormStatus.submitted,
      submittedAt: DateTime.now(),
      preferredDate: _preferredDate,
      contactNumber: _contactNumberController.text,
      additionalNotes: _additionalNotesController.text,
      // Buyer fields
      paymentMethod: _paymentMethod,
      bankName: _bankNameController.text.isEmpty
          ? null
          : _bankNameController.text,
      accountName: _accountNameController.text.isEmpty
          ? null
          : _accountNameController.text,
      accountNumber: _accountNumberController.text.isEmpty
          ? null
          : _accountNumberController.text,
      pickupOrDelivery: _pickupOrDelivery,
      deliveryAddress: _deliveryAddressController.text.isEmpty
          ? null
          : _deliveryAddressController.text,
      handoverTimeSlot: _preferredTimeSlot,
      reviewedVehicleCondition: _reviewedVehicleCondition,
      understoodAuctionTerms: _understoodAuctionTerms,
      willArrangeInsurance: _willArrangeInsurance,
      acceptsAsIsCondition: _acceptsAsIsCondition,
    );

    final success = await widget.controller.submitForm(form);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Buyer form submitted successfully!'),
          backgroundColor: ColorConstants.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final myForm = widget.controller.myForm;
        final isSubmitted = myForm != null && myForm.status != FormStatus.draft;
        final transaction = widget.controller.transaction;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                if (isSubmitted) _buildSubmittedBanner(isDark),

                // Transaction Summary
                if (transaction != null) ...[
                  _buildTransactionSummary(transaction, isDark),
                  const SizedBox(height: 24),
                ],

                // Payment Details Section
                _buildSectionHeader('Payment Details', Icons.payment),
                const SizedBox(height: 8),
                _buildInfoText('How will you complete the payment?', isDark),
                const SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: InputDecoration(
                    labelText: 'Payment Method *',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _paymentMethods
                      .map(
                        (method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitted
                      ? null
                      : (v) => setState(
                          () => _paymentMethod = v ?? 'Bank Transfer',
                        ),
                ),

                // Bank details (only show for Bank Transfer)
                if (_paymentMethod == 'Bank Transfer') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankNameController,
                    enabled: !isSubmitted,
                    decoration: InputDecoration(
                      labelText: 'Bank Name',
                      hintText: 'e.g., BDO, BPI, Metrobank',
                      prefixIcon: const Icon(Icons.account_balance),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountNameController,
                    enabled: !isSubmitted,
                    decoration: InputDecoration(
                      labelText: 'Account Name',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _accountNumberController,
                    enabled: !isSubmitted,
                    decoration: InputDecoration(
                      labelText: 'Account Number',
                      prefixIcon: const Icon(Icons.numbers),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],

                const SizedBox(height: 24),

                // Pickup/Delivery Section
                _buildSectionHeader('Pickup / Delivery', Icons.local_shipping),
                const SizedBox(height: 8),
                _buildInfoText(
                  'How do you want to receive the vehicle?',
                  isDark,
                ),
                const SizedBox(height: 12),

                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'Pickup',
                      label: Text('I\'ll Pick Up'),
                      icon: Icon(Icons.directions_car),
                    ),
                    ButtonSegment(
                      value: 'Delivery',
                      label: Text('Deliver to Me'),
                      icon: Icon(Icons.local_shipping),
                    ),
                  ],
                  selected: {_pickupOrDelivery},
                  onSelectionChanged: isSubmitted
                      ? null
                      : (v) => setState(() => _pickupOrDelivery = v.first),
                ),

                if (_pickupOrDelivery == 'Delivery') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _deliveryAddressController,
                    enabled: !isSubmitted,
                    decoration: InputDecoration(
                      labelText: 'Delivery Address *',
                      hintText: 'Complete address for vehicle delivery',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    maxLines: 2,
                    validator: (v) =>
                        _pickupOrDelivery == 'Delivery' && (v?.isEmpty ?? true)
                        ? 'Required for delivery'
                        : null,
                  ),
                ],

                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Contact Number *',
                    hintText: 'For coordination with seller',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),

                const SizedBox(height: 12),
                InkWell(
                  onTap: isSubmitted
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _preferredDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 30),
                            ),
                          );
                          if (date != null)
                            setState(() => _preferredDate = date);
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Preferred Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${_preferredDate.month}/${_preferredDate.day}/${_preferredDate.year}',
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _preferredTimeSlot,
                  decoration: InputDecoration(
                    labelText: 'Preferred Time',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _timeSlots
                      .map(
                        (slot) => DropdownMenuItem(
                          value: slot.split(' ')[0],
                          child: Text(slot),
                        ),
                      )
                      .toList(),
                  onChanged: isSubmitted
                      ? null
                      : (v) => setState(
                          () => _preferredTimeSlot = v ?? 'Afternoon',
                        ),
                ),

                const SizedBox(height: 24),

                // Acknowledgments Section
                _buildSectionHeader(
                  'Buyer Acknowledgments',
                  Icons.verified_user,
                ),
                const SizedBox(height: 8),
                _buildInfoText(
                  'Please confirm you understand and accept the following',
                  isDark,
                ),
                const SizedBox(height: 12),

                _buildAcknowledgmentCheckbox(
                  'I have reviewed the vehicle condition',
                  'I\'ve carefully reviewed all photos, descriptions, and disclosed issues',
                  _reviewedVehicleCondition,
                  (v) => setState(() => _reviewedVehicleCondition = v ?? false),
                  isSubmitted,
                ),
                _buildAcknowledgmentCheckbox(
                  'I understand the auction terms',
                  'I accept that winning bids are binding commitments',
                  _understoodAuctionTerms,
                  (v) => setState(() => _understoodAuctionTerms = v ?? false),
                  isSubmitted,
                ),
                _buildAcknowledgmentCheckbox(
                  'I will arrange my own insurance',
                  'I understand I need to insure the vehicle after purchase',
                  _willArrangeInsurance,
                  (v) => setState(() => _willArrangeInsurance = v ?? false),
                  isSubmitted,
                ),
                _buildAcknowledgmentCheckbox(
                  'I accept the vehicle "as-is"',
                  'I understand the vehicle is sold as described in the listing',
                  _acceptsAsIsCondition,
                  (v) => setState(() => _acceptsAsIsCondition = v ?? false),
                  isSubmitted,
                ),

                const SizedBox(height: 16),
                TextFormField(
                  controller: _additionalNotesController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes / Questions',
                    hintText:
                        'Any special requests or questions for the seller',
                    prefixIcon: const Icon(Icons.note_add),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 24),

                // Submit Button
                if (!isSubmitted)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.controller.isProcessing
                          ? null
                          : _submitForm,
                      icon: widget.controller.isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Submit Buyer Form'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: ColorConstants.primary,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionSummary(TransactionEntity transaction, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: ColorConstants.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  transaction.carName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Winning Bid:',
                style: TextStyle(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              Text(
                '₱${transaction.agreedPrice.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: ColorConstants.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmittedBanner(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: ColorConstants.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.success),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: ColorConstants.success),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your buyer form has been submitted. Waiting for seller to review.',
              style: TextStyle(color: ColorConstants.success),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorConstants.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInfoText(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: isDark
            ? ColorConstants.textSecondaryDark
            : ColorConstants.textSecondaryLight,
      ),
    );
  }

  Widget _buildAcknowledgmentCheckbox(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
    bool disabled,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: disabled ? null : onChanged,
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ColorConstants.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Required',
              style: TextStyle(fontSize: 10, color: ColorConstants.error),
            ),
          ),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: ColorConstants.success,
    );
  }
}
