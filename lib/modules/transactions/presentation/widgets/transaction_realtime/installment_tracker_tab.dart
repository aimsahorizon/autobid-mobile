import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  final bool bothConfirmed;

  const InstallmentTrackerTab({
    super.key,
    required this.controller,
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
        // Agreement gate banner
        if (!widget.bothConfirmed)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Both parties must confirm the agreement before payments can be submitted.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),

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

        // Buyer FAB area — blocked until agreement confirmed
        if (isBuyer &&
            widget.bothConfirmed &&
            widget.controller.nextPendingPayment != null)
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
