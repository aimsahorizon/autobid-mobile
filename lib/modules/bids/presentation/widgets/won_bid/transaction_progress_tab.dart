import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../controllers/buyer_transaction_controller.dart';
import 'package:autobid_mobile/modules/transactions/domain/entities/buyer_transaction_entity.dart';

class TransactionProgressTab extends StatelessWidget {
  final BuyerTransactionController controller;

  const TransactionProgressTab({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final transaction = controller.transaction;
        final timeline = controller.timeline;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pre-delivery Progress Steps
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
                      isCompleted:
                          transaction?.buyerFormSubmitted == true &&
                          transaction?.sellerFormSubmitted == true,
                      isActive:
                          transaction?.buyerFormSubmitted != true ||
                          transaction?.sellerFormSubmitted != true,
                      icon: Icons.assignment,
                    ),
                    _ProgressConnector(
                      isCompleted:
                          transaction?.buyerFormSubmitted == true &&
                          transaction?.sellerFormSubmitted == true,
                    ),
                    _ProgressStep(
                      title: 'Form Review',
                      subtitle: 'Confirm each other\'s forms',
                      isCompleted:
                          transaction?.buyerConfirmed == true &&
                          transaction?.sellerConfirmed == true,
                      isActive:
                          (transaction?.buyerFormSubmitted == true &&
                              transaction?.sellerFormSubmitted == true) &&
                          (transaction?.buyerConfirmed != true ||
                              transaction?.sellerConfirmed != true),
                      icon: Icons.check_circle,
                    ),
                    _ProgressConnector(
                      isCompleted:
                          transaction?.buyerConfirmed == true &&
                          transaction?.sellerConfirmed == true,
                    ),
                    _ProgressStep(
                      title: 'Admin Approval',
                      subtitle: 'Waiting for admin verification',
                      isCompleted: transaction?.adminApproved == true,
                      isActive:
                          transaction?.readyForAdminReview == true &&
                          transaction?.adminApproved != true,
                      icon: Icons.verified_user,
                    ),
                  ],
                ),
              ),

              // Delivery Progress Section (shown after admin approval)
              if (transaction?.adminApproved == true) ...[
                const SizedBox(height: 24),
                _buildDeliverySection(context, transaction!, isDark),
              ],

              // Timeline
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
                              color: ColorConstants.primary.withValues(
                                alpha: 0.1,
                              ),
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

  Widget _buildDeliverySection(
    BuildContext context,
    BuyerTransactionEntity transaction,
    bool isDark,
  ) {
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
          // Header
          Row(
            children: [
              Icon(Icons.local_shipping, color: ColorConstants.primary),
              const SizedBox(width: 8),
              const Text(
                'Delivery Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getDeliveryStatusColor(
                    transaction.deliveryStatus,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getDeliveryStatusLabel(transaction.deliveryStatus),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getDeliveryStatusColor(transaction.deliveryStatus),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Delivery Steps
          _buildDeliveryStep(
            icon: Icons.build,
            title: 'Preparing',
            subtitle: 'Seller is preparing your vehicle',
            isCompleted:
                transaction.deliveryStatus.index >=
                DeliveryStatus.preparing.index,
            isActive: transaction.deliveryStatus == DeliveryStatus.preparing,
            isDark: isDark,
          ),
          _buildDeliveryConnector(
            transaction.deliveryStatus.index >= DeliveryStatus.inTransit.index,
            isDark,
          ),
          _buildDeliveryStep(
            icon: Icons.local_shipping,
            title: 'On Delivery',
            subtitle: 'Your vehicle is on the way',
            isCompleted:
                transaction.deliveryStatus.index >=
                DeliveryStatus.inTransit.index,
            isActive: transaction.deliveryStatus == DeliveryStatus.inTransit,
            isDark: isDark,
          ),
          _buildDeliveryConnector(
            transaction.deliveryStatus.index >= DeliveryStatus.delivered.index,
            isDark,
          ),
          _buildDeliveryStep(
            icon: Icons.inventory_2,
            title: 'Delivered',
            subtitle: 'Vehicle handed over to you',
            isCompleted:
                transaction.deliveryStatus.index >=
                DeliveryStatus.delivered.index,
            isActive: transaction.deliveryStatus == DeliveryStatus.delivered,
            isDark: isDark,
          ),

          // Buyer Response Section
          if (transaction.deliveryStatus.index >=
              DeliveryStatus.delivered.index) ...[
            const SizedBox(height: 20),
            _buildBuyerResponseSection(context, transaction, isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isDark,
  }) {
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
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Current',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: ColorConstants.primary,
              ),
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

  Widget _buildBuyerResponseSection(
    BuildContext context,
    BuyerTransactionEntity transaction,
    bool isDark,
  ) {
    final acceptanceStatus = transaction.buyerAcceptanceStatus;

    // If already responded, show status
    if (acceptanceStatus != BuyerAcceptanceStatus.pending) {
      return _buildAcceptanceResult(transaction, isDark);
    }

    // Show accept/reject buttons if vehicle is delivered
    if (transaction.deliveryStatus == DeliveryStatus.delivered) {
      return _buildAcceptRejectButtons(context, transaction, isDark);
    }

    return const SizedBox.shrink();
  }

  Widget _buildAcceptanceResult(
    BuyerTransactionEntity transaction,
    bool isDark,
  ) {
    final isAccepted =
        transaction.buyerAcceptanceStatus == BuyerAcceptanceStatus.accepted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAccepted
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isAccepted ? Icons.celebration : Icons.cancel,
                color: isAccepted ? Colors.green : Colors.red,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAccepted
                          ? 'You Accepted the Vehicle! 🎉'
                          : 'You Rejected the Vehicle',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAccepted ? Colors.green[700] : Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAccepted
                          ? 'Transaction completed successfully!'
                          : 'Deal has been cancelled',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isAccepted && transaction.buyerRejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Reason:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.buyerRejectionReason!,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? ColorConstants.textPrimaryDark
                          : ColorConstants.textPrimaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAcceptRejectButtons(
    BuildContext context,
    BuyerTransactionEntity transaction,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.primary.withValues(alpha: 0.1),
            ColorConstants.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: ColorConstants.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Has Been Delivered',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please inspect the vehicle and confirm your acceptance',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Accept Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _showAcceptConfirmation(context, transaction),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.check_circle, size: 20),
                  label: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Reject Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context, transaction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.cancel, size: 20),
                  label: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAcceptConfirmation(
    BuildContext context,
    BuyerTransactionEntity transaction,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Text('Accept Vehicle'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By accepting, you confirm that:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildConfirmationItem('You have received the vehicle'),
            _buildConfirmationItem('The vehicle condition matches the listing'),
            _buildConfirmationItem('All documents have been handed over'),
            _buildConfirmationItem('You agree to complete the transaction'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptVehicle(context, transaction);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Acceptance'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  void _showRejectDialog(
    BuildContext context,
    BuyerTransactionEntity transaction,
  ) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 28),
            const SizedBox(width: 12),
            const Text('Reject Vehicle'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Rejecting will cancel this transaction. Make sure you have valid reasons.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please provide a reason for rejection:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: reasonController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the issues with the vehicle...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a reason';
                  }
                  if (value.trim().length < 20) {
                    return 'Please provide more details (min 20 characters)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                _rejectVehicle(
                  context,
                  transaction,
                  reasonController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Rejection'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptVehicle(
    BuildContext context,
    BuyerTransactionEntity transaction,
  ) async {
    final success = await controller.acceptVehicle(transaction.buyerId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Vehicle accepted! Transaction completed successfully.'
                : controller.errorMessage ?? 'Failed to accept vehicle',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectVehicle(
    BuildContext context,
    BuyerTransactionEntity transaction,
    String reason,
  ) async {
    final success = await controller.rejectVehicle(transaction.buyerId, reason);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Vehicle rejected. Our team will review your case.'
                : controller.errorMessage ?? 'Failed to reject vehicle',
          ),
          backgroundColor: success ? Colors.orange : Colors.red,
        ),
      );
    }
  }

  Color _getDeliveryStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return Colors.grey;
      case DeliveryStatus.preparing:
        return Colors.blue;
      case DeliveryStatus.inTransit:
        return Colors.orange;
      case DeliveryStatus.delivered:
        return ColorConstants.primary;
      case DeliveryStatus.completed:
        return Colors.green;
    }
  }

  String _getDeliveryStatusLabel(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Pending';
      case DeliveryStatus.preparing:
        return 'Preparing';
      case DeliveryStatus.inTransit:
        return 'On Delivery';
      case DeliveryStatus.delivered:
        return 'Delivered';
      case DeliveryStatus.completed:
        return 'Completed';
    }
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

  const _ProgressConnector({required this.isCompleted});

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
