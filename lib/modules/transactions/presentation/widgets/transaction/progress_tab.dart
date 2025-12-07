import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/transaction_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

class ProgressTab extends StatelessWidget {
  final TransactionController controller;

  const ProgressTab({super.key, required this.controller});

  Future<void> _submitToAdmin(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit to Admin'),
        content: const Text(
          'Once submitted, forms cannot be modified. Admin will review and approve the transaction. Continue?',
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await controller.submitToAdmin();
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Submitted to admin for approval')),
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
        final transaction = controller.transaction;
        final timeline = controller.timeline;

        if (transaction == null) {
          return const Center(child: Text('No transaction data'));
        }

        final canSubmitToAdmin =
            transaction.readyForAdminReview &&
            transaction.status == TransactionStatus.formReview;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Current status card
              Container(
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
                      children: [
                        const Icon(Icons.track_changes, color: Colors.white),
                        const SizedBox(width: 12),
                        const Text(
                          'Current Status',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      transaction.status.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getStatusDescription(transaction.status),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Progress checklist
              const SizedBox(height: 24),
              _buildProgressChecklist(transaction, isDark),

              // Submit to admin button
              if (canSubmitToAdmin) ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: controller.isProcessing
                      ? null
                      : () => _submitToAdmin(context),
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
                      : const Text('Submit to Admin for Approval'),
                ),
              ],

              // Delivery tracker (only shown after admin approval)
              if (transaction.adminApproved) ...[
                const SizedBox(height: 24),
                _buildDeliveryTracker(context, transaction, isDark),
              ],

              // Timeline
              if (timeline.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Transaction Timeline',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? ColorConstants.textPrimaryDark
                        : ColorConstants.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTimeline(timeline, isDark),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDeliveryTracker(
    BuildContext context,
    TransactionEntity transaction,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Delivery Progress',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? ColorConstants.textPrimaryDark
                : ColorConstants.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? ColorConstants.surfaceDark
                : ColorConstants.backgroundSecondaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildDeliveryStep(
                'Preparing',
                'Vehicle being prepared for handover',
                transaction.deliveryStatus.index >=
                    DeliveryStatus.preparing.index,
                transaction.deliveryStatus == DeliveryStatus.preparing,
                Icons.build,
                isDark,
              ),
              _buildDeliveryConnector(
                transaction.deliveryStatus.index >=
                    DeliveryStatus.inTransit.index,
                isDark,
              ),
              _buildDeliveryStep(
                'In Transit',
                'Vehicle being transported to buyer',
                transaction.deliveryStatus.index >=
                    DeliveryStatus.inTransit.index,
                transaction.deliveryStatus == DeliveryStatus.inTransit,
                Icons.local_shipping,
                isDark,
              ),
              _buildDeliveryConnector(
                transaction.deliveryStatus.index >=
                    DeliveryStatus.delivered.index,
                isDark,
              ),
              _buildDeliveryStep(
                'Delivered',
                'Vehicle handed over to buyer',
                transaction.deliveryStatus.index >=
                    DeliveryStatus.delivered.index,
                transaction.deliveryStatus == DeliveryStatus.delivered,
                Icons.check_circle,
                isDark,
              ),
              _buildDeliveryConnector(
                transaction.deliveryStatus == DeliveryStatus.completed,
                isDark,
              ),
              _buildDeliveryStep(
                'Completed',
                'Buyer confirmed receipt',
                transaction.deliveryStatus == DeliveryStatus.completed,
                false,
                Icons.celebration,
                isDark,
              ),
            ],
          ),
        ),
        if (transaction.deliveryStatus != DeliveryStatus.completed) ...[
          const SizedBox(height: 16),
          _buildDeliveryActionButton(context, transaction),
        ],
      ],
    );
  }

  Widget _buildDeliveryStep(
    String title,
    String subtitle,
    bool isCompleted,
    bool isActive,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? ColorConstants.success
                : (isActive
                      ? ColorConstants.primary
                      : (isDark
                            ? ColorConstants.backgroundDark
                            : Colors.grey[200])),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted || isActive
                ? Colors.white
                : (isDark ? Colors.grey[600] : Colors.grey[400]),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive
                      ? (isDark
                            ? ColorConstants.textPrimaryDark
                            : ColorConstants.textPrimaryLight)
                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
              ),
              Text(
                subtitle,
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
      ],
    );
  }

  Widget _buildDeliveryConnector(bool isCompleted, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 19, top: 4, bottom: 4),
      width: 2,
      height: 20,
      color: isCompleted
          ? ColorConstants.success
          : (isDark ? Colors.grey[700] : Colors.grey[300]),
    );
  }

  Widget _buildDeliveryActionButton(
    BuildContext context,
    TransactionEntity transaction,
  ) {
    DeliveryStatus? nextStatus;
    String buttonText = '';

    switch (transaction.deliveryStatus) {
      case DeliveryStatus.pending:
        nextStatus = DeliveryStatus.preparing;
        buttonText = 'Start Preparing Vehicle';
        break;
      case DeliveryStatus.preparing:
        nextStatus = DeliveryStatus.inTransit;
        buttonText = 'Mark as In Transit';
        break;
      case DeliveryStatus.inTransit:
        nextStatus = DeliveryStatus.delivered;
        buttonText = 'Mark as Delivered';
        break;
      case DeliveryStatus.delivered:
        nextStatus = DeliveryStatus.completed;
        buttonText = 'Complete Transaction';
        break;
      case DeliveryStatus.completed:
        break;
    }

    if (nextStatus == null) return const SizedBox.shrink();

    return ElevatedButton.icon(
      onPressed: controller.isProcessing
          ? null
          : () async {
              final success = await controller.updateDeliveryStatus(
                nextStatus!,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Updated to: ${_getDeliveryStatusLabel(nextStatus)}',
                    ),
                  ),
                );
              }
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: controller.isProcessing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.arrow_forward),
      label: Text(buttonText),
    );
  }

  String _getDeliveryStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.preparing:
        return 'Preparing';
      case DeliveryStatus.inTransit:
        return 'In Transit';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.completed:
        return 'Completed';
    }
  }

  Widget _buildProgressChecklist(TransactionEntity transaction, bool isDark) {
    return Container(
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
            'Progress Checklist',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? ColorConstants.textPrimaryDark
                  : ColorConstants.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildChecklistItem(
            'Seller form submitted',
            transaction.sellerFormSubmitted,
            isDark,
          ),
          _buildChecklistItem(
            'Buyer form submitted',
            transaction.buyerFormSubmitted,
            isDark,
          ),
          _buildChecklistItem(
            'Seller confirmed buyer form',
            transaction.sellerConfirmed,
            isDark,
          ),
          _buildChecklistItem(
            'Buyer confirmed seller form',
            transaction.buyerConfirmed,
            isDark,
          ),
          _buildChecklistItem(
            'Submitted to admin',
            transaction.status == TransactionStatus.pendingApproval ||
                transaction.status == TransactionStatus.approved ||
                transaction.status == TransactionStatus.ongoing ||
                transaction.status == TransactionStatus.completed,
            isDark,
          ),
          _buildChecklistItem(
            'Admin approved',
            transaction.adminApproved,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool completed, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed
                  ? Colors.green
                  : (isDark
                        ? ColorConstants.surfaceLight
                        : ColorConstants.backgroundSecondaryLight),
              border: completed
                  ? null
                  : Border.all(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
            ),
            child: completed
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: completed
                    ? (isDark
                          ? ColorConstants.textPrimaryDark
                          : ColorConstants.textPrimaryLight)
                    : (isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight),
                fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(List<TransactionTimelineEntity> timeline, bool isDark) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: timeline.length,
      itemBuilder: (context, index) {
        final event = timeline[index];
        final isLast = index == timeline.length - 1;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _getTimelineEventColor(
                        event.type,
                      ).withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _getTimelineEventIcon(event.type),
                      size: 16,
                      color: _getTimelineEventColor(event.type),
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: isDark
                            ? ColorConstants.surfaceLight
                            : ColorConstants.backgroundSecondaryLight,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (event.actorName != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              event.actorName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? ColorConstants.textSecondaryDark
                                    : ColorConstants.textSecondaryLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimestamp(event.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getTimelineEventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.created:
        return Icons.add_circle_outline;
      case TimelineEventType.formSubmitted:
        return Icons.upload_outlined;
      case TimelineEventType.formConfirmed:
        return Icons.check_circle_outline;
      case TimelineEventType.adminReview:
        return Icons.rate_review_outlined;
      case TimelineEventType.adminApproved:
        return Icons.verified_outlined;
      case TimelineEventType.depositRefunded:
        return Icons.account_balance_wallet_outlined;
      case TimelineEventType.transactionStarted:
        return Icons.play_circle_outline;
      case TimelineEventType.completed:
        return Icons.task_alt;
      case TimelineEventType.cancelled:
        return Icons.cancel_outlined;
      case TimelineEventType.disputed:
        return Icons.warning_outlined;
    }
  }

  Color _getTimelineEventColor(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.created:
        return Colors.blue;
      case TimelineEventType.formSubmitted:
      case TimelineEventType.formConfirmed:
        return ColorConstants.primary;
      case TimelineEventType.adminReview:
        return Colors.orange;
      case TimelineEventType.adminApproved:
      case TimelineEventType.depositRefunded:
      case TimelineEventType.transactionStarted:
      case TimelineEventType.completed:
        return Colors.green;
      case TimelineEventType.cancelled:
      case TimelineEventType.disputed:
        return Colors.red;
    }
  }

  String _getStatusDescription(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.discussion:
        return 'Discussing pre-transaction details with the buyer';
      case TransactionStatus.formReview:
        return 'Both parties reviewing submitted forms';
      case TransactionStatus.pendingApproval:
        return 'Waiting for admin approval';
      case TransactionStatus.approved:
        return 'Admin approved - deposit will be refunded/credited';
      case TransactionStatus.ongoing:
        return 'Transaction in progress';
      case TransactionStatus.completed:
        return 'Transaction completed successfully';
      case TransactionStatus.cancelled:
        return 'Transaction cancelled';
      case TransactionStatus.disputed:
        return 'Issue raised - under review';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
