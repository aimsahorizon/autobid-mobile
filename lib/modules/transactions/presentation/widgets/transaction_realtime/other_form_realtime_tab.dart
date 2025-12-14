import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Other party's form tab - view and confirm the other party's form
class OtherFormRealtimeTab extends StatelessWidget {
  final TransactionRealtimeController controller;
  final String userId;

  const OtherFormRealtimeTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final otherForm = controller.otherPartyForm;
        final role = controller.getUserRole(userId);
        final otherRole = role == FormRole.seller
            ? FormRole.buyer
            : FormRole.seller;
        final otherRoleLabel = otherRole == FormRole.seller
            ? 'Seller'
            : 'Buyer';

        if (otherForm == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.hourglass_empty,
                  size: 64,
                  color: ColorConstants.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'Waiting for $otherRoleLabel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The $otherRoleLabel has not submitted their form yet.',
                  style: TextStyle(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final isConfirmed = otherForm.status == FormStatus.confirmed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? ColorConstants.success.withValues(alpha: 0.1)
                      : ColorConstants.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isConfirmed
                        ? ColorConstants.success
                        : ColorConstants.info,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isConfirmed ? Icons.verified : Icons.rate_review,
                      color: isConfirmed
                          ? ColorConstants.success
                          : ColorConstants.info,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isConfirmed
                            ? 'You have confirmed this form'
                            : 'Review and confirm the $otherRoleLabel\'s form',
                        style: TextStyle(
                          color: isConfirmed
                              ? ColorConstants.success
                              : ColorConstants.info,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Details
              _buildSectionHeader('Agreement Details', Icons.handshake),
              const SizedBox(height: 12),

              _buildDetailRow(
                'Agreed Price',
                '₱${otherForm.agreedPrice.toStringAsFixed(0)}',
                isDark,
              ),
              _buildDetailRow(
                'Payment Method',
                otherForm.paymentMethod,
                isDark,
              ),
              _buildDetailRow(
                'Delivery Date',
                '${otherForm.deliveryDate.month}/${otherForm.deliveryDate.day}/${otherForm.deliveryDate.year}',
                isDark,
              ),
              _buildDetailRow(
                'Delivery Location',
                otherForm.deliveryLocation,
                isDark,
              ),

              const SizedBox(height: 24),

              _buildSectionHeader('Legal Checklist', Icons.checklist),
              const SizedBox(height: 12),

              _buildChecklistRow(
                'OR/CR documents verified',
                otherForm.orCrVerified,
                isDark,
              ),
              _buildChecklistRow(
                'Deed of Sale ready',
                otherForm.deedsOfSaleReady,
                isDark,
              ),
              _buildChecklistRow(
                'Plate number confirmed',
                otherForm.plateNumberConfirmed,
                isDark,
              ),
              _buildChecklistRow(
                'Registration valid',
                otherForm.registrationValid,
                isDark,
              ),
              _buildChecklistRow(
                'No outstanding loans',
                otherForm.noOutstandingLoans,
                isDark,
              ),
              _buildChecklistRow(
                'Mechanical inspection done',
                otherForm.mechanicalInspectionDone,
                isDark,
              ),

              if (otherForm.additionalTerms.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionHeader('Additional Terms', Icons.note),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorConstants.surfaceDark
                        : ColorConstants.backgroundSecondaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(otherForm.additionalTerms),
                ),
              ],

              const SizedBox(height: 24),

              // Confirm Button
              if (!isConfirmed)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isProcessing
                        ? null
                        : () => _confirmForm(context, otherRole),
                    icon: controller.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text('Confirm $otherRoleLabel Form'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: ColorConstants.success,
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmForm(BuildContext context, FormRole otherRole) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Form'),
        content: const Text(
          'By confirming, you agree to the terms in this form. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.confirmForm(otherRole);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form confirmed successfully!'),
            backgroundColor: ColorConstants.success,
          ),
        );
      }
    }
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ColorConstants.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistRow(String label, bool checked, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.cancel,
            size: 20,
            color: checked ? ColorConstants.success : ColorConstants.error,
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
