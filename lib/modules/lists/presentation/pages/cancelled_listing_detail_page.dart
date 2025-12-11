import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/config/supabase_config.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../../data/datasources/listing_supabase_datasource.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import '../controllers/listing_draft_controller.dart';
import 'create_listing_page.dart';

class CancelledListingDetailPage extends StatefulWidget {
  final ListingDetailEntity listing;
  final ListingDraftController controller;
  final String sellerId;

  const CancelledListingDetailPage({
    super.key,
    required this.listing,
    required this.controller,
    required this.sellerId,
  });

  @override
  State<CancelledListingDetailPage> createState() =>
      _CancelledListingDetailPageState();
}

class _CancelledListingDetailPageState
    extends State<CancelledListingDetailPage> {
  bool _isProcessing = false;
  late final ListingSupabaseDataSource _datasource;

  @override
  void initState() {
    super.initState();
    _datasource = ListingSupabaseDataSource(SupabaseConfig.client);
  }

  Future<void> _editListing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Listing'),
        content: const Text(
          'Editing this listing will create a new draft and resubmit for approval. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Edit'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Copy the cancelled listing to a new draft
      final draftId = await _datasource.copyListingToDraft(
        widget.listing.id,
        widget.sellerId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to create listing page with the copied draft
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CreateListingPage(
            controller: widget.controller,
            sellerId: widget.sellerId,
            draftId: draftId,
          ),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Draft created successfully. Edit and resubmit for approval.',
          ),
          backgroundColor: ColorConstants.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create draft: $e'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _reAuction(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-auction Listing'),
        content: const Text(
          'This will create a new auction with the same details. '
          'The new auction will be pending admin approval before going live.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create New Auction'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create new auction from the cancelled listing
      final newAuctionId = await _datasource.createAuctionFromCancelled(
        widget.listing.id,
        widget.sellerId,
        null, // Use original starting price
        null, // Use default 7-day auction duration
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Pop back to listing view
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'New auction created (ID: $newAuctionId). It is pending admin approval.',
          ),
          backgroundColor: ColorConstants.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create new auction: $e'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Future<void> _deleteListing(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to permanently delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Delete the listing
      await _datasource.deleteListing(widget.listing.id, widget.sellerId);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Pop back twice to return to listing view
      Navigator.pop(context);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing deleted successfully'),
          backgroundColor: ColorConstants.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete listing: $e'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Cancelled Listing')),
      backgroundColor: isDark
          ? ColorConstants.backgroundDark
          : ColorConstants.backgroundLight,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListingCoverSection(listing: widget.listing),
                const SizedBox(height: 16),
                _buildCancelledStatusCard(context, isDark),
                const SizedBox(height: 16),
                _buildActionOptionsCard(context, isDark),
                const SizedBox(height: 16),
                ListingInfoSection(listing: widget.listing),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledStatusCard(BuildContext context, bool isDark) {
    final reserveNotMet =
        widget.listing.reservePrice != null && !widget.listing.isReserveMet;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withValues(alpha: 0.15),
            Colors.red.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cancel, size: 48, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Auction Cancelled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reserveNotMet
                ? 'Reserve price was not met'
                : 'Ended on ${_formatDate(widget.listing.endTime ?? widget.listing.createdAt)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.surfaceLight.withValues(alpha: 0.3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatColumn(
                      label: 'Total Bids',
                      value: '${widget.listing.totalBids}',
                      isDark: isDark,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: isDark
                          ? ColorConstants.surfaceLight
                          : Colors.grey.shade300,
                    ),
                    _StatColumn(
                      label: reserveNotMet ? 'Highest Bid' : 'Starting Price',
                      value:
                          '₱${(widget.listing.currentBid ?? widget.listing.startingPrice).toStringAsFixed(0)}',
                      isDark: isDark,
                    ),
                  ],
                ),
                if (reserveNotMet) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reserve price of ₱${widget.listing.reservePrice!.toStringAsFixed(0)} was not reached',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
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

  Widget _buildActionOptionsCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What would you like to do?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _ActionOption(
            icon: Icons.edit,
            title: 'Edit & Resubmit',
            description: 'Make changes and resubmit for approval',
            color: ColorConstants.primary,
            onTap: () => _editListing(context),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _ActionOption(
            icon: Icons.refresh,
            title: 'Re-auction',
            description: 'Start a new auction with same details',
            color: Colors.blue,
            onTap: () => _reAuction(context),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _ActionOption(
            icon: Icons.delete,
            title: 'Delete Listing',
            description: 'Permanently remove this listing',
            color: Colors.red,
            onTap: () => _deleteListing(context),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _StatColumn({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _ActionOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
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
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }
}
