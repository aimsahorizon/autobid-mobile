import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/kyc_document_entity.dart';
import '../controllers/kyc_controller.dart';
import '../widgets/kyc_document_viewer.dart';

class AdminKycReviewPage extends StatefulWidget {
  final KycController controller;
  final String kycDocumentId;

  const AdminKycReviewPage({
    super.key,
    required this.controller,
    required this.kycDocumentId,
  });

  @override
  State<AdminKycReviewPage> createState() => _AdminKycReviewPageState();
}

class _AdminKycReviewPageState extends State<AdminKycReviewPage> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _rejectionReasonController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.loadDocument(widget.kycDocumentId);
  }

  @override
  void dispose() {
    _notesController.dispose();
    _rejectionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Document Review'),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoadingDocument) {
            return const Center(child: CircularProgressIndicator());
          }

          final document = widget.controller.selectedDocument;
          if (document == null) {
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
                  const Text('Failed to load KYC document'),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () {
                      widget.controller.loadDocument(widget.kycDocumentId);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Document Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildUserInfoSection(document),
                      const SizedBox(height: 24),
                      _buildAddressSection(document),
                      const SizedBox(height: 24),
                      _buildDocumentsSection(document),
                      const SizedBox(height: 24),
                      _buildReviewInfoSection(document),
                      const SizedBox(height: 24),
                      _buildAdminNotesSection(document),
                    ],
                  ),
                ),
              ),

              // Action Buttons (only show if pending or under_review)
              if (document.isPending) _buildActionButtons(document),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUserInfoSection(KycDocumentEntity document) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: ColorConstants.primary),
                const SizedBox(width: 8),
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Full Name', document.fullName),
            _buildInfoRow('Email', document.email),
            if (document.phoneNumber != null)
              _buildInfoRow('Phone', document.phoneNumber!),
            if (document.dateOfBirth != null)
              _buildInfoRow(
                'Date of Birth',
                _formatDate(document.dateOfBirth!),
              ),
            if (document.sex != null) _buildInfoRow('Sex', document.sex!),
            if (document.nationalIdNumber != null)
              _buildInfoRow('National ID', document.nationalIdNumber!),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(KycDocumentEntity document) {
    if (document.fullAddress.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: ColorConstants.primary),
                const SizedBox(width: 8),
                const Text(
                  'Address',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              document.fullAddress,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentsSection(KycDocumentEntity document) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: ColorConstants.primary),
                const SizedBox(width: 8),
                const Text(
                  'Submitted Documents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // National ID
            const Text(
              'National ID',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: KycDocumentViewer(
                    title: 'Front',
                    filePath: document.nationalIdFrontUrl,
                    controller: widget.controller,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KycDocumentViewer(
                    title: 'Back',
                    filePath: document.nationalIdBackUrl,
                    controller: widget.controller,
                  ),
                ),
              ],
            ),

            // Secondary ID
            if (document.secondaryGovIdFrontUrl != null) ...[
              const SizedBox(height: 24),
              Text(
                'Secondary ID ${document.secondaryGovIdType != null ? "(${document.secondaryGovIdType})" : ""}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: KycDocumentViewer(
                      title: 'Front',
                      filePath: document.secondaryGovIdFrontUrl!,
                      controller: widget.controller,
                    ),
                  ),
                  if (document.secondaryGovIdBackUrl != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: KycDocumentViewer(
                        title: 'Back',
                        filePath: document.secondaryGovIdBackUrl!,
                        controller: widget.controller,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            // Proof of Address
            if (document.proofOfAddressUrl != null) ...[
              const SizedBox(height: 24),
              Text(
                'Proof of Address ${document.proofOfAddressType != null ? "(${document.proofOfAddressType})" : ""}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              KycDocumentViewer(
                title: 'Document',
                filePath: document.proofOfAddressUrl!,
                controller: widget.controller,
              ),
            ],

            // Selfie with ID
            const SizedBox(height: 24),
            const Text(
              'Selfie with ID',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            KycDocumentViewer(
              title: 'Selfie',
              filePath: document.selfieWithIdUrl,
              controller: widget.controller,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewInfoSection(KycDocumentEntity document) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: ColorConstants.primary),
                const SizedBox(width: 8),
                const Text(
                  'Review Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Status', _formatStatus(document.statusName)),
            if (document.submittedAt != null)
              _buildInfoRow(
                'Submitted At',
                _formatDateTime(document.submittedAt!),
              ),
            if (document.reviewedAt != null)
              _buildInfoRow(
                'Reviewed At',
                _formatDateTime(document.reviewedAt!),
              ),
            if (document.reviewedByName != null)
              _buildInfoRow('Reviewed By', document.reviewedByName!),
            if (document.slaDeadline != null)
              _buildInfoRow(
                'SLA Deadline',
                _formatDateTime(document.slaDeadline!),
                color: document.isSlaBreached
                    ? ColorConstants.error
                    : document.isSlaAtRisk
                        ? Colors.orange
                        : null,
              ),
            if (document.rejectionReason != null)
              _buildInfoRow(
                'Rejection Reason',
                document.rejectionReason!,
                color: ColorConstants.error,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminNotesSection(KycDocumentEntity document) {
    if (document.adminNotes == null || document.adminNotes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: ColorConstants.primary),
                const SizedBox(width: 8),
                const Text(
                  'Admin Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              document.adminNotes!,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(KycDocumentEntity document) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _showRejectDialog(document),
                icon: const Icon(Icons.cancel),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ColorConstants.error,
                  side: BorderSide(color: ColorConstants.error),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _isProcessing ? null : () => _showApproveDialog(document),
                icon: const Icon(Icons.check_circle),
                label: const Text('Approve'),
                style: FilledButton.styleFrom(
                  backgroundColor: ColorConstants.success,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? ColorConstants.textPrimaryLight,
                fontWeight: color != null ? FontWeight.bold : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(KycDocumentEntity document) {
    _notesController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve KYC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Approve KYC for ${document.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                hintText: 'Add any notes for this approval',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _handleApprove(document),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(KycDocumentEntity document) {
    _rejectionReasonController.clear();
    _notesController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reject KYC for ${document.fullName}?'),
            const SizedBox(height: 16),
            TextField(
              controller: _rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason *',
                hintText: 'Explain why this KYC is being rejected',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Admin Notes (Optional)',
                hintText: 'Add any additional notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _handleReject(document),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove(KycDocumentEntity document) async {
    Navigator.pop(context);
    setState(() => _isProcessing = true);

    final success = await widget.controller.approveKyc(
      document.id,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KYC approved for ${document.fullName}'),
          backgroundColor: ColorConstants.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve KYC: ${widget.controller.error}'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _handleReject(KycDocumentEntity document) async {
    final reason = _rejectionReasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a rejection reason'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context);
    setState(() => _isProcessing = true);

    final success = await widget.controller.rejectKyc(
      document.id,
      reason,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    setState(() => _isProcessing = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('KYC rejected for ${document.fullName}'),
          backgroundColor: Colors.orange,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject KYC: ${widget.controller.error}'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'under_review':
        return 'Under Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }
}
