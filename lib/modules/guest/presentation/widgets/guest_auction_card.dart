import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E2337), const Color(0xFF151828)]
              : [Colors.white, const Color(0xFFFAFBFD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(isDark),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTitle(theme),
                const SizedBox(height: 10),
                _buildDescription(theme, isDark),
                const SizedBox(height: 16),
                _buildCategory(theme, isDark),
                const SizedBox(height: 16),
                _buildLoginPrompt(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: auction['image_url'] != null
                ? Image.network(
                    auction['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(isDark),
                  )
                : _buildPlaceholder(isDark),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility_outlined,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 4),
                Text(
                  'Preview',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2A2F45), const Color(0xFF1A1E2E)]
              : [const Color(0xFFE8EAF0), const Color(0xFFF5F7FA)],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: isDark
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.2),
        ),
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
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.primary.withValues(alpha: 0.15),
                ColorConstants.primary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorConstants.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 14,
                color: ColorConstants.primary,
              ),
              const SizedBox(width: 6),
              Text(
                auction['category'] ?? 'General',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: ColorConstants.primary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginPrompt(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  ColorConstants.info.withValues(alpha: 0.15),
                  ColorConstants.info.withValues(alpha: 0.08),
                ]
              : [
                  ColorConstants.info.withValues(alpha: 0.12),
                  ColorConstants.info.withValues(alpha: 0.05),
                ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorConstants.info.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorConstants.info.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline,
              color: ColorConstants.info,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sign in to view full details and place bids',
              style: theme.textTheme.bodySmall?.copyWith(
                color: ColorConstants.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: ColorConstants.info.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }
}
