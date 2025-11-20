import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class SecondaryIdStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const SecondaryIdStep({
    super.key,
    required this.controller,
  });

  @override
  State<SecondaryIdStep> createState() => _SecondaryIdStepState();
}

class _SecondaryIdStepState extends State<SecondaryIdStep> {
  final _idNumberController = TextEditingController();

  final List<String> _idTypes = [
    'Driver\'s License',
    'Passport',
    'SSS ID',
    'UMID',
    'Postal ID',
    'Voter\'s ID',
    'PRC ID',
    'Senior Citizen ID',
    'PWD ID',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller.secondaryIdNumber != null) {
      _idNumberController.text = widget.controller.secondaryIdNumber!;
    }
    _idNumberController.addListener(() {
      widget.controller.setSecondaryIdNumber(_idNumberController.text);
    });
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _pickImage(String type) async {
    // Mock image picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Image Picker'),
        content: Text('Image picker for $type would open here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Secondary Government ID',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide another valid government-issued ID',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          DropdownButtonFormField<String>(
            initialValue: widget.controller.secondaryIdType,
            decoration: const InputDecoration(
              labelText: 'ID Type',
              hintText: 'Select ID type',
              prefixIcon: Icon(Icons.credit_card_rounded),
            ),
            items: _idTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              widget.controller.setSecondaryIdType(value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _idNumberController,
            decoration: const InputDecoration(
              labelText: 'ID Number',
              hintText: 'Enter your ID number',
              prefixIcon: Icon(Icons.numbers_rounded),
            ),
          ),
          const SizedBox(height: 24),
          ImagePickerCard(
            label: 'Front of Secondary ID',
            hint: 'Clear photo of the front side',
            imageFile: widget.controller.secondaryIdFront,
            icon: Icons.credit_card_rounded,
            onTap: () => _pickImage('front'),
          ),
          const SizedBox(height: 24),
          ImagePickerCard(
            label: 'Back of Secondary ID',
            hint: 'Clear photo of the back side',
            imageFile: widget.controller.secondaryIdBack,
            icon: Icons.credit_card_rounded,
            onTap: () => _pickImage('back'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.warning.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.verified_user_outlined,
                  color: ColorConstants.warning,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This ID must be different from your National ID and should be a valid government-issued identification',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
