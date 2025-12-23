import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../../domain/entities/payment_entity.dart';

class PaymentMethodSheet extends StatelessWidget {
  final double amount;
  final Function(PaymentMethod) onSelect;

  const PaymentMethodSheet({
    super.key,
    required this.amount,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Select Payment Method',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 18, color: ColorConstants.primary),
                const SizedBox(width: 8),
                Text(
                  'Deposit: ₱${amount.toStringAsFixed(0)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: ColorConstants.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _PaymentMethodTile(
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFF007DFE),
            title: 'GCash',
            subtitle: 'Pay with your GCash wallet',
            onTap: () => onSelect(PaymentMethod.gcash),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFF52B44B),
            title: 'Maya',
            subtitle: 'Pay with your Maya wallet',
            onTap: () => onSelect(PaymentMethod.maya),
          ),
          const SizedBox(height: 12),
          _PaymentMethodTile(
            icon: Icons.credit_card,
            iconColor: ColorConstants.primary,
            title: 'Credit/Debit Card',
            subtitle: 'Visa, Mastercard accepted',
            onTap: () => onSelect(PaymentMethod.card),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 14, color: ColorConstants.textSecondaryLight),
              const SizedBox(width: 6),
              Text(
                'Secured by PayMongo',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PaymentMethodTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? ColorConstants.backgroundSecondaryDark
                : ColorConstants.backgroundSecondaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
