import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/transaction_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

class BuyerFormTab extends StatelessWidget {
  final TransactionController controller;
  final String userId;

  const BuyerFormTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  Future<void> _confirmForm(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Form'),
        content: const Text(
          'By confirming, you agree to the terms and conditions in the buyer\'s form. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.confirmForm(FormRole.buyer);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Form confirmed successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final buyerForm = controller.otherPartyForm;

        if (buyerForm == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 64,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
                const SizedBox(height: 16),
                Text(
                  'No form submitted yet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ColorConstants.textPrimaryDark
                        : ColorConstants.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Waiting for buyer to submit their form',
                  style: TextStyle(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ],
            ),
          );
        }

        final isConfirmed = buyerForm.status == FormStatus.confirmed;
        final canConfirm =
            buyerForm.status == FormStatus.submitted ||
            buyerForm.status == FormStatus.reviewed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status banner
              if (isConfirmed)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'You have confirmed this form',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ColorConstants.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: ColorConstants.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Review the buyer\'s form carefully before confirming',
                          style: TextStyle(
                            color: ColorConstants.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              _buildSectionTitle('Agreement Details', isDark),
              const SizedBox(height: 12),

              _buildDetailRow(
                'Agreed Price',
                '₱${_formatPrice(controller.transaction?.agreedPrice ?? 0)}',
                isDark,
              ),
              _buildDetailRow(
                'Payment Method',
                buyerForm.paymentMethod,
                isDark,
              ),
              _buildDetailRow(
                'Delivery Date',
                _formatDate(buyerForm.preferredDate),
                isDark,
              ),
              _buildDetailRow(
                'Delivery Location',
                buyerForm.deliveryLocation,
                isDark,
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('Legal Checklist', isDark),
              const SizedBox(height: 12),

              _buildChecklistItem(
                'OR/CR verified and authentic',
                buyerForm.orCrVerified,
                isDark,
              ),
              _buildChecklistItem(
                'Deeds of Sale ready for signing',
                buyerForm.deedsOfSaleReady,
                isDark,
              ),
              _buildChecklistItem(
                'Plate number confirmed with LTO',
                buyerForm.plateNumberConfirmed,
                isDark,
              ),
              _buildChecklistItem(
                'Registration is valid and current',
                buyerForm.registrationValid,
                isDark,
              ),
              _buildChecklistItem(
                'No outstanding loans on vehicle',
                buyerForm.noOutstandingLoans,
                isDark,
              ),
              _buildChecklistItem(
                'Mechanical inspection completed',
                buyerForm.mechanicalInspectionDone,
                isDark,
              ),

              if (buyerForm.additionalNotes.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Additional Terms', isDark),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? ColorConstants.surfaceDark
                        : ColorConstants.backgroundSecondaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(buyerForm.additionalNotes),
                ),
              ],

              const SizedBox(height: 24),
              _buildSectionTitle('Form Status', isDark),
              const SizedBox(height: 12),
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
                    Row(
                      children: [
                        Icon(
                          _getStatusIcon(buyerForm.status),
                          color: _getStatusColor(buyerForm.status),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _getStatusLabel(buyerForm.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(buyerForm.status),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted on ${_formatDate(buyerForm.submittedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),

              if (canConfirm) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.isProcessing
                      ? null
                      : () => _confirmForm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstants.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: controller.isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirm Form'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark
            ? ColorConstants.textPrimaryDark
            : ColorConstants.textPrimaryLight,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
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
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool checked, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.cancel,
            color: checked ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark
                    ? ColorConstants.textPrimaryDark
                    : ColorConstants.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(FormStatus status) {
    switch (status) {
      case FormStatus.draft:
        return Icons.edit_outlined;
      case FormStatus.submitted:
        return Icons.upload_outlined;
      case FormStatus.reviewed:
        return Icons.visibility_outlined;
      case FormStatus.changesRequested:
        return Icons.feedback_outlined;
      case FormStatus.confirmed:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(FormStatus status) {
    switch (status) {
      case FormStatus.draft:
        return Colors.grey;
      case FormStatus.submitted:
        return Colors.blue;
      case FormStatus.reviewed:
        return Colors.orange;
      case FormStatus.changesRequested:
        return Colors.red;
      case FormStatus.confirmed:
        return Colors.green;
    }
  }

  String _getStatusLabel(FormStatus status) {
    switch (status) {
      case FormStatus.draft:
        return 'Draft';
      case FormStatus.submitted:
        return 'Submitted - Awaiting Review';
      case FormStatus.reviewed:
        return 'Reviewed';
      case FormStatus.changesRequested:
        return 'Changes Requested';
      case FormStatus.confirmed:
        return 'Confirmed';
    }
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
