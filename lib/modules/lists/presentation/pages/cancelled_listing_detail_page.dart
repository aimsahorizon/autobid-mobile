import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import '../controllers/listing_draft_controller.dart';
import 'create_listing_page.dart';

class CancelledListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;
  final ListingDraftController controller;
  final String sellerId;

  const CancelledListingDetailPage({
    super.key,
    required this.listing,
    required this.controller,
    required this.sellerId,
  });

  void _editListing(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Listing'),
        content: const Text(
          'Editing this listing will create a new draft and resubmit for approval. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Create new draft from cancelled listing
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateListingPage(
                    controller: controller,
                    sellerId: sellerId,
                    draftId: listing.id,
                  ),
                ),
              );
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  void _reAuction(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-auction Listing'),
        content: const Text(
          'This will create a new auction with the same details. You can adjust the starting price and auction duration.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Create new auction from cancelled listing
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New auction created')),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _deleteListing(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Listing'),
        content: const Text(
          'Are you sure you want to permanently delete this listing? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete listing permanently
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Listing deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancelled Listing'),
      ),
      backgroundColor: isDark ? ColorConstants.backgroundDark : ColorConstants.backgroundLight,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListingCoverSection(listing: listing),
                const SizedBox(height: 16),
                _buildCancelledStatusCard(context, isDark),
                const SizedBox(height: 16),
                _buildActionOptionsCard(context, isDark),
                const SizedBox(height: 16),
                ListingInfoSection(listing: listing),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledStatusCard(BuildContext context, bool isDark) {
    final reserveNotMet = listing.reservePrice != null && !listing.isReserveMet;

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
            child: const Icon(
              Icons.cancel,
              size: 48,
              color: Colors.red,
            ),
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
                : 'Ended on ${_formatDate(listing.endTime ?? listing.createdAt)}',
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
                      value: '${listing.totalBids}',
                      isDark: isDark,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: isDark ? ColorConstants.surfaceLight : Colors.grey.shade300,
                    ),
                    _StatColumn(
                      label: reserveNotMet ? 'Highest Bid' : 'Starting Price',
                      value: '₱${(listing.currentBid ?? listing.startingPrice).toStringAsFixed(0)}',
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
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reserve price of ₱${listing.reservePrice!.toStringAsFixed(0)} was not reached',
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
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
