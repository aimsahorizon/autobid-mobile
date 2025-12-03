import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class NationalIdStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const NationalIdStep({
    super.key,
    required this.controller,
  });

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
      widget.controller.setNationalIdNumber(_idNumberController.text);
    });
  }

  @override
  void dispose() {
    _idNumberController.dispose();
    super.dispose();
  }

  void _pickImage(String type) async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: source,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
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
            decoration: const InputDecoration(
              labelText: 'National ID Number',
              hintText: 'Enter your 12-digit National ID number',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
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
