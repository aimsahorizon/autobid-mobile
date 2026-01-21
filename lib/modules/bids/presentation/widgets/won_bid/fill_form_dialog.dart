import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/buyer_transaction_entity.dart';
import '../../controllers/buyer_transaction_controller.dart';

class FillFormDialog extends StatefulWidget {
  final BuyerTransactionController controller;
  final String transactionId;

  const FillFormDialog({
    super.key,
    required this.controller,
    required this.transactionId,
  });

  @override
  State<FillFormDialog> createState() => _FillFormDialogState();
}

class _FillFormDialogState extends State<FillFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Juan Dela Cruz');
  final _emailController = TextEditingController(text: 'juan@email.com');
  final _phoneController = TextEditingController(text: '09171234567');
  final _addressController = TextEditingController(text: '123 Main St');
  final _cityController = TextEditingController(text: 'Quezon City');
  final _provinceController = TextEditingController(text: 'Metro Manila');
  final _zipController = TextEditingController(text: '1100');
  final _idNumberController = TextEditingController(text: '1234-5678-9012');

  String _idType = 'Driver\'s License';
  String _paymentMethod = 'Bank Transfer';
  final String _deliveryMethod = 'Pickup';
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to terms')),
      );
      return;
    }

    final form = BuyerTransactionFormEntity(
      id: 'form_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: widget.transactionId,
      role: FormRole.buyer,
      fullName: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      city: _cityController.text,
      province: _provinceController.text,
      zipCode: _zipController.text,
      idType: _idType,
      idNumber: _idNumberController.text,
      paymentMethod: _paymentMethod,
      deliveryMethod: _deliveryMethod,
      agreedToTerms: _agreedToTerms,
      submittedAt: DateTime.now(),
      isConfirmed: false,
    );

    widget.controller.submitForm(form).then((success) {
      if (success && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form submitted successfully'),
            backgroundColor: ColorConstants.success,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? ColorConstants.surfaceDark : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment, color: ColorConstants.primary),
                  const SizedBox(width: 12),
                  Text(
                    'Fill Transaction Form',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(labelText: 'Address'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(labelText: 'City'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _provinceController,
                            decoration: const InputDecoration(labelText: 'Province'),
                            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _idType,
                      decoration: const InputDecoration(labelText: 'ID Type'),
                      items: ['Driver\'s License', 'Passport', 'National ID']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _idType = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idNumberController,
                      decoration: const InputDecoration(labelText: 'ID Number'),
                      validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                      items: ['Bank Transfer', 'Cash', 'Financing']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _paymentMethod = v!),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _agreedToTerms,
                      onChanged: (v) => setState(() => _agreedToTerms = v!),
                      title: const Text('I agree to terms and conditions'),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitForm,
                  child: const Text('Submit Form'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
