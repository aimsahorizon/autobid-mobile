import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../domain/entities/installment_plan_entity.dart';
import '../../../domain/entities/installment_payment_entity.dart';
import '../../../domain/entities/payment_attempt_entity.dart';
import '../../controllers/installment_controller.dart';
import '../../controllers/transaction_realtime_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Installment Tracker Tab — shows payment plan progress, payment history,
/// and action buttons for buyers (submit payment) and sellers (confirm/reject).
class InstallmentTrackerTab extends StatefulWidget {
  final InstallmentController controller;
  final TransactionRealtimeController? transactionController;
  final String transactionId;
  final String userId;
  final FormRole userRole;
  final bool bothConfirmed;

  const InstallmentTrackerTab({
    super.key,
    required this.controller,
    this.transactionController,
    required this.transactionId,
    required this.userId,
    required this.userRole,
    this.bothConfirmed = false,
  });

  @override
  State<InstallmentTrackerTab> createState() => _InstallmentTrackerTabState();
}

class _InstallmentTrackerTabState extends State<InstallmentTrackerTab> {
  @override
  void initState() {
    super.initState();
    if (!widget.controller.hasPlan) {
      widget.controller.loadInstallmentPlan(widget.transactionId);
    }
  }

  bool get isBuyer => widget.userRole == FormRole.buyer;
  bool get isSeller => widget.userRole == FormRole.seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.controller.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: ColorConstants.error,
                ),
                const SizedBox(height: 12),
                Text(widget.controller.errorMessage ?? 'An error occurred'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => widget.controller.loadInstallmentPlan(
                    widget.transactionId,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final plan = widget.controller.plan;
        if (plan == null) {
          return _buildNoPlanView(isDark);
        }

        return _buildPlanView(plan, isDark);
      },
    );
  }

  // =========================================================================
  // No Plan View — directs user to Agreement tab
  // =========================================================================

  Widget _buildNoPlanView(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 64,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Gives Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up a gives plan in the Agreement tab.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Plan View — Progress + Payments
  // =========================================================================

  Widget _buildPlanView(InstallmentPlanEntity plan, bool isDark) {
    final payments = widget.controller.payments;

    return Column(
      children: [
        // Progress header
        _buildProgressHeader(plan, isDark),

        // Payments list
        Expanded(
          child: payments.isEmpty
              ? const Center(child: Text('No gives scheduled'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(payments[index], isDark);
                  },
                ),
        ),

        // Buyer FAB area — available once plan exists
        if (isBuyer && widget.controller.nextPendingPayment != null)
          _buildBuyerActionBar(isDark),

        // Review section — visible when installments completed AND delivery completed
        if (widget.controller.isCompleted &&
            widget.transactionController != null &&
            widget.transactionController!.transaction?.deliveryStatus ==
                DeliveryStatus.completed)
          _buildInstallmentReviewSection(isDark),
      ],
    );
  }

  // =========================================================================
  // Progress Header
  // =========================================================================

  Widget _buildProgressHeader(InstallmentPlanEntity plan, bool isDark) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Gives Progress',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: plan.status == InstallmentPlanStatus.completed
                      ? Colors.green.withValues(alpha: 0.15)
                      : Colors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  plan.status.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: plan.status == InstallmentPlanStatus.completed
                        ? Colors.green
                        : Colors.blue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: plan.progress,
              minHeight: 12,
              backgroundColor: isDark
                  ? Colors.grey.shade800
                  : Colors.grey.shade200,
              color: plan.isFullyPaid ? Colors.green : ColorConstants.primary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₱${plan.totalPaid.toStringAsFixed(0)} paid',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '₱${plan.totalAmount.toStringAsFixed(0)} total',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(plan.progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
              Text(
                '₱${plan.remainingAmount.toStringAsFixed(0)} remaining',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInfoChip(
                Icons.calendar_today,
                '${plan.numInstallments} gives',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.repeat,
                _frequencyDisplayLabel(plan.frequency),
                isDark,
              ),
              if (plan.downPayment > 0) ...[
                const SizedBox(width: 8),
                _buildInfoChip(
                  Icons.money,
                  '₱${plan.downPayment.toStringAsFixed(0)} down',
                  isDark,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  // =========================================================================
  // Payment Card
  // =========================================================================

  Widget _buildPaymentCard(InstallmentPaymentEntity payment, bool isDark) {
    final statusColor = _paymentStatusColor(payment.status);
    final isOverdue = payment.isOverdue;
    final isDownPayment = payment.paymentNumber == 0;
    final displayLabel = isDownPayment ? 'DP' : '#${payment.paymentNumber}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Payment number badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      displayLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Amount and due date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₱${payment.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        payment.hasNoDueDate
                            ? 'Due: Upon buyer\'s discretion'
                            : 'Due: ${_formatDate(payment.dueDate)}${isOverdue ? ' (OVERDUE)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue
                              ? ColorConstants.error
                              : isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                          fontWeight: isOverdue ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    payment.status.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            // Rejection reason — only show when currently rejected
            if (payment.status == InstallmentPaymentStatus.rejected &&
                payment.rejectionReason != null &&
                payment.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 14, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Rejected: ${payment.rejectionReason}',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Proof image preview
            if (payment.proofImageUrl != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showProofImage(payment.proofImageUrl!),
                    child: Row(
                      children: [
                        Icon(Icons.image, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'View proof of payment',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // History link for non-pending payments
                  if (payment.status != InstallmentPaymentStatus.pending)
                    GestureDetector(
                      onTap: () => _showAttemptHistory(payment),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.history, size: 14, color: Colors.grey),
                          const SizedBox(width: 2),
                          Text(
                            'History',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ] else if (payment.status != InstallmentPaymentStatus.pending) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _showAttemptHistory(payment),
                child: Row(
                  children: [
                    Icon(Icons.history, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'View submission history',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Seller actions for submitted payments
            if (isSeller && payment.canSellerAct) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.controller.isProcessing
                          ? null
                          : () => _showRejectDialog(payment),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.controller.isProcessing
                          ? null
                          : () => _confirmPayment(payment),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Confirm'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Buyer Action Bar
  // =========================================================================

  Widget _buildBuyerActionBar(bool isDark) {
    final next = widget.controller.nextPendingPayment!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 0.5),
        ),
      ),
      child: SafeArea(
        child: FilledButton.icon(
          onPressed: widget.controller.isProcessing
              ? null
              : () => _showSubmitPaymentSheet(next),
          icon: const Icon(Icons.upload),
          label: Text(
            next.paymentNumber == 0
                ? 'Log Down Payment — ₱${next.amount.toStringAsFixed(0)}'
                : 'Log Give #${next.paymentNumber} — ₱${next.amount.toStringAsFixed(0)}',
          ),
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // Dialogs / Sheets
  // =========================================================================

  void _showSubmitPaymentSheet(InstallmentPaymentEntity payment) {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(0),
    );
    String? selectedImagePath;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    payment.paymentNumber == 0
                        ? 'Log Down Payment'
                        : 'Log Give #${payment.paymentNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Amount Paid (₱)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Image picker
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picker = ImagePicker();
                      final image = await picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 1200,
                        imageQuality: 80,
                      );
                      if (image != null) {
                        setSheetState(() => selectedImagePath = image.path);
                      }
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      selectedImagePath != null
                          ? 'Photo selected ✓'
                          : 'Upload Proof of Payment',
                    ),
                  ),
                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;

                      Navigator.pop(ctx);
                      await widget.controller.submitPayment(
                        paymentId: payment.id,
                        amount: amount,
                        proofImagePath: selectedImagePath,
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Submit Payment'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRejectDialog(InstallmentPaymentEntity payment) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Payment'),
          content: TextField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) return;
                Navigator.pop(ctx);
                widget.controller.rejectPayment(payment.id, reason);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPayment(InstallmentPaymentEntity payment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Text(
            'Confirm receipt of ₱${payment.amount.toStringAsFixed(0)} for ${payment.paymentNumber == 0 ? 'down payment' : 'give #${payment.paymentNumber}'}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      widget.controller.confirmPayment(payment.id);
    }
  }

  void _showAttemptHistory(InstallmentPaymentEntity payment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          maxChildSize: 0.85,
          minChildSize: 0.3,
          expand: false,
          builder: (_, scrollController) {
            return FutureBuilder<List<PaymentAttemptEntity>>(
              future: widget.controller.getPaymentAttempts(payment.id),
              builder: (context, snapshot) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Payment #${payment.paymentNumber} — History',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Expanded(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (snapshot.hasError ||
                        !snapshot.hasData ||
                        snapshot.data!.isEmpty)
                      const Expanded(
                        child: Center(child: Text('No submission history')),
                      )
                    else
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: snapshot.data!.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final attempt = snapshot.data![i];
                            return _buildAttemptTile(attempt);
                          },
                        ),
                      ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAttemptTile(PaymentAttemptEntity attempt) {
    final statusColor = switch (attempt.status) {
      PaymentAttemptStatus.submitted => Colors.orange,
      PaymentAttemptStatus.confirmed => Colors.green,
      PaymentAttemptStatus.rejected => Colors.red,
    };
    final statusIcon = switch (attempt.status) {
      PaymentAttemptStatus.submitted => Icons.hourglass_top,
      PaymentAttemptStatus.confirmed => Icons.check_circle,
      PaymentAttemptStatus.rejected => Icons.cancel,
    };

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: statusColor.withValues(alpha: 0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 16, color: statusColor),
              const SizedBox(width: 6),
              Text(
                'Attempt #${attempt.attemptNumber}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: statusColor,
                ),
              ),
              const Spacer(),
              Text(
                attempt.status.label,
                style: TextStyle(fontSize: 11, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Amount: RM ${attempt.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12),
          ),
          if (attempt.createdAt != null)
            Text(
              'Submitted: ${_formatDateTime(attempt.createdAt!)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          if (attempt.rejectionReason != null &&
              attempt.rejectionReason!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Reason: ${attempt.rejectionReason}',
              style: const TextStyle(fontSize: 12, color: Colors.red),
            ),
          ],
          if (attempt.proofImageUrl != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _showProofImage(attempt.proofImageUrl!),
              child: const Text(
                'View proof',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showProofImage(String url) {
    // The URL stored might be a public URL that won't work for private buckets.
    // Extract the storage path and create a signed URL instead.
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Proof of Payment'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              FutureBuilder<String>(
                future: _getSignedProofUrl(url),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(Icons.broken_image, size: 64),
                    );
                  }
                  return Image.network(
                    snapshot.data!,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(Icons.broken_image, size: 64),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Extract storage path from a Supabase URL and create a signed URL
  Future<String> _getSignedProofUrl(String url) async {
    try {
      // Extract the path after /payment-proofs/
      final bucket = 'payment-proofs';
      final marker = '/object/public/$bucket/';
      final markerAlt = '/object/$bucket/';
      String storagePath;

      if (url.contains(marker)) {
        storagePath = Uri.decodeFull(url.split(marker).last);
      } else if (url.contains(markerAlt)) {
        storagePath = Uri.decodeFull(url.split(markerAlt).last);
      } else {
        // Fallback: try using the URL as-is (maybe already signed)
        return url;
      }

      // Remove query params if any
      if (storagePath.contains('?')) {
        storagePath = storagePath.split('?').first;
      }

      final signedUrl = await Supabase.instance.client.storage
          .from(bucket)
          .createSignedUrl(storagePath, 3600); // 1 hour expiry

      return signedUrl;
    } catch (e) {
      debugPrint('[InstallmentTracker] Error creating signed URL: $e');
      // Fallback to original URL
      return url;
    }
  }

  // =========================================================================
  // Review Section (shown when fully complete)
  // =========================================================================

  Widget _buildInstallmentReviewSection(bool isDark) {
    final txnController = widget.transactionController!;
    final myReview = txnController.myReview;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorConstants.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.rate_review, color: ColorConstants.primary, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Rate your Experience',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All gives completed! Please rate the other party.',
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 12),
          if (myReview != null) ...[
            const Text('Your submitted review:'),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 1; i <= 5; i++)
                  Icon(
                    i <= myReview.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  ),
              ],
            ),
            if (myReview.comment != null && myReview.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                myReview.comment!,
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _showReviewDialog(context),
                icon: const Icon(Icons.star),
                label: const Text('Submit Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showReviewDialog(BuildContext context) async {
    final txnController = widget.transactionController!;
    int rating = 5;
    int communication = 5;
    int reliability = 5;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Submit Review'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How was your experience?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildRatingRow(
                  'Overall',
                  rating,
                  (v) => setState(() => rating = v),
                ),
                const SizedBox(height: 12),
                _buildRatingRow(
                  'Communication',
                  communication,
                  (v) => setState(() => communication = v),
                ),
                const SizedBox(height: 12),
                _buildRatingRow(
                  'Reliability',
                  reliability,
                  (v) => setState(() => reliability = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Add a comment (optional)...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await txnController.submitReview(
                  rating: rating,
                  ratingCommunication: communication,
                  ratingReliability: reliability,
                  comment: commentController.text.trim(),
                );
                if (success && context.mounted) {
                  (ScaffoldMessenger.of(
                    context,
                  )..clearSnackBars()).showSnackBar(
                    const SnackBar(
                      content: Text('Thank you for your review!'),
                      backgroundColor: ColorConstants.success,
                    ),
                  );
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, int value, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        ...List.generate(5, (index) {
          final star = index + 1;
          return GestureDetector(
            onTap: () => onChanged(star),
            child: Icon(
              star <= value ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 28,
            ),
          );
        }),
      ],
    );
  }

  // =========================================================================
  // Helpers
  // =========================================================================

  Color _paymentStatusColor(InstallmentPaymentStatus status) {
    switch (status) {
      case InstallmentPaymentStatus.pending:
        return Colors.grey;
      case InstallmentPaymentStatus.submitted:
        return Colors.orange;
      case InstallmentPaymentStatus.confirmed:
        return Colors.green;
      case InstallmentPaymentStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _frequencyDisplayLabel(String frequency) {
    switch (frequency) {
      case 'no_schedule':
        return "Buyer's discretion";
      default:
        return frequency[0].toUpperCase() + frequency.substring(1);
    }
  }
}
