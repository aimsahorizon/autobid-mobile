import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/admin_listing_entity.dart';
import '../controllers/admin_controller.dart';

/// Admin page for reviewing listing details
class AdminListingReviewPage extends StatefulWidget {
  final AdminListingEntity listing;
  final AdminController controller;

  const AdminListingReviewPage({
    super.key,
    required this.listing,
    required this.controller,
  });

  @override
  State<AdminListingReviewPage> createState() => _AdminListingReviewPageState();
}

class _AdminListingReviewPageState extends State<AdminListingReviewPage> {
  bool _isProcessing = false;

  Future<void> _approveListing() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Listing'),
        content: const Text('Are you sure you want to approve this listing?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    final success = await widget.controller.approveListing(widget.listing.id);

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing approved successfully'),
          backgroundColor: ColorConstants.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: ${widget.controller.error}'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _rejectListing() async {
    final TextEditingController reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Rejection Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || reasonController.text.isEmpty) return;

    setState(() => _isProcessing = true);

    final success = await widget.controller.rejectListing(
      widget.listing.id,
      reasonController.text,
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing rejected'),
          backgroundColor: ColorConstants.warning,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: ${widget.controller.error}'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _isProcessing = true);

    final success = await widget.controller.changeStatus(
      widget.listing.id,
      newStatus,
    );

    if (!mounted) return;

    setState(() => _isProcessing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status changed to $newStatus'),
          backgroundColor: ColorConstants.success,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change status: ${widget.controller.error}'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Listing'),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'live') {
                _changeStatus('live');
              } else if (value == 'cancelled') {
                _changeStatus('cancelled');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'live',
                child: Row(
                  children: [
                    Icon(Icons.play_arrow, size: 20),
                    SizedBox(width: 8),
                    Text('Set Live'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Row(
                  children: [
                    Icon(Icons.cancel, size: 20),
                    SizedBox(width: 8),
                    Text('Cancel Listing'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover Photo
                  if (widget.listing.coverPhotoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          widget.listing.coverPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: ColorConstants.surfaceVariantLight,
                                child: const Center(
                                  child: Icon(Icons.directions_car, size: 64),
                                ),
                              ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Vehicle Info
                  Text(
                    widget.listing.carName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Badge
                  _buildStatusBadge(),
                  const SizedBox(height: 24),

                  // Seller Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seller Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('Name', widget.listing.sellerName),
                          _buildInfoRow('Email', widget.listing.sellerEmail),
                          _buildInfoRow(
                            'Submitted',
                            widget.listing.submittedAt != null
                                ? '${widget.listing.submittedAt!.day}/${widget.listing.submittedAt!.month}/${widget.listing.submittedAt!.year}'
                                : 'N/A',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vehicle Details Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vehicle Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            'Condition',
                            widget.listing.condition.toUpperCase(),
                          ),
                          _buildInfoRow(
                            'Mileage',
                            '${widget.listing.mileage.toStringAsFixed(0)} km',
                          ),
                          _buildInfoRow(
                            'Starting Price',
                            '₱${widget.listing.startingPrice.toStringAsFixed(2)}',
                          ),
                          if (widget.listing.reservePrice != null)
                            _buildInfoRow(
                              'Reserve Price',
                              '₱${widget.listing.reservePrice!.toStringAsFixed(2)}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons (only for pending status)
                  if (widget.listing.status == 'pending_approval') ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _approveListing,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Approve Listing'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorConstants.success,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _rejectListing,
                        icon: const Icon(Icons.cancel),
                        label: const Text('Reject Listing'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.error,
                          side: BorderSide(color: ColorConstants.error),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatusBadge() {
    Color color;
    IconData icon;

    switch (widget.listing.status) {
      case 'pending_approval':
        color = ColorConstants.warning;
        icon = Icons.pending;
        break;
      case 'scheduled':
        color = ColorConstants.info;
        icon = Icons.schedule;
        break;
      case 'live':
        color = ColorConstants.success;
        icon = Icons.check_circle;
        break;
      default:
        color = ColorConstants.textSecondaryLight;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            widget.listing.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
                color: ColorConstants.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
