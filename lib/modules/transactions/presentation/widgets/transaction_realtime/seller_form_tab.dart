import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Seller Form Tab - Role-specific form for vehicle sellers
/// Focuses on document preparation, vehicle condition, and handover details
class SellerFormTab extends StatefulWidget {
  final TransactionRealtimeController controller;
  final String userId;

  const SellerFormTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<SellerFormTab> createState() => _SellerFormTabState();
}

class _SellerFormTabState extends State<SellerFormTab> {
  final _formKey = GlobalKey<FormState>();

  // Document Checklist
  bool _orCrOriginalAvailable = false;
  bool _deedOfSaleReady = false;
  bool _releaseOfMortgage = false;
  bool _registrationValid = false;
  bool _noLiensEncumbrances = false;

  // Vehicle Condition
  bool _conditionMatchesListing = false;
  final _newIssuesController = TextEditingController();
  String _fuelLevel = 'Half';
  final _accessoriesController = TextEditingController();

  // Handover Details
  final _handoverLocationController = TextEditingController();
  final _contactNumberController = TextEditingController();
  String _handoverTimeSlot = 'Afternoon';
  DateTime _preferredDate = DateTime.now().add(const Duration(days: 3));
  final _additionalNotesController = TextEditingController();

  static const _fuelLevels = ['Full', '3/4', 'Half', '1/4', 'Empty'];
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
    if (form != null && form.role == FormRole.seller) {
      setState(() {
        _orCrOriginalAvailable = form.orCrOriginalAvailable;
        _deedOfSaleReady = form.deedOfSaleReady;
        _releaseOfMortgage = form.releaseOfMortgage;
        _registrationValid = form.registrationValid;
        _noLiensEncumbrances = form.noLiensEncumbrances;
        _conditionMatchesListing = form.conditionMatchesListing;
        _newIssuesController.text = form.newIssuesDisclosure ?? '';
        _fuelLevel = form.fuelLevel;
        _accessoriesController.text = form.accessoriesIncluded ?? '';
        _handoverLocationController.text = form.handoverLocation;
        _contactNumberController.text = form.contactNumber;
        _handoverTimeSlot = form.handoverTimeSlot;
        _preferredDate = form.preferredDate;
        _additionalNotesController.text = form.additionalNotes;
      });
    }
  }

  @override
  void dispose() {
    _newIssuesController.dispose();
    _accessoriesController.dispose();
    _handoverLocationController.dispose();
    _contactNumberController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  bool get _isDocumentChecklistComplete =>
      _orCrOriginalAvailable &&
      _deedOfSaleReady &&
      _registrationValid &&
      _noLiensEncumbrances &&
      _conditionMatchesListing;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isDocumentChecklistComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required checkboxes'),
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
      role: FormRole.seller,
      status: FormStatus.submitted,
      submittedAt: DateTime.now(),
      preferredDate: _preferredDate,
      contactNumber: _contactNumberController.text,
      additionalNotes: _additionalNotesController.text,
      // Seller fields
      orCrOriginalAvailable: _orCrOriginalAvailable,
      deedOfSaleReady: _deedOfSaleReady,
      releaseOfMortgage: _releaseOfMortgage,
      registrationValid: _registrationValid,
      noLiensEncumbrances: _noLiensEncumbrances,
      conditionMatchesListing: _conditionMatchesListing,
      newIssuesDisclosure: _newIssuesController.text.isEmpty
          ? null
          : _newIssuesController.text,
      fuelLevel: _fuelLevel,
      accessoriesIncluded: _accessoriesController.text.isEmpty
          ? null
          : _accessoriesController.text,
      handoverLocation: _handoverLocationController.text,
      handoverTimeSlot: _handoverTimeSlot,
    );

    final success = await widget.controller.submitForm(form);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller form submitted successfully!'),
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

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Banner
                if (isSubmitted) _buildSubmittedBanner(isDark),

                // Document Preparation Section
                _buildSectionHeader('Document Preparation', Icons.folder_copy),
                const SizedBox(height: 8),
                _buildInfoText(
                  'Confirm all required documents are ready for transfer',
                  isDark,
                ),
                const SizedBox(height: 12),

                _buildRequiredCheckbox(
                  'Original OR/CR available',
                  'You have the original Official Receipt and Certificate of Registration',
                  _orCrOriginalAvailable,
                  (v) => setState(() => _orCrOriginalAvailable = v ?? false),
                  isSubmitted,
                ),
                _buildRequiredCheckbox(
                  'Deed of Absolute Sale prepared',
                  'Legal document for ownership transfer is ready',
                  _deedOfSaleReady,
                  (v) => setState(() => _deedOfSaleReady = v ?? false),
                  isSubmitted,
                ),
                _buildOptionalCheckbox(
                  'Release of Chattel Mortgage (if applicable)',
                  'Required if vehicle was previously financed',
                  _releaseOfMortgage,
                  (v) => setState(() => _releaseOfMortgage = v ?? false),
                  isSubmitted,
                ),
                _buildRequiredCheckbox(
                  'Registration is valid and current',
                  'Vehicle registration has not expired',
                  _registrationValid,
                  (v) => setState(() => _registrationValid = v ?? false),
                  isSubmitted,
                ),
                _buildRequiredCheckbox(
                  'No liens or encumbrances',
                  'Vehicle is free from any legal claims or debts',
                  _noLiensEncumbrances,
                  (v) => setState(() => _noLiensEncumbrances = v ?? false),
                  isSubmitted,
                ),

                const SizedBox(height: 24),

                // Vehicle Condition Section
                _buildSectionHeader('Vehicle Condition', Icons.directions_car),
                const SizedBox(height: 8),
                _buildInfoText('Confirm the vehicle\'s current state', isDark),
                const SizedBox(height: 12),

                _buildRequiredCheckbox(
                  'Condition matches listing description',
                  'No changes to vehicle condition since auction listing',
                  _conditionMatchesListing,
                  (v) => setState(() => _conditionMatchesListing = v ?? false),
                  isSubmitted,
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _newIssuesController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'New Issues to Disclose (if any)',
                    hintText: 'Any problems that occurred since listing',
                    prefixIcon: const Icon(Icons.warning_amber),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _fuelLevel,
                  decoration: InputDecoration(
                    labelText: 'Fuel Level at Handover',
                    prefixIcon: const Icon(Icons.local_gas_station),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: _fuelLevels
                      .map(
                        (level) =>
                            DropdownMenuItem(value: level, child: Text(level)),
                      )
                      .toList(),
                  onChanged: isSubmitted
                      ? null
                      : (v) => setState(() => _fuelLevel = v ?? 'Half'),
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _accessoriesController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Accessories Included',
                    hintText: 'Keys, manual, spare tire, tools, etc.',
                    prefixIcon: const Icon(Icons.inventory_2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                ),

                const SizedBox(height: 24),

                // Handover Details Section
                _buildSectionHeader('Handover Details', Icons.handshake),
                const SizedBox(height: 8),
                _buildInfoText(
                  'Where and when can the buyer pick up the vehicle?',
                  isDark,
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _handoverLocationController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Handover Location *',
                    hintText: 'Complete address for vehicle pickup',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 2,
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _contactNumberController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Contact Number *',
                    hintText: 'For coordination with buyer',
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
                          if (date != null) {
                            setState(() => _preferredDate = date);
                          }
                        },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Preferred Handover Date',
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
                  initialValue: _handoverTimeSlot,
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
                          () => _handoverTimeSlot = v ?? 'Afternoon',
                        ),
                ),

                const SizedBox(height: 12),
                TextFormField(
                  controller: _additionalNotesController,
                  enabled: !isSubmitted,
                  decoration: InputDecoration(
                    labelText: 'Additional Notes',
                    hintText: 'Any other information for the buyer',
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
                      label: const Text('Submit Seller Form'),
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
              'Your seller form has been submitted. Waiting for buyer to review.',
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

  Widget _buildRequiredCheckbox(
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

  Widget _buildOptionalCheckbox(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool?> onChanged,
    bool disabled,
  ) {
    return CheckboxListTile(
      value: value,
      onChanged: disabled ? null : onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: ColorConstants.success,
    );
  }
}
