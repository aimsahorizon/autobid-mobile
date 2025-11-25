import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../controllers/buyer_transaction_controller.dart';
import '../../../domain/entities/buyer_transaction_entity.dart';

class TransactionProgressTab extends StatelessWidget {
  final BuyerTransactionController controller;

  const TransactionProgressTab({
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
        final timeline = controller.timeline;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                  children: [
                    _ProgressStep(
                      title: 'Discussion',
                      subtitle: 'Communicate with seller',
                      isCompleted: true,
                      isActive: false,
                      icon: Icons.chat_bubble,
                    ),
                    _ProgressConnector(isCompleted: true),
                    _ProgressStep(
                      title: 'Form Submission',
                      subtitle: 'Both parties submit forms',
                      isCompleted: controller.transaction?.buyerFormSubmitted ==
                              true &&
                          controller.transaction?.sellerFormSubmitted == true,
                      isActive: controller.transaction?.buyerFormSubmitted !=
                              true ||
                          controller.transaction?.sellerFormSubmitted != true,
                      icon: Icons.assignment,
                    ),
                    _ProgressConnector(
                      isCompleted:
                          controller.transaction?.buyerFormSubmitted == true &&
                              controller.transaction?.sellerFormSubmitted == true,
                    ),
                    _ProgressStep(
                      title: 'Form Review',
                      subtitle: 'Confirm each other\'s forms',
                      isCompleted:
                          controller.transaction?.buyerConfirmed == true &&
                              controller.transaction?.sellerConfirmed == true,
                      isActive: (controller.transaction?.buyerFormSubmitted ==
                                  true &&
                              controller.transaction?.sellerFormSubmitted == true) &&
                          (controller.transaction?.buyerConfirmed != true ||
                              controller.transaction?.sellerConfirmed != true),
                      icon: Icons.check_circle,
                    ),
                    _ProgressConnector(
                      isCompleted:
                          controller.transaction?.buyerConfirmed == true &&
                              controller.transaction?.sellerConfirmed == true,
                    ),
                    _ProgressStep(
                      title: 'Admin Approval',
                      subtitle: 'Waiting for admin verification',
                      isCompleted: controller.transaction?.adminApproved == true,
                      isActive: controller.transaction?.readyForAdminReview ==
                              true &&
                          controller.transaction?.adminApproved != true,
                      icon: Icons.verified_user,
                    ),
                    _ProgressConnector(
                      isCompleted: controller.transaction?.adminApproved == true,
                    ),
                    _ProgressStep(
                      title: 'Completed',
                      subtitle: 'Transaction finalized',
                      isCompleted: controller.transaction?.status ==
                          TransactionStatus.completed,
                      isActive: false,
                      icon: Icons.celebration,
                    ),
                  ],
                ),
              ),
              if (timeline.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Timeline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
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
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: timeline.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final event = timeline[index];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ColorConstants.primary
                                  .withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getEventIcon(event.type),
                              size: 20,
                              color: ColorConstants.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event.title,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  event.description,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: isDark
                                        ? ColorConstants.textSecondaryDark
                                        : ColorConstants.textSecondaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTimestamp(event.timestamp),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
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
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  IconData _getEventIcon(TimelineEventType type) {
    switch (type) {
      case TimelineEventType.created:
        return Icons.star;
      case TimelineEventType.formSubmitted:
        return Icons.assignment_turned_in;
      case TimelineEventType.formConfirmed:
        return Icons.check_circle;
      case TimelineEventType.adminReview:
        return Icons.admin_panel_settings;
      case TimelineEventType.adminApproved:
        return Icons.verified;
      case TimelineEventType.completed:
        return Icons.celebration;
      case TimelineEventType.cancelled:
        return Icons.cancel;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

class _ProgressStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final bool isActive;
  final IconData icon;

  const _ProgressStep({
    required this.title,
    required this.subtitle,
    required this.isCompleted,
    required this.isActive,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isCompleted
                ? ColorConstants.success
                : (isActive
                    ? ColorConstants.primary
                    : (isDark
                        ? ColorConstants.backgroundDark
                        : ColorConstants.backgroundSecondaryLight)),
            shape: BoxShape.circle,
            border: !isCompleted && !isActive
                ? Border.all(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                    width: 2,
                  )
                : null,
          ),
          child: Icon(
            isCompleted ? Icons.check : icon,
            color: isCompleted || isActive
                ? Colors.white
                : (isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted || isActive
                      ? null
                      : (isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight),
                ),
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
      ],
    );
  }
}

class _ProgressConnector extends StatelessWidget {
  final bool isCompleted;

  const _ProgressConnector({
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 23, top: 4, bottom: 4),
      width: 2,
      height: 24,
      color: isCompleted
          ? ColorConstants.success
          : (isDark
              ? ColorConstants.textSecondaryDark.withValues(alpha: 0.3)
              : ColorConstants.textSecondaryLight.withValues(alpha: 0.3)),
    );
  }
}
