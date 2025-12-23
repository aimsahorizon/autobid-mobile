import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/admin_transaction_entity.dart';
import '../controllers/admin_transaction_controller.dart';

/// Page for reviewing a single transaction in detail
class AdminTransactionReviewPage extends StatefulWidget {
  final AdminTransactionController controller;
  final String transactionId;

  const AdminTransactionReviewPage({
    super.key,
    required this.controller,
    required this.transactionId,
  });

  @override
  State<AdminTransactionReviewPage> createState() =>
      _AdminTransactionReviewPageState();
}

class _AdminTransactionReviewPageState
    extends State<AdminTransactionReviewPage> {
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.controller.loadTransactionDetails(widget.transactionId);
  }

  @override
  void dispose() {
    _notesController.dispose();
    widget.controller.clearSelection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Review'),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                widget.controller.loadTransactionDetails(widget.transactionId),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final transaction = widget.controller.selectedTransaction;
          if (transaction == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ColorConstants.error,
                  ),
                  const SizedBox(height: 16),
                  const Text('Transaction not found'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Transaction Header
                _buildTransactionHeader(transaction),

                const SizedBox(height: 24),

                // Progress Overview
                _buildProgressOverview(transaction),

                const SizedBox(height: 24),

                // Seller Form
                _buildFormSection(
                  'Seller Form',
                  widget.controller.sellerForm,
                  transaction.sellerName,
                  Icons.store,
                  ColorConstants.primary,
                ),

                const SizedBox(height: 16),

                // Buyer Form
                _buildFormSection(
                  'Buyer Form',
                  widget.controller.buyerForm,
                  transaction.buyerName,
                  Icons.person,
                  Colors.blue,
                ),

                const SizedBox(height: 24),

                // Admin Notes
                _buildAdminNotesSection(transaction),

                const SizedBox(height: 24),

                // Action Buttons (only if pending review)
                if (transaction.readyForReview && !transaction.adminApproved)
                  _buildActionButtons(transaction),

                // Already Approved Banner
                if (transaction.adminApproved)
                  _buildApprovedBanner(transaction),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionHeader(AdminTransactionEntity transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.directions_car,
                  size: 32,
                  color: ColorConstants.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.carName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Transaction ID: ${transaction.id.substring(0, 8)}...',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(transaction.reviewStatus),
              ],
            ),

            const Divider(height: 24),

            // Price
            Row(
              children: [
                const Text('Agreed Price:'),
                const Spacer(),
                Text(
                  '₱${_formatPrice(transaction.agreedPrice)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Parties
            Row(
              children: [
                Expanded(
                  child: _buildPartyCard(
                    'Seller',
                    transaction.sellerName,
                    Icons.store,
                    ColorConstants.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPartyCard(
                    'Buyer',
                    transaction.buyerName,
                    Icons.person,
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created: ${_formatDate(transaction.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorConstants.textSecondaryLight,
                  ),
                ),
                if (transaction.updatedAt != null)
                  Text(
                    'Updated: ${_formatDate(transaction.updatedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(AdminReviewStatus status) {
    Color color;
    switch (status) {
      case AdminReviewStatus.pendingReview:
        color = ColorConstants.warning;
        break;
      case AdminReviewStatus.approved:
        color = ColorConstants.success;
        break;
      case AdminReviewStatus.completed:
        color = Colors.green;
        break;
      case AdminReviewStatus.failed:
        color = ColorConstants.error;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPartyCard(
    String label,
    String name,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: ColorConstants.textSecondaryLight,
                  ),
                ),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(AdminTransactionEntity transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildProgressStep(
                  'Seller Form',
                  transaction.sellerFormSubmitted,
                  1,
                ),
                _buildProgressConnector(transaction.sellerFormSubmitted),
                _buildProgressStep(
                  'Buyer Form',
                  transaction.buyerFormSubmitted,
                  2,
                ),
                _buildProgressConnector(transaction.bothFormsSubmitted),
                _buildProgressStep('Confirmed', transaction.bothConfirmed, 3),
                _buildProgressConnector(transaction.bothConfirmed),
                _buildProgressStep('Approved', transaction.adminApproved, 4),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStep(String label, bool completed, int step) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: completed ? ColorConstants.success : Colors.grey[300],
            ),
            child: Center(
              child: completed
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      step.toString(),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: completed
                  ? ColorConstants.textPrimaryLight
                  : ColorConstants.textSecondaryLight,
              fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressConnector(bool completed) {
    return Container(
      height: 2,
      width: 20,
      color: completed ? ColorConstants.success : Colors.grey[300],
    );
  }

  Widget _buildFormSection(
    String title,
    AdminTransactionFormEntity? form,
    String partyName,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      Text(
                        partyName,
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (form != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getFormStatusColor(
                        form.status,
                      ).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      form.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getFormStatusColor(form.status),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          if (form == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'Form not submitted yet',
                  style: TextStyle(color: ColorConstants.textSecondaryLight),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Agreement Details
                  _buildFormField(
                    'Agreed Price',
                    '₱${_formatPrice(form.agreedPrice)}',
                  ),
                  _buildFormField(
                    'Payment Method',
                    form.paymentMethod ?? 'Not specified',
                  ),
                  _buildFormField(
                    'Delivery Date',
                    form.deliveryDate != null
                        ? _formatDate(form.deliveryDate!)
                        : 'Not specified',
                  ),
                  _buildFormField(
                    'Delivery Location',
                    form.deliveryLocation ?? 'Not specified',
                  ),

                  const Divider(height: 24),

                  // Legal Checklist
                  const Text(
                    'Legal Checklist',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildChecklistItem('OR/CR Verified', form.orCrVerified),
                  _buildChecklistItem(
                    'Deed of Sale Ready',
                    form.deedsOfSaleReady,
                  ),
                  _buildChecklistItem(
                    'Plate Number Confirmed',
                    form.plateNumberConfirmed,
                  ),
                  _buildChecklistItem(
                    'Registration Valid',
                    form.registrationValid,
                  ),
                  _buildChecklistItem(
                    'No Outstanding Loans',
                    form.noOutstandingLoans,
                  ),
                  _buildChecklistItem(
                    'Mechanical Inspection Done',
                    form.mechanicalInspectionDone,
                  ),

                  // Checklist Summary
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value:
                        form.checklistCompletedCount / form.checklistTotalCount,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      form.checklistCompletedCount == form.checklistTotalCount
                          ? ColorConstants.success
                          : ColorConstants.warning,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${form.checklistCompletedCount}/${form.checklistTotalCount} items completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.textSecondaryLight,
                    ),
                  ),

                  // Additional Terms
                  if (form.additionalTerms != null &&
                      form.additionalTerms!.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Text(
                      'Additional Terms',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        form.additionalTerms!,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],

                  // Submitted At
                  if (form.submittedAt != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Submitted: ${_formatDateTime(form.submittedAt!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String label, bool completed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: completed ? ColorConstants.success : Colors.grey[400],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: completed
                  ? ColorConstants.textPrimaryLight
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminNotesSection(AdminTransactionEntity transaction) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (transaction.adminApproved && transaction.adminNotes != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(transaction.adminNotes!),
              )
            else
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add notes for this transaction...',
                  border: OutlineInputBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AdminTransactionEntity transaction) {
    return Column(
      children: [
        // Approve Button
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.controller.isProcessing
                ? null
                : () => _showApproveDialog(),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: widget.controller.isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: const Text('Approve Transaction'),
          ),
        ),

        const SizedBox(height: 12),

        // Reject Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.controller.isProcessing
                ? null
                : () => _showRejectDialog(),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.error,
              side: BorderSide(color: ColorConstants.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.cancel),
            label: const Text('Reject Transaction'),
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedBanner(AdminTransactionEntity transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorConstants.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstants.success),
      ),
      child: Row(
        children: [
          Icon(Icons.verified, color: ColorConstants.success, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction Approved',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.success,
                  ),
                ),
                if (transaction.adminApprovedAt != null)
                  Text(
                    'Approved on: ${_formatDateTime(transaction.adminApprovedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: ColorConstants.textSecondaryLight,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to approve this transaction?'),
            const SizedBox(height: 16),
            const Text(
              'This will:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Notify both parties of approval'),
            const Text('• Allow seller to proceed with delivery'),
            const Text('• Process deposit handling'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await widget.controller.approveTransaction(
                notes: _notesController.text.isNotEmpty
                    ? _notesController.text
                    : null,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction approved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              final success = await widget.controller.rejectTransaction(
                reason: reasonController.text,
              );
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Color _getFormStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.blue;
      case 'confirmed':
        return ColorConstants.success;
      case 'changes_requested':
        return ColorConstants.warning;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${months[date.month - 1]} ${date.day}, ${date.year} $hour:$minute';
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
