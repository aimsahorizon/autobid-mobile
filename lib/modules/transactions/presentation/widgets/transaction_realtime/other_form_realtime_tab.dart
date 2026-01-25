import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Other party's form tab - View the counterpart's submitted form
/// Sellers see Buyer's form, Buyers see Seller's form
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

        final transaction = controller.transaction;
        final isConfirmed = otherForm.status == FormStatus.confirmed;
        final adminApproved = transaction?.adminApproved ?? false;

        // Determine if the current user has confirmed the other party's form
        final hasUserConfirmed = role == FormRole.seller
            ? (transaction?.buyerConfirmed ?? false)
            : (transaction?.sellerConfirmed ?? false);

        final canWithdraw = hasUserConfirmed && !adminApproved;
        final canConfirm = !isConfirmed && !hasUserConfirmed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status banner
              _buildStatusBanner(
                adminApproved,
                isConfirmed,
                otherRoleLabel,
                isDark,
              ),
              const SizedBox(height: 16),

              // Display role-specific form content
              if (otherRole == FormRole.seller)
                _buildSellerFormView(otherForm, isDark)
              else
                _buildBuyerFormView(otherForm, isDark),

              const SizedBox(height: 24),

              // Action buttons
              if (canConfirm)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.isProcessing
                        ? null
                        : () =>
                              _confirmForm(context, otherRole, otherRoleLabel),
                    icon: controller.isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text('Confirm $otherRoleLabel\'s Form'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: ColorConstants.success,
                    ),
                  ),
                ),

              if (canWithdraw) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: controller.isProcessing
                        ? null
                        : () => _withdrawConfirmation(
                            context,
                            otherRole,
                            otherRoleLabel,
                          ),
                    icon: const Icon(Icons.undo),
                    label: const Text('Withdraw Confirmation'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: ColorConstants.warning,
                      side: const BorderSide(color: ColorConstants.warning),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can withdraw to request changes before admin approval.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// Build view for Seller's form (seen by Buyer)
  Widget _buildSellerFormView(TransactionFormEntity form, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Document Checklist
        _buildSectionHeader('Document Status', Icons.folder_copy),
        const SizedBox(height: 12),
        _buildChecklistRow(
          'Original OR/CR available',
          form.orCrOriginalAvailable,
          isDark,
        ),
        _buildChecklistRow(
          'Deed of Absolute Sale ready',
          form.deedOfSaleReady,
          isDark,
        ),
        _buildChecklistRow(
          'Release of Mortgage (if applicable)',
          form.releaseOfMortgage,
          isDark,
        ),
        _buildChecklistRow(
          'Registration is valid',
          form.registrationValid,
          isDark,
        ),
        _buildChecklistRow(
          'No liens or encumbrances',
          form.noLiensEncumbrances,
          isDark,
        ),

        const SizedBox(height: 24),

        // Vehicle Condition
        _buildSectionHeader('Vehicle Condition', Icons.directions_car),
        const SizedBox(height: 12),
        _buildChecklistRow(
          'Condition matches listing',
          form.conditionMatchesListing,
          isDark,
        ),
        if (form.newIssuesDisclosure != null &&
            form.newIssuesDisclosure!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildWarningBox(
            'New Issues Disclosed',
            form.newIssuesDisclosure!,
            isDark,
          ),
        ],
        _buildDetailRow('Fuel Level', form.fuelLevel, isDark),
        if (form.accessoriesIncluded != null &&
            form.accessoriesIncluded!.isNotEmpty)
          _buildDetailRow(
            'Accessories Included',
            form.accessoriesIncluded!,
            isDark,
          ),

        const SizedBox(height: 24),

        // Handover Details
        _buildSectionHeader('Handover Details', Icons.handshake),
        const SizedBox(height: 12),
        _buildDetailRow('Location', form.handoverLocation, isDark),
        _buildDetailRow('Contact', form.contactNumber, isDark),
        _buildDetailRow(
          'Preferred Date',
          _formatDate(form.preferredDate),
          isDark,
        ),
        _buildDetailRow('Preferred Time', form.handoverTimeSlot, isDark),

        if (form.additionalNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNotesBox('Seller Notes', form.additionalNotes, isDark),
        ],
      ],
    );
  }

  /// Build view for Buyer's form (seen by Seller)
  Widget _buildBuyerFormView(TransactionFormEntity form, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Details
        _buildSectionHeader('Payment Details', Icons.payment),
        const SizedBox(height: 12),
        _buildDetailRow('Payment Method', form.paymentMethod, isDark),
        if (form.bankName != null && form.bankName!.isNotEmpty)
          _buildDetailRow('Bank', form.bankName!, isDark),
        if (form.accountName != null && form.accountName!.isNotEmpty)
          _buildDetailRow('Account Name', form.accountName!, isDark),
        if (form.accountNumber != null && form.accountNumber!.isNotEmpty)
          _buildDetailRow('Account Number', form.accountNumber!, isDark),

        const SizedBox(height: 24),

        // Pickup/Delivery
        _buildSectionHeader('Pickup / Delivery', Icons.local_shipping),
        const SizedBox(height: 12),
        _buildDetailRow('Preference', form.pickupOrDelivery, isDark),
        if (form.pickupOrDelivery == 'Delivery' && form.deliveryAddress != null)
          _buildDetailRow('Delivery Address', form.deliveryAddress!, isDark),
        _buildDetailRow('Contact', form.contactNumber, isDark),
        _buildDetailRow(
          'Preferred Date',
          _formatDate(form.preferredDate),
          isDark,
        ),
        _buildDetailRow('Preferred Time', form.handoverTimeSlot, isDark),

        const SizedBox(height: 24),

        // Buyer Acknowledgments
        _buildSectionHeader('Buyer Acknowledgments', Icons.verified_user),
        const SizedBox(height: 12),
        _buildChecklistRow(
          'Reviewed vehicle condition',
          form.reviewedVehicleCondition,
          isDark,
        ),
        _buildChecklistRow(
          'Understood auction terms',
          form.understoodAuctionTerms,
          isDark,
        ),
        _buildChecklistRow(
          'Will arrange own insurance',
          form.willArrangeInsurance,
          isDark,
        ),
        _buildChecklistRow(
          'Accepts "as-is" condition',
          form.acceptsAsIsCondition,
          isDark,
        ),

        if (form.additionalNotes.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildNotesBox('Buyer Notes', form.additionalNotes, isDark),
        ],
      ],
    );
  }

  Widget _buildStatusBanner(
    bool adminApproved,
    bool isConfirmed,
    String otherRoleLabel,
    bool isDark,
  ) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String text;

    if (adminApproved) {
      bgColor = ColorConstants.primary.withValues(alpha: 0.1);
      textColor = ColorConstants.primary;
      icon = Icons.admin_panel_settings;
      text = 'Transaction approved by admin - forms locked';
    } else if (isConfirmed) {
      bgColor = ColorConstants.success.withValues(alpha: 0.1);
      textColor = ColorConstants.success;
      icon = Icons.verified;
      text = 'You have confirmed this form';
    } else {
      bgColor = ColorConstants.info.withValues(alpha: 0.1);
      textColor = ColorConstants.info;
      icon = Icons.rate_review;
      text = 'Review the $otherRoleLabel\'s form and confirm if acceptable';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
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

  Widget _buildWarningBox(String title, String content, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: ColorConstants.warning),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber,
                size: 18,
                color: ColorConstants.warning,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ColorConstants.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  Widget _buildNotesBox(String title, String content, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(content),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _confirmForm(
    BuildContext context,
    FormRole otherRole,
    String otherRoleLabel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Form'),
        content: Text(
          'By confirming, you agree to the terms in the $otherRoleLabel\'s form.\n\n'
          'You can withdraw your confirmation later if needed, '
          'as long as the admin has not yet approved the transaction.',
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

  Future<void> _withdrawConfirmation(
    BuildContext context,
    FormRole otherRole,
    String otherRoleLabel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw Confirmation'),
        content: Text(
          'Are you sure you want to withdraw your confirmation of the $otherRoleLabel\'s form?\n\n'
          'This will allow you to request changes or review again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.warning,
            ),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await controller.withdrawConfirmation(otherRole);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmation withdrawn.'),
            backgroundColor: ColorConstants.warning,
          ),
        );
      }
    }
  }
}
