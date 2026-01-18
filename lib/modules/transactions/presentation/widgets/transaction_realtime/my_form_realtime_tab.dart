import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// My Form tab - allows user to submit their transaction form
class MyFormRealtimeTab extends StatefulWidget {
  final TransactionRealtimeController controller;
  final String userId;

  const MyFormRealtimeTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<MyFormRealtimeTab> createState() => _MyFormRealtimeTabState();
}

class _MyFormRealtimeTabState extends State<MyFormRealtimeTab> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  late TextEditingController _priceController;
  late TextEditingController _paymentMethodController;
  late TextEditingController _deliveryLocationController;
  late TextEditingController _contactController;
  late TextEditingController _additionalTermsController;
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));

  // Checklist
  bool _orCrVerified = false;
  bool _deedsOfSaleReady = false;
  bool _plateNumberConfirmed = false;
  bool _registrationValid = false;
  bool _noOutstandingLoans = false;
  bool _mechanicalInspectionDone = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _paymentMethodController = TextEditingController();
    _deliveryLocationController = TextEditingController();
    _contactController = TextEditingController();
    _additionalTermsController = TextEditingController();

    // Pre-populate from existing form if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFromExistingForm();
    });
  }

  void _populateFromExistingForm() {
    final form = widget.controller.myForm;
    final transaction = widget.controller.transaction;

    if (form != null) {
      setState(() {
        _priceController.text = form.agreedPrice.toStringAsFixed(0);
        _paymentMethodController.text = form.paymentMethod;
        _deliveryLocationController.text = form.deliveryLocation;
        _contactController.text = form.contactNumber;
        _additionalTermsController.text = form.additionalNotes;
        _deliveryDate = form.preferredDate;
        _orCrVerified = form.orCrVerified;
        _deedsOfSaleReady = form.deedsOfSaleReady;
        _plateNumberConfirmed = form.plateNumberConfirmed;
        _registrationValid = form.registrationValid;
        _noOutstandingLoans = form.noOutstandingLoans;
        _mechanicalInspectionDone = form.mechanicalInspectionDone;
      });
    } else if (transaction != null) {
      // Pre-fill with transaction's agreed price
      _priceController.text = transaction.agreedPrice.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _paymentMethodController.dispose();
    _deliveryLocationController.dispose();
    _contactController.dispose();
    _additionalTermsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = widget.controller.transaction;
    if (transaction == null) return;

    final role = widget.controller.getUserRole(widget.userId);

    final form = TransactionFormEntity(
      id: widget.controller.myForm?.id ?? '',
      transactionId: transaction.id,
      role: role,
      status: FormStatus.submitted,
      preferredDate: _deliveryDate,
      contactNumber: _contactController.text.trim(),
      additionalNotes: _additionalTermsController.text.trim(),
      paymentMethod: _paymentMethodController.text,
      pickupOrDelivery: 'Delivery',
      deliveryAddress: _deliveryLocationController.text.trim(),
      handoverLocation: _deliveryLocationController.text.trim(),
      handoverTimeSlot: 'Afternoon',
      orCrOriginalAvailable: _orCrVerified,
      deedOfSaleReady: _deedsOfSaleReady,
      releaseOfMortgage: false,
      registrationValid: _registrationValid,
      noLiensEncumbrances: _noOutstandingLoans,
      conditionMatchesListing: _mechanicalInspectionDone,
      reviewedVehicleCondition: true,
      understoodAuctionTerms: true,
      willArrangeInsurance: true,
      acceptsAsIsCondition: true,
      submittedAt: DateTime.now(),
    );

    final success = await widget.controller.submitForm(form);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form submitted successfully!'),
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
        final role = widget.controller.getUserRole(widget.userId);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                if (isSubmitted)
                  Container(
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
                            'Your form has been submitted. Waiting for the other party to review.',
                            style: TextStyle(color: ColorConstants.success),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Agreement Section
                _buildSectionHeader('Agreement Details', Icons.handshake),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _priceController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Agreed Price (₱)',
                    prefixIcon: const Icon(Icons.payments),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _paymentMethodController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: const Icon(Icons.credit_card),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., Bank Transfer, Cash',
                  ),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 12),

                // Delivery Date
                InkWell(
                  onTap: isSubmitted
                      ? null
                      : () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _deliveryDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 90),
                            ),
                          );
                          if (date != null) {
                            setState(() => _deliveryDate = date);
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Delivery Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '${_deliveryDate.month}/${_deliveryDate.day}/${_deliveryDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _deliveryLocationController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Delivery Location',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Address for vehicle delivery',
                  ),
                  maxLines: 2,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),

                const SizedBox(height: 12),

                TextFormField(
                  controller: _contactController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Contact Number',
                    prefixIcon: const Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'e.g., 09XX...',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),

                const SizedBox(height: 24),

                // Legal Checklist Section
                _buildSectionHeader('Legal Checklist', Icons.checklist),
                const SizedBox(height: 12),

                _buildChecklistItem(
                  'OR/CR documents verified',
                  _orCrVerified,
                  (v) => setState(() => _orCrVerified = v ?? false),
                  isSubmitted,
                ),
                _buildChecklistItem(
                  'Deed of Sale ready',
                  _deedsOfSaleReady,
                  (v) => setState(() => _deedsOfSaleReady = v ?? false),
                  isSubmitted,
                ),
                _buildChecklistItem(
                  'Plate number confirmed',
                  _plateNumberConfirmed,
                  (v) => setState(() => _plateNumberConfirmed = v ?? false),
                  isSubmitted,
                ),
                _buildChecklistItem(
                  'Registration valid',
                  _registrationValid,
                  (v) => setState(() => _registrationValid = v ?? false),
                  isSubmitted,
                ),
                _buildChecklistItem(
                  'No outstanding loans',
                  _noOutstandingLoans,
                  (v) => setState(() => _noOutstandingLoans = v ?? false),
                  isSubmitted,
                ),
                _buildChecklistItem(
                  'Mechanical inspection done',
                  _mechanicalInspectionDone,
                  (v) => setState(() => _mechanicalInspectionDone = v ?? false),
                  isSubmitted,
                ),

                const SizedBox(height: 24),

                // Additional Terms
                _buildSectionHeader('Additional Terms', Icons.note_add),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _additionalTermsController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Additional Terms (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    hintText: 'Any special conditions or notes...',
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
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Submit Form'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildChecklistItem(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
    bool isDisabled,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: isDisabled ? null : onChanged,
      title: Text(label),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}
