import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';
import '../../data/datasources/listing_supabase_datasource.dart';
import '../../../../app/core/config/supabase_config.dart';

class ApprovedListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;

  const ApprovedListingDetailPage({super.key, required this.listing});

  Future<void> _makeListingLive(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Auction'),
        content: const Text(
          'Are you ready to make this listing live? Once published, the auction will start immediately.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final datasource = ListingSupabaseDataSource(SupabaseConfig.client);
      await datasource.makeListingLive(listing.id);

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading
      Navigator.pop(context, true); // Return to listings page with refresh flag

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction published successfully!'),
          backgroundColor: ColorConstants.success,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish auction: $e'),
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
      appBar: AppBar(
        title: const Text('Approved Listing'),
      ),
      backgroundColor: isDark ? ColorConstants.backgroundDark : ColorConstants.backgroundLight,
      body: ListView(
        children: [
          ListingCoverSection(listing: listing),
          const SizedBox(height: 16),
          _buildStatusCard(context, isDark),
          const SizedBox(height: 16),
          ListingInfoSection(listing: listing),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(context, isDark),
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.success.withValues(alpha: 0.2),
            ColorConstants.success.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ColorConstants.success.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorConstants.success.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: ColorConstants.success,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Listing Approved!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your listing has been approved by our admin team. You can now publish it to start the auction.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatusStep(
                  icon: Icons.check_circle,
                  label: 'Submitted',
                  isCompleted: true,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 2,
                width: 32,
                color: ColorConstants.success,
              ),
              Expanded(
                child: _StatusStep(
                  icon: Icons.check_circle,
                  label: 'Approved',
                  isCompleted: true,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 2,
                width: 32,
                color: isDark ? ColorConstants.surfaceLight : Colors.grey.shade300,
              ),
              Expanded(
                child: _StatusStep(
                  icon: Icons.rocket_launch,
                  label: 'Go Live',
                  isCompleted: false,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ready to publish? Click the "Make Live" button below to start your auction immediately.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton.icon(
            onPressed: () => _makeListingLive(context),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.primary,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.rocket_launch),
            label: const Text(
              'Make Live',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isCompleted;
  final bool isDark;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.isCompleted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted
                ? ColorConstants.success.withValues(alpha: 0.2)
                : (isDark
                    ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                    : Colors.grey.shade100),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isCompleted
                ? ColorConstants.success
                : (isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
            color: isCompleted
                ? ColorConstants.success
                : (isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
