import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class SelfieWithIdStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const SelfieWithIdStep({super.key, required this.controller});

  @override
  State<SelfieWithIdStep> createState() => _SelfieWithIdStepState();
}

class _SelfieWithIdStepState extends State<SelfieWithIdStep> {
  final ImagePicker _picker = ImagePicker();

  void _pickSelfie() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        widget.controller.setSelfieWithId(imageFile);
        // No AI autofill here - it happens after secondary ID upload
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
            'Selfie with ID',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please take a selfie while holding your National ID',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.brightness == Brightness.dark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          ImagePickerCard(
            label: 'Selfie with National ID',
            hint: 'Hold your ID next to your face',
            imageFile: widget.controller.selfieWithId,
            icon: Icons.face_rounded,
            onTap: _pickSelfie,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: ColorConstants.info,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Selfie Guidelines',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ColorConstants.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildGuideline('Hold your ID next to your face'),
                const SizedBox(height: 8),
                _buildGuideline('Make sure your face is clearly visible'),
                const SizedBox(height: 8),
                _buildGuideline('Ensure the ID text is readable'),
                const SizedBox(height: 8),
                _buildGuideline('Use good lighting'),
                const SizedBox(height: 8),
                _buildGuideline('Remove sunglasses or face coverings'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideline(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.check_circle, color: ColorConstants.info, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: ColorConstants.info),
          ),
        ),
      ],
    );
  }
}
