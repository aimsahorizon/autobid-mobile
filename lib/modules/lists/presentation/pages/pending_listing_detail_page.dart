import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';

class PendingListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;

  const PendingListingDetailPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Review'),
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
    );
  }

  Widget _buildStatusCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withValues(alpha: 0.2),
            Colors.orange.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.pending_actions,
              size: 48,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Awaiting Admin Approval',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your listing is currently being reviewed by our admin team. This typically takes 24-48 hours.',
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
                color: Colors.orange,
              ),
              Expanded(
                child: _StatusStep(
                  icon: Icons.pending,
                  label: 'Under Review',
                  isCompleted: false,
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
                  'We review all listings to ensure quality and accuracy. You\'ll be notified once approved.',
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
                ? Colors.orange.withValues(alpha: 0.2)
                : (isDark
                    ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
                    : Colors.grey.shade100),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 24,
            color: isCompleted
                ? Colors.orange
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
                ? Colors.orange
                : (isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight),
          ),
        ),
      ],
    );
  }
}
