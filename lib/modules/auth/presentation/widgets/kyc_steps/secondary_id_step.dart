import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class SecondaryIdStep extends StatefulWidget {
  final KYCRegistrationController controller;
  final VoidCallback? onRequestAiExtraction;

  const SecondaryIdStep({
    super.key,
    required this.controller,
    this.onRequestAiExtraction,
  });

  @override
  State<SecondaryIdStep> createState() => SecondaryIdStepState();
}

class SecondaryIdStepState extends State<SecondaryIdStep> {
  final _idNumberController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

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
      // Strip formatting (dashes, spaces) before saving to controller
      final rawNumber = _idNumberController.text.replaceAll(
        RegExp(r'[-\s]'),
        '',
      );
      widget.controller.setSecondaryIdNumber(rawNumber);
    });
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  // Shows image source picker (camera or gallery)
  void _pickImage(String type) async {
    try {
      // Pick image directly from camera (gallery disabled)
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Set the image in controller
        if (type == 'front') {
          widget.controller.setSecondaryIdFront(imageFile);
        } else {
          widget.controller.setSecondaryIdBack(imageFile);
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

  // Public method to trigger AI extraction (called from parent when Next is pressed)
  void triggerAiExtraction() async {
    // Check if required images exist
    if (widget.controller.secondaryIdFront == null ||
        widget.controller.nationalIdFront == null) {
      return;
    }

    await _showAiExtractionDialog();
  }

  // Shows AI extraction dialog with mock processing
  Future<void> _showAiExtractionDialog() async {
    final useAI = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ColorConstants.primary, Colors.purple],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('AI Auto-fill', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Would you like AI to automatically extract and fill your personal information from your IDs?',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: ColorConstants.success,
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You can review and edit all information in the next steps',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Skip'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: const Text('Use AI'),
          ),
        ],
      ),
    );

    // If user declined or canceled, proceed to next step
    if (useAI != true) {
      if (mounted && widget.onRequestAiExtraction != null) {
        widget.onRequestAiExtraction!();
      }
      return;
    }

    // Show processing dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Extracting information from IDs...'),
                  SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      try {
        // Perform AI extraction
        final extractedData = await widget.controller.extractDataFromIds();

        if (mounted) {
          Navigator.pop(context); // Close processing dialog

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Successfully extracted ${_getExtractedFieldCount(extractedData)} fields from your IDs!',
              ),
              backgroundColor: ColorConstants.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close processing dialog

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to extract data: $e'),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }

      // After AI extraction completes, proceed to next step
      if (mounted && widget.onRequestAiExtraction != null) {
        widget.onRequestAiExtraction!();
      }
    }
  }

  int _getExtractedFieldCount(dynamic data) {
    // Count non-null fields
    int count = 0;
    if (data.firstName != null) count++;
    if (data.middleName != null) count++;
    if (data.lastName != null) count++;
    if (data.dateOfBirth != null) count++;
    if (data.sex != null) count++;
    if (data.address != null) count++;
    if (data.province != null) count++;
    if (data.city != null) count++;
    if (data.barangay != null) count++;
    if (data.zipCode != null) count++;
    return count;
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
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (value) {
              widget.controller.setSecondaryIdType(value);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _idNumberController,
            keyboardType: _getKeyboardType(widget.controller.secondaryIdType),
            inputFormatters: _getInputFormatters(
              widget.controller.secondaryIdType,
            ),
            decoration: InputDecoration(
              labelText: 'ID Number',
              hintText: _getHintText(widget.controller.secondaryIdType),
              helperText: _getHelperText(widget.controller.secondaryIdType),
              prefixIcon: const Icon(Icons.numbers_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'ID number is required';
              }
              return _validateIdFormat(
                value,
                widget.controller.secondaryIdType,
              );
            },
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

  // Get keyboard type based on ID type
  TextInputType _getKeyboardType(String? idType) {
    if (idType == 'Passport') {
      return TextInputType.text; // Alphanumeric
    }
    return TextInputType.number;
  }

  // Get input formatters based on ID type
  List<TextInputFormatter> _getInputFormatters(String? idType) {
    switch (idType) {
      case 'Driver\'s License':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
          LengthLimitingTextInputFormatter(13),
          _DriverLicenseFormatter(),
        ];
      case 'Passport':
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          LengthLimitingTextInputFormatter(9),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return TextEditingValue(
              text: newValue.text.toUpperCase(),
              selection: newValue.selection,
            );
          }),
        ];
      case 'SSS ID':
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
          _SSSIdFormatter(),
        ];
      case 'UMID':
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
          _UMIDFormatter(),
        ];
      case 'PRC ID':
        return [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(7),
        ];
      default:
        return [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9-]')),
          LengthLimitingTextInputFormatter(20),
        ];
    }
  }

  // Get hint text based on ID type
  String _getHintText(String? idType) {
    switch (idType) {
      case 'Driver\'s License':
        return 'N00-00-000000';
      case 'Passport':
        return 'XX0000000';
      case 'SSS ID':
        return '00-0000000-0';
      case 'UMID':
        return '0000-0000000-0';
      case 'PRC ID':
        return '0000000';
      default:
        return 'Enter your ID number';
    }
  }

  // Get helper text based on ID type
  // Note: Formatting is for display only. Numbers are stored without dashes in database.
  String? _getHelperText(String? idType) {
    switch (idType) {
      case 'Driver\'s License':
        return 'Format: N00-00-000000';
      case 'Passport':
        return 'Format: 2 letters + 7 digits';
      case 'SSS ID':
        return 'Format: 00-0000000-0';
      case 'UMID':
        return 'Format: 0000-0000000-0';
      case 'PRC ID':
        return '7-digit PRC number';
      default:
        return null;
    }
  }

  // Validate ID format
  String? _validateIdFormat(String value, String? idType) {
    switch (idType) {
      case 'Driver\'s License':
        final digits = value.replaceAll('-', '');
        if (digits.length != 11) {
          return 'Driver\'s License must be 11 characters';
        }
        break;
      case 'Passport':
        if (value.length != 9) {
          return 'Passport must be 9 characters';
        }
        if (!RegExp(r'^[A-Z]{2}[0-9]{7}$').hasMatch(value)) {
          return 'Invalid passport format (XX0000000)';
        }
        break;
      case 'SSS ID':
        final digits = value.replaceAll('-', '');
        if (digits.length != 10) {
          return 'SSS ID must be 10 digits';
        }
        break;
      case 'UMID':
        final digits = value.replaceAll('-', '');
        if (digits.length != 12) {
          return 'UMID must be 12 digits';
        }
        break;
      case 'PRC ID':
        if (value.length != 7) {
          return 'PRC ID must be 7 digits';
        }
        break;
    }
    return null;
  }
}

/// Formatter for Philippine Driver's License
/// Format: N00-00-000000 (Letter + 2 digits + dash + 2 digits + dash + 6 digits)
class _DriverLicenseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll('-', '').toUpperCase();
    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    for (int i = 0; i < text.length && i < 11; i++) {
      buffer.write(text[i]);
      if (i == 2 || i == 4) {
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

/// Formatter for SSS ID
/// Format: 00-0000000-0 (2 digits + dash + 7 digits + dash + 1 digit)
class _SSSIdFormatter extends TextInputFormatter {
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
    for (int i = 0; i < text.length && i < 10; i++) {
      buffer.write(text[i]);
      if (i == 1 || i == 8) {
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

/// Formatter for UMID
/// Format: 0000-0000000-0 (4 digits + dash + 7 digits + dash + 1 digit)
class _UMIDFormatter extends TextInputFormatter {
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
    for (int i = 0; i < text.length && i < 12; i++) {
      buffer.write(text[i]);
      if (i == 3 || i == 10) {
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
