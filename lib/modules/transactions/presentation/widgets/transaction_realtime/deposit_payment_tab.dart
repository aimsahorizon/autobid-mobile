import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/browse/presentation/pages/deposit_payment_page.dart';
import '../../controllers/transaction_realtime_controller.dart';

/// Gate widget that requires the buyer to pay a deposit
/// before accessing transaction tabs (Chat, Agreement, Progress).
class DepositPaymentTab extends StatelessWidget {
  final TransactionRealtimeController controller;
  final String userId;

  const DepositPaymentTab({
    super.key,
    required this.controller,
    required this.userId,
  });

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final transaction = controller.transaction;
    final depositAmount = controller.depositAmount;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lock icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorConstants.warning.withValues(alpha: 0.2),
                    ColorConstants.warning.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                size: 40,
                color: ColorConstants.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Deposit Required',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You must pay a refundable deposit before you can proceed with this transaction.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            if (transaction != null)
              Text(
                transaction.carName,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 24),

            // Deposit amount badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 20,
                    color: ColorConstants.primary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₱${_formatNumber(depositAmount)} Deposit',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: ColorConstants.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Pay Deposit button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _navigateToPayment(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.payment_rounded),
                label: const Text(
                  'Pay Deposit',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Info text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: ColorConstants.info),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Fully refundable if the transaction is cancelled',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ColorConstants.info,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToPayment(BuildContext context) async {
    final transaction = controller.transaction;
    if (transaction == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => DepositPaymentPage(
          auctionId: transaction.listingId,
          userId: userId,
          depositAmount: controller.depositAmount,
          onSuccess: () {
            controller.refreshDepositStatus();
          },
        ),
      ),
    );

    if (result == true && context.mounted) {
      // Refresh deposit status
      await controller.refreshDepositStatus();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Deposit paid! You can now proceed with the transaction.',
              ),
              backgroundColor: ColorConstants.success,
            ),
          );
      }
    }
  }
}
