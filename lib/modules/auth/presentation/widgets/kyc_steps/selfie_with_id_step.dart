import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/kyc_registration_controller.dart';
import '../image_picker_card.dart';

class SelfieWithIdStep extends StatefulWidget {
  final KYCRegistrationController controller;
  final VoidCallback onAIAutoFillComplete;

  const SelfieWithIdStep({
    super.key,
    required this.controller,
    required this.onAIAutoFillComplete,
  });

  @override
  State<SelfieWithIdStep> createState() => _SelfieWithIdStepState();
}

class _SelfieWithIdStepState extends State<SelfieWithIdStep> {
  void _pickSelfie() async {
    // Mock image picker
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selfie Capture'),
        content: const Text('Camera would open here for selfie'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // After capturing selfie, show AI auto-fill dialog
              _showAIAutoFillDialog();
            },
            child: const Text('Capture'),
          ),
        ],
      ),
    );
  }

  void _showAIAutoFillDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: ColorConstants.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'AI Auto-fill',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We\'ve successfully extracted information from your ID. Would you like us to automatically fill in your personal information?',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ColorConstants.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: ColorConstants.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can review and edit this information in the next step',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ColorConstants.success,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.controller.setAiAutoFillAccepted(false);
              Navigator.pop(context);
            },
            child: const Text('Skip'),
          ),
          FilledButton(
            onPressed: () async {
              widget.controller.setAiAutoFillAccepted(true);
              Navigator.pop(context);

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Processing your ID...'),
                        ],
                      ),
                    ),
                  ),
                ),
              );

              await widget.controller.performAIAutoFill();

              if (mounted) {
                Navigator.pop(context);
                widget.onAIAutoFillComplete();
              }
            },
            child: const Text('Auto-fill'),
          ),
        ],
      ),
    );
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
          child: Icon(
            Icons.check_circle,
            color: ColorConstants.info,
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ColorConstants.info,
                ),
          ),
        ),
      ],
    );
  }
}
