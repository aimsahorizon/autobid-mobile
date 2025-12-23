import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../../domain/entities/listing_detail_entity.dart';

class AuctionStatsSection extends StatelessWidget {
  final ListingDetailEntity listing;

  const AuctionStatsSection({super.key, required this.listing});

  String _formatTimeRemaining(Duration? duration) {
    if (duration == null) return 'N/A';
    if (duration.isNegative) return 'Ended';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final timeRemaining = listing.timeRemaining;
    final isEnded = listing.hasEnded;

    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          // Current Bid / Starting Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.currentBid != null ? 'Current Bid' : 'Starting Price',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₱${(listing.currentBid ?? listing.startingPrice).toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                    ),
                  ),
                ],
              ),
              // Reserve Met Indicator
              if (listing.reservePrice != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: listing.isReserveMet
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        listing.isReserveMet ? Icons.check_circle : Icons.info,
                        size: 16,
                        color: listing.isReserveMet ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        listing.isReserveMet ? 'Reserve Met' : 'Reserve Not Met',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: listing.isReserveMet ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.timer_outlined,
                  label: 'Time Left',
                  value: isEnded ? 'Ended' : _formatTimeRemaining(timeRemaining),
                  valueColor: isEnded ? Colors.red : ColorConstants.primary,
                  isDark: isDark,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: isDark ? ColorConstants.surfaceLight : Colors.grey.shade300,
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.gavel,
                  label: 'Total Bids',
                  value: listing.totalBids.toString(),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.favorite_border,
                  label: 'Watchers',
                  value: listing.watchersCount.toString(),
                  isDark: isDark,
                ),
              ),
              Container(
                height: 50,
                width: 1,
                color: isDark ? ColorConstants.surfaceLight : Colors.grey.shade300,
              ),
              Expanded(
                child: _StatItem(
                  icon: Icons.visibility_outlined,
                  label: 'Views',
                  value: listing.viewsCount.toString(),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? ColorConstants.textSecondaryDark
              : ColorConstants.textSecondaryLight,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ??
                (isDark ? ColorConstants.textPrimaryDark : ColorConstants.textPrimaryLight),
          ),
        ),
      ],
    );
  }
}
