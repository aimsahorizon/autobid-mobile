import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class ProofOfAddressStep extends StatefulWidget {
  final KYCRegistrationController controller;

  const ProofOfAddressStep({super.key, required this.controller});

  @override
  State<ProofOfAddressStep> createState() => _ProofOfAddressStepState();
}

class _ProofOfAddressStepState extends State<ProofOfAddressStep> {
  final ImagePicker _picker = ImagePicker();

  void _pickDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        widget.controller.setProofOfAddress(imageFile);
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
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Proof of Address',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload a document that proves your current address',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 32),
          ImagePickerCard(
            label: 'Upload Proof of Address',
            hint: 'Upload a clear photo of your document',
            imageFile: widget.controller.proofOfAddress,
            icon: Icons.description_outlined,
            onTap: _pickDocument,
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
                      'Acceptable Documents',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: ColorConstants.info,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDocumentType('Utility Bill (Water, Electric, Internet)'),
                const SizedBox(height: 8),
                _buildDocumentType('Bank Statement'),
                const SizedBox(height: 8),
                _buildDocumentType('Government-issued Document'),
                const SizedBox(height: 8),
                _buildDocumentType('Barangay Certificate'),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: ColorConstants.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Document must be issued within the last 3 months and clearly show your name and address',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentType(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_outline,
          color: ColorConstants.info,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: ColorConstants.info),
        ),
      ],
    );
  }
}
