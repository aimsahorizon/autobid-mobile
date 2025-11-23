import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';

class PaymentSuccessSheet extends StatelessWidget {
  final double amount;
  final String paymentMethod;
  final VoidCallback onContinue;

  const PaymentSuccessSheet({
    super.key,
    required this.amount,
    required this.paymentMethod,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: ColorConstants.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: ColorConstants.success,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful!',
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your deposit has been received',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.backgroundSecondaryDark
                  : ColorConstants.backgroundSecondaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow('Amount', '₱${amount.toStringAsFixed(2)}', theme, isDark),
                const SizedBox(height: 8),
                _buildDetailRow('Method', paymentMethod, theme, isDark),
                const SizedBox(height: 8),
                _buildDetailRow('Status', 'Confirmed', theme, isDark, isSuccess: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Bidding'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, size: 14, color: ColorConstants.info),
              const SizedBox(width: 6),
              Text(
                'Deposit is refundable if you don\'t win',
                style: theme.textTheme.bodySmall?.copyWith(color: ColorConstants.info),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ThemeData theme,
    bool isDark, {
    bool isSuccess = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isSuccess ? ColorConstants.success : null,
          ),
        ),
      ],
    );
  }
}
