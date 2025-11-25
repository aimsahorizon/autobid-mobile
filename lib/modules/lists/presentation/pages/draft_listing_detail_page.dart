import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import 'create_listing_page.dart';
import '../controllers/listing_draft_controller.dart';

class DraftListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;
  final ListingDraftController controller;
  final String sellerId;

  const DraftListingDetailPage({
    super.key,
    required this.listing,
    required this.controller,
    required this.sellerId,
  });

  void _continueDraft(BuildContext context) {
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
  }

  void _deleteDraft(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Draft'),
        content: const Text(
          'Are you sure you want to delete this draft? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement delete draft
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to list
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Draft deleted')),
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
        title: const Text('Draft Listing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteDraft(context),
          ),
        ],
      ),
      backgroundColor: isDark ? ColorConstants.backgroundDark : ColorConstants.backgroundLight,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ListingCoverSection(listing: listing),
                const SizedBox(height: 16),
                _buildDraftStatusCard(context, isDark),
                const SizedBox(height: 16),
                ListingInfoSection(listing: listing),
                const SizedBox(height: 16),
              ],
            ),
          ),
          _buildBottomActionBar(context, isDark),
        ],
      ),
    );
  }

  Widget _buildDraftStatusCard(BuildContext context, bool isDark) {
    // Calculate completion percentage based on filled fields
    int filledFields = 0;
    int totalFields = 57; // Total fields in 9-step form

    // This is a simplified calculation - in real implementation,
    // use the completionPercentage from ListingDraftEntity
    if (listing.brand != null) filledFields++;
    if (listing.model != null) filledFields++;
    if (listing.year != null) filledFields++;
    if (listing.description != null) filledFields++;
    // ... etc

    final percentage = (filledFields / totalFields * 100).toInt();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.primary.withValues(alpha: 0.15),
            ColorConstants.primary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.primary.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_document,
                  size: 32,
                  color: ColorConstants.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Draft in Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue editing to complete your listing',
                      style: TextStyle(
                        fontSize: 14,
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
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Completion',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: isDark
                            ? ColorConstants.surfaceLight
                            : Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          ColorConstants.primary,
                        ),
                        minHeight: 8,
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
              Icon(
                Icons.access_time,
                size: 16,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Last saved: ${_formatDateTime(listing.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => _deleteDraft(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                ),
                child: const Text('Delete Draft'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () => _continueDraft(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: ColorConstants.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Continue Editing'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
