import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/auction_entity.dart';

class AuctionCard extends StatelessWidget {
  final AuctionEntity auction;
  final VoidCallback? onTap;

  const AuctionCard({
    super.key,
    required this.auction,
    this.onTap,
  });

  String _formatTimeRemaining() {
    final minutes = auction.timeRemainingMinutes;

    if (minutes < 0) return 'Ended';
    if (minutes == 0) return '< 1 min';
    if (minutes == 1) return '< 2 mins';
    if (minutes < 60) return '$minutes mins';

    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hrs';

    final days = hours ~/ 24;
    return '$days days';
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? ColorConstants.borderDark : ColorConstants.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCarName(theme),
                  const SizedBox(height: 8),
                  _buildCurrentBid(theme),
                  const SizedBox(height: 12),
                  _buildStats(theme, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: auction.carImageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: ColorConstants.backgroundSecondaryLight,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: ColorConstants.backgroundSecondaryLight,
          child: const Icon(
            Icons.directions_car,
            size: 48,
            color: ColorConstants.textSecondaryLight,
          ),
        ),
      ),
    );
  }

  Widget _buildCarName(ThemeData theme) {
    return Text(
      auction.carName,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildCurrentBid(ThemeData theme) {
    return Row(
      children: [
        Text(
          '₱${_formatPrice(auction.currentBid)}',
          style: theme.textTheme.titleLarge?.copyWith(
            color: ColorConstants.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: auction.hasEnded
                ? ColorConstants.error.withValues(alpha: 0.1)
                : ColorConstants.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: auction.hasEnded
                    ? ColorConstants.error
                    : ColorConstants.success,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTimeRemaining(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: auction.hasEnded
                      ? ColorConstants.error
                      : ColorConstants.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme, bool isDark) {
    return Row(
      children: [
        _buildStatItem(
          icon: Icons.visibility_outlined,
          count: auction.watchersCount,
          theme: theme,
          isDark: isDark,
        ),
        const SizedBox(width: 16),
        _buildStatItem(
          icon: Icons.gavel_rounded,
          count: auction.biddersCount,
          theme: theme,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required int count,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark
              ? ColorConstants.textSecondaryDark
              : ColorConstants.textSecondaryLight,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
