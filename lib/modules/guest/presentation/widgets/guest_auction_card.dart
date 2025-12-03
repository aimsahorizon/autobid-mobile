import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';

class GuestAuctionCard extends StatelessWidget {
  final Map<String, dynamic> auction;

  const GuestAuctionCard({
    super.key,
    required this.auction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(theme),
                const SizedBox(height: 8),
                _buildDescription(theme, isDark),
                const SizedBox(height: 12),
                _buildCategory(theme, isDark),
                const SizedBox(height: 12),
                _buildLoginPrompt(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: auction['image_url'] != null
            ? Image.network(
                auction['image_url'],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_outlined, size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      auction['title'] ?? 'Untitled Auction',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDescription(ThemeData theme, bool isDark) {
    return Text(
      auction['description'] ?? 'No description available',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark
            ? ColorConstants.textSecondaryDark
            : ColorConstants.textSecondaryLight,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCategory(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        auction['category'] ?? 'General',
        style: theme.textTheme.labelSmall?.copyWith(
          color: ColorConstants.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_outline,
            color: ColorConstants.info,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sign in to view full details and place bids',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColorConstants.info,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
