import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Progress tab - shows transaction timeline and status
class ProgressRealtimeTab extends StatelessWidget {
  final TransactionRealtimeController controller;
  final String? userId;

  const ProgressRealtimeTab({super.key, required this.controller, this.userId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final transaction = controller.transaction;
        final timeline = controller.timeline;

        if (transaction == null) {
          return const Center(child: Text('No transaction data'));
        }

        // Check if current user is the buyer
        final isBuyer =
            userId != null && controller.getUserRole(userId!) == FormRole.buyer;

        // Check if deal can be cancelled (not yet admin approved and not already failed/cancelled)
        final canCancelDeal =
            isBuyer &&
            !transaction.adminApproved &&
            transaction.status != TransactionStatus.cancelled &&
            transaction.status != TransactionStatus.completed;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Summary Card
              _buildSummaryCard(transaction, isDark),

              const SizedBox(height: 24),

              // Progress Steps
              _buildProgressSteps(transaction, isDark),

              // Cancel Deal Button (only for buyers who haven't completed transaction)
              if (canCancelDeal) ...[
                const SizedBox(height: 24),
                _buildCancelDealSection(context, isDark),
              ],

              const SizedBox(height: 24),

              // Timeline
              if (timeline.isNotEmpty) ...[
                const Text(
                  'Activity Timeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...timeline.reversed.map(
                  (event) => _buildTimelineItem(event, isDark),
                ),
              ] else
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 48,
                        color: ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No activity yet',
                        style: TextStyle(
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCancelDealSection(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.error.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: ColorConstants.error,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Cancel Transaction',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'If you can no longer proceed with this purchase, you can cancel the deal. The seller will be notified and may offer to the next highest bidder.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.isProcessing
                  ? null
                  : () => _showCancelDealDialog(context),
              icon: controller.isProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Deal'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorConstants.error,
                side: BorderSide(color: ColorConstants.error),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDealDialog(BuildContext context) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: ColorConstants.error),
            const SizedBox(width: 12),
            const Text('Cancel Deal'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this deal? This action cannot be undone.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Please provide a reason (optional):',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter reason for cancellation...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ColorConstants.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: ColorConstants.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'The seller will be notified and may offer to the next highest bidder.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Deal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Cancel Deal'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      print(
        '[ProgressRealtimeTab] User confirmed cancel. Calling controller...',
      );
      print('[ProgressRealtimeTab] Reason: "${reasonController.text.trim()}"');

      final success = await controller.buyerCancelDeal(
        reason: reasonController.text.trim(),
      );

      print('[ProgressRealtimeTab] buyerCancelDeal returned: $success');

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Deal cancelled successfully'),
              backgroundColor: ColorConstants.success,
            ),
          );
          // Navigate back since the deal is cancelled
          Navigator.pop(context);
        } else {
          print(
            '[ProgressRealtimeTab] ❌ Cancel failed. Error: ${controller.errorMessage}',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(controller.errorMessage ?? 'Failed to cancel deal'),
              backgroundColor: ColorConstants.error,
            ),
          );
        }
      }
    }

    reasonController.dispose();
  }

  Widget _buildSummaryCard(TransactionEntity transaction, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.primary,
            ColorConstants.primary.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  transaction.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            transaction.carName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${transaction.agreedPrice.toStringAsFixed(0)}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSteps(TransactionEntity transaction, bool isDark) {
    final steps = [
      _ProgressStep(
        title: 'Transaction Started',
        isComplete: true,
        icon: Icons.handshake,
      ),
      _ProgressStep(
        title: 'Seller Form Submitted',
        isComplete: transaction.sellerFormSubmitted,
        icon: Icons.description,
      ),
      _ProgressStep(
        title: 'Buyer Form Submitted',
        isComplete: transaction.buyerFormSubmitted,
        icon: Icons.description,
      ),
      _ProgressStep(
        title: 'Forms Confirmed',
        isComplete: transaction.sellerConfirmed && transaction.buyerConfirmed,
        icon: Icons.verified,
      ),
      _ProgressStep(
        title: 'Admin Approved',
        isComplete: transaction.adminApproved,
        icon: Icons.admin_panel_settings,
      ),
      _ProgressStep(
        title: 'Completed',
        isComplete: transaction.status == TransactionStatus.completed,
        icon: Icons.celebration,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progress',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step indicator
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: step.isComplete
                          ? ColorConstants.success
                          : (isDark
                                ? ColorConstants.surfaceDark
                                : ColorConstants.backgroundSecondaryLight),
                      shape: BoxShape.circle,
                      border: step.isComplete
                          ? null
                          : Border.all(
                              color: ColorConstants.textSecondaryLight,
                            ),
                    ),
                    child: Icon(
                      step.isComplete ? Icons.check : step.icon,
                      size: 16,
                      color: step.isComplete
                          ? Colors.white
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: step.isComplete
                          ? ColorConstants.success
                          : ColorConstants.textSecondaryLight.withValues(
                              alpha: 0.3,
                            ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              // Step text
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontWeight: step.isComplete
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: step.isComplete
                          ? (isDark
                                ? ColorConstants.textPrimaryDark
                                : ColorConstants.textPrimaryLight)
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildTimelineItem(TransactionTimelineEntity event, bool isDark) {
    IconData icon;
    Color color;

    switch (event.type) {
      case TimelineEventType.created:
        icon = Icons.add_circle;
        color = ColorConstants.info;
      case TimelineEventType.messageSent:
        icon = Icons.chat;
        color = ColorConstants.primary;
      case TimelineEventType.formSubmitted:
        icon = Icons.description;
        color = ColorConstants.warning;
      case TimelineEventType.formConfirmed:
        icon = Icons.verified;
        color = ColorConstants.success;
      case TimelineEventType.adminApproved:
        icon = Icons.admin_panel_settings;
        color = ColorConstants.success;
      case TimelineEventType.completed:
        icon = Icons.celebration;
        color = ColorConstants.success;
      case TimelineEventType.cancelled:
        icon = Icons.cancel;
        color = ColorConstants.error;
      default:
        icon = Icons.circle;
        color = ColorConstants.textSecondaryLight;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (event.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTimestamp(event.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';

    return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
  }
}

class _ProgressStep {
  final String title;
  final bool isComplete;
  final IconData icon;

  _ProgressStep({
    required this.title,
    required this.isComplete,
    required this.icon,
  });
}
