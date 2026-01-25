import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/buyer_transaction_controller.dart';
import 'fill_form_dialog.dart';

class TransactionMyFormTab extends StatelessWidget {
  final BuyerTransactionController controller;

  const TransactionMyFormTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final form = controller.myForm;

        if (form == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Form Not Submitted',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You need to submit your transaction form to proceed',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => FillFormDialog(
                          controller: controller,
                          transactionId: controller.transaction?.id ?? '',
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Fill Form'),
                  ),
                ],
              ),
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionCard(
                title: 'Personal Information',
                icon: Icons.person,
                children: [
                  _InfoRow(label: 'Full Name', value: form.fullName),
                  _InfoRow(label: 'Email', value: form.email),
                  _InfoRow(label: 'Phone', value: form.phone),
                  _InfoRow(
                      label: 'Address',
                      value: '${form.address}, ${form.city}, ${form.province}'),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'ID Verification',
                icon: Icons.badge,
                children: [
                  _InfoRow(label: 'ID Type', value: form.idType),
                  _InfoRow(label: 'ID Number', value: form.idNumber),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Payment Details',
                icon: Icons.payment,
                children: [
                  _InfoRow(label: 'Payment Method', value: form.paymentMethod),
                  if (form.bankName != null)
                    _InfoRow(label: 'Bank Name', value: form.bankName!),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: form.isConfirmed
                      ? ColorConstants.success.withValues(alpha: 0.1)
                      : ColorConstants.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      form.isConfirmed ? Icons.check_circle : Icons.pending,
                      color: form.isConfirmed
                          ? ColorConstants.success
                          : ColorConstants.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        form.isConfirmed
                            ? 'Form confirmed by seller'
                            : 'Waiting for seller confirmation',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: form.isConfirmed
                              ? ColorConstants.success
                              : ColorConstants.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: ColorConstants.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
