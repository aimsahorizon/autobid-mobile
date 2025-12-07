import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/transaction_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

class MyFormTab extends StatefulWidget {
  final TransactionController controller;
  final String userId;

  const MyFormTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  State<MyFormTab> createState() => _MyFormTabState();
}

class _MyFormTabState extends State<MyFormTab> {
  final _formKey = GlobalKey<FormState>();

  // Form fields
  late TextEditingController _priceController;
  late TextEditingController _locationController;
  late TextEditingController _termsController;

  String _paymentMethod = 'Bank Transfer';
  DateTime _deliveryDate = DateTime.now().add(const Duration(days: 7));

  // Legal checklist
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
    _locationController = TextEditingController();
    _termsController = TextEditingController();

    // Load existing form if available
    final form = widget.controller.myForm;
    if (form != null) {
      _priceController.text = form.agreedPrice.toString();
      _paymentMethod = form.paymentMethod;
      _deliveryDate = form.deliveryDate;
      _locationController.text = form.deliveryLocation;
      _orCrVerified = form.orCrVerified;
      _deedsOfSaleReady = form.deedsOfSaleReady;
      _plateNumberConfirmed = form.plateNumberConfirmed;
      _registrationValid = form.registrationValid;
      _noOutstandingLoans = form.noOutstandingLoans;
      _mechanicalInspectionDone = form.mechanicalInspectionDone;
      _termsController.text = form.additionalTerms;
    } else {
      // Pre-fill with agreed price from transaction
      final transaction = widget.controller.transaction;
      if (transaction != null) {
        _priceController.text = transaction.agreedPrice.toString();
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _locationController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final role = widget.controller.getUserRole(widget.userId);
    final form = TransactionFormEntity(
      id: 'form_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: widget.controller.transaction!.id,
      role: role,
      status: FormStatus.submitted,
      agreedPrice: double.parse(_priceController.text),
      paymentMethod: _paymentMethod,
      deliveryDate: _deliveryDate,
      deliveryLocation: _locationController.text,
      orCrVerified: _orCrVerified,
      deedsOfSaleReady: _deedsOfSaleReady,
      plateNumberConfirmed: _plateNumberConfirmed,
      registrationValid: _registrationValid,
      noOutstandingLoans: _noOutstandingLoans,
      mechanicalInspectionDone: _mechanicalInspectionDone,
      additionalTerms: _termsController.text,
      submittedAt: DateTime.now(),
    );

    final success = await widget.controller.submitForm(form);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form submitted successfully')),
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
        final isSubmitted = myForm?.status == FormStatus.submitted ||
            myForm?.status == FormStatus.reviewed ||
            myForm?.status == FormStatus.confirmed;
        final isConfirmed = myForm?.status == FormStatus.confirmed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isConfirmed)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Your form has been confirmed by the buyer',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isConfirmed) const SizedBox(height: 16),

                _buildSectionTitle('Agreement Details', isDark),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _priceController,
                  label: 'Agreed Price (₱)',
                  enabled: !isSubmitted,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter agreed price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                _buildDropdownField(
                  label: 'Payment Method',
                  value: _paymentMethod,
                  enabled: !isSubmitted,
                  items: ['Bank Transfer', 'Cash', 'Check', 'Installment'],
                  onChanged: (value) {
                    setState(() => _paymentMethod = value!);
                  },
                ),
                const SizedBox(height: 12),

                _buildDateField(
                  label: 'Delivery Date',
                  value: _deliveryDate,
                  enabled: !isSubmitted,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _locationController,
                  label: 'Delivery Location',
                  enabled: !isSubmitted,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter delivery location';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Legal Checklist', isDark),
                const SizedBox(height: 12),

                _buildCheckbox(
                  'OR/CR verified and authentic',
                  _orCrVerified,
                  !isSubmitted,
                  (value) => setState(() => _orCrVerified = value!),
                ),
                _buildCheckbox(
                  'Deeds of Sale ready for signing',
                  _deedsOfSaleReady,
                  !isSubmitted,
                  (value) => setState(() => _deedsOfSaleReady = value!),
                ),
                _buildCheckbox(
                  'Plate number confirmed with LTO',
                  _plateNumberConfirmed,
                  !isSubmitted,
                  (value) => setState(() => _plateNumberConfirmed = value!),
                ),
                _buildCheckbox(
                  'Registration is valid and current',
                  _registrationValid,
                  !isSubmitted,
                  (value) => setState(() => _registrationValid = value!),
                ),
                _buildCheckbox(
                  'No outstanding loans on vehicle',
                  _noOutstandingLoans,
                  !isSubmitted,
                  (value) => setState(() => _noOutstandingLoans = value!),
                ),
                _buildCheckbox(
                  'Mechanical inspection completed',
                  _mechanicalInspectionDone,
                  !isSubmitted,
                  (value) => setState(() => _mechanicalInspectionDone = value!),
                ),

                const SizedBox(height: 24),
                _buildSectionTitle('Additional Terms', isDark),
                const SizedBox(height: 12),

                _buildTextField(
                  controller: _termsController,
                  label: 'Additional Terms (Optional)',
                  enabled: !isSubmitted,
                  maxLines: 4,
                  hint: 'Enter any additional terms or conditions...',
                ),

                const SizedBox(height: 24),
                if (!isSubmitted)
                  ElevatedButton(
                    onPressed: widget.controller.isProcessing ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorConstants.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: widget.controller.isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Form'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark
            ? ColorConstants.textPrimaryDark
            : ColorConstants.textPrimaryLight,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required bool enabled,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) {
        return DropdownMenuItem(value: item, child: Text(item));
      }).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime value,
    required bool enabled,
    required bool isDark,
  }) {
    return InkWell(
      onTap: enabled ? () => _selectDate() : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDate(value)),
            Icon(
              Icons.calendar_today,
              size: 20,
              color: enabled
                  ? ColorConstants.primary
                  : (isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(
    String label,
    bool value,
    bool enabled,
    void Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      enabled: enabled,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: ColorConstants.primary,
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
