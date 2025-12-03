import 'package:flutter/material.dart';
import '../../../../../app/core/config/supabase_config.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/listing_draft_controller.dart';

class Step9Summary extends StatelessWidget {
  final ListingDraftController controller;
  final VoidCallback onSubmitSuccess;

  const Step9Summary({
    super.key,
    required this.controller,
    required this.onSubmitSuccess,
  });

  Future<void> _submitListing(BuildContext context) async {
    // Get current user ID from Supabase
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';

    final success = await controller.submitListing(userId);
    if (success) {
      onSubmitSuccess();
    } else if (context.mounted) {
      final errorMessage = controller.errorMessage ?? 'Please complete all required fields';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final draft = controller.currentDraft!;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Step 9: Review & Submit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? ColorConstants.surfaceDark
                    : ColorConstants.backgroundSecondaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completion Status',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? ColorConstants.textPrimaryDark
                          : ColorConstants.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: draft.completionPercentage / 100,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${draft.completionPercentage.toStringAsFixed(0)}% Complete',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: draft.completionPercentage >= 100
                          ? Colors.green
                          : ColorConstants.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(8, (index) {
              final step = index + 1;
              final isComplete = draft.isStepComplete(step);
              return _buildStepSummary(step, isComplete, isDark);
            }),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: controller.isSubmitting || draft.completionPercentage < 100
                  ? null
                  : () => _submitListing(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: controller.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Listing',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStepSummary(int step, bool isComplete, bool isDark) {
    final stepTitles = [
      'Basic Information',
      'Mechanical Specification',
      'Dimensions & Capacity',
      'Exterior Details',
      'Condition & History',
      'Documentation & Location',
      'Photos',
      'Final Details & Pricing',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isComplete ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isComplete ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Step $step: ${stepTitles[step - 1]}',
              style: TextStyle(
                fontWeight: isComplete ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          TextButton(
            onPressed: () => controller.goToStep(step),
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}
