import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/installment_plan_entity.dart';
import '../../../domain/entities/installment_payment_entity.dart';
import '../../controllers/installment_controller.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Installment Tracker Tab — shows payment plan progress, payment history,
/// and action buttons for buyers (submit payment) and sellers (confirm/reject).
class InstallmentTrackerTab extends StatefulWidget {
  final InstallmentController controller;
  final String transactionId;
  final String userId;
  final FormRole userRole;

  const InstallmentTrackerTab({
    super.key,
    required this.controller,
    required this.transactionId,
    required this.userId,
    required this.userRole,
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
  // No Plan View — Buyer can set up an installment plan
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
              'No Installment Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isBuyer
                  ? 'Set up an installment plan to spread your payments over time.'
                  : 'The buyer has not set up an installment plan yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            if (isBuyer) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showCreatePlanDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Installment Plan'),
              ),
            ],
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
              ? const Center(child: Text('No payments scheduled'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    return _buildPaymentCard(payments[index], isDark);
                  },
                ),
        ),

        // Buyer FAB area
        if (isBuyer && widget.controller.nextPendingPayment != null)
          _buildBuyerActionBar(isDark),
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
                'Payment Progress',
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
                '${plan.numInstallments} payments',
                isDark,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                Icons.repeat,
                plan.frequency[0].toUpperCase() + plan.frequency.substring(1),
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
                        'Due: ${_formatDate(payment.dueDate)}${isOverdue ? ' (OVERDUE)' : ''}',
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

            // Rejection reason
            if (payment.rejectionReason != null &&
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
                : 'Log Payment #${next.paymentNumber} — ₱${next.amount.toStringAsFixed(0)}',
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

  void _showCreatePlanDialog() {
    final totalController = TextEditingController();
    final downController = TextEditingController(text: '0');
    int installments = 3;
    String frequency = 'monthly';

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
                  const Text(
                    'Create Installment Plan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: totalController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Total Amount (₱)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: downController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Down Payment (₱)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: installments,
                    decoration: const InputDecoration(
                      labelText: 'Number of Installments',
                      border: OutlineInputBorder(),
                    ),
                    items: [2, 3, 4, 6, 9, 12, 18, 24].map((n) {
                      return DropdownMenuItem(
                        value: n,
                        child: Text('$n payments'),
                      );
                    }).toList(),
                    onChanged: (v) =>
                        setSheetState(() => installments = v ?? 3),
                  ),
                  const SizedBox(height: 12),

                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(
                        value: 'bi-weekly',
                        child: Text('Bi-Weekly'),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text('Monthly'),
                      ),
                    ],
                    onChanged: (v) =>
                        setSheetState(() => frequency = v ?? 'monthly'),
                  ),
                  const SizedBox(height: 20),

                  FilledButton(
                    onPressed: () async {
                      final total = double.tryParse(totalController.text);
                      final down = double.tryParse(downController.text) ?? 0;
                      if (total == null || total <= 0) return;
                      if (down >= total) return;

                      Navigator.pop(ctx);
                      await widget.controller.createPlan(
                        transactionId: widget.transactionId,
                        totalAmount: total,
                        downPayment: down,
                        numInstallments: installments,
                        frequency: frequency,
                        startDate: DateTime.now(),
                      );
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Create Plan'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

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
                        : 'Log Payment #${payment.paymentNumber}',
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
            'Confirm receipt of ₱${payment.amount.toStringAsFixed(0)} for ${payment.paymentNumber == 0 ? 'down payment' : 'payment #${payment.paymentNumber}'}?',
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

  void _showProofImage(String url) {
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
              Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(32),
                  child: Icon(Icons.broken_image, size: 64),
                ),
              ),
            ],
          ),
        );
      },
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
}
