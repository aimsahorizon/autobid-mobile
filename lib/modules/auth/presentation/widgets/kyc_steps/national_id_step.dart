import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class NationalIdStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const NationalIdStep({super.key, required this.controller});

  @override
  State<NationalIdStep> createState() => _NationalIdStepState();
}

class _NationalIdStepState extends State<NationalIdStep> {
  final _idNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.controller.nationalIdNumber != null) {
      _idNumberController.text = widget.controller.nationalIdNumber!;
    }
    _idNumberController.addListener(() {
      // Strip formatting (dashes) before saving to controller
      final rawNumber = _idNumberController.text.replaceAll('-', '');
      widget.controller.setNationalIdNumber(rawNumber);
    });
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _pickImage(String type) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        if (type == 'front') {
          widget.controller.setNationalIdFront(imageFile);
        } else {
          widget.controller.setNationalIdBack(imageFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Philippine National ID',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please provide your Philippine National ID information',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          TextFormField(
            controller: _idNumberController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(12),
              _NationalIdFormatter(),
            ],
            decoration: const InputDecoration(
              labelText: 'Philippine National ID (PhilSys ID)',
              hintText: 'XXXX-XXXX-XXXX',
              helperText: '12-digit PhilSys ID number',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'National ID number is required';
              }
              final digitsOnly = value.replaceAll('-', '');
              if (digitsOnly.length != 12) {
                return 'National ID must be 12 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          ImagePickerCard(
            label: 'Front of National ID',
            hint: 'Clear photo of the front side',
            imageFile: widget.controller.nationalIdFront,
            icon: Icons.credit_card_rounded,
            onTap: () => _pickImage('front'),
          ),
          const SizedBox(height: 24),
          ImagePickerCard(
            label: 'Back of National ID',
            hint: 'Clear photo of the back side',
            imageFile: widget.controller.nationalIdBack,
            icon: Icons.credit_card_rounded,
            onTap: () => _pickImage('back'),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: ColorConstants.info.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: ColorConstants.info,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make sure the ID is clearly visible and all text is readable',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.info,
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

/// Formatter for Philippine National ID (PhilSys ID)
/// Format: XXXX-XXXX-XXXX (12 digits with dashes)
/// Note: Formatted for display, but stored without dashes in database
class _NationalIdFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '');
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final nonZeroIndex = i + 1;
      if (nonZeroIndex % 4 == 0 && nonZeroIndex != text.length) {
        buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
