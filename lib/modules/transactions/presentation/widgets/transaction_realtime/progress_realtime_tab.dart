import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Progress tab - shows transaction timeline and status
class ProgressRealtimeTab extends StatelessWidget {
  final TransactionRealtimeController controller;

  const ProgressRealtimeTab({super.key, required this.controller});

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
