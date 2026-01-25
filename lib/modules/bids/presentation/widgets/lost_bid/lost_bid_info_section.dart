import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/bid_detail_entity.dart';

class LostBidInfoSection extends StatelessWidget {
  final BidDetailEntity bidDetail;

  const LostBidInfoSection({
    super.key,
    required this.bidDetail,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final difference = (bidDetail.currentBid ?? bidDetail.startingPrice) - bidDetail.userHighestBid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.gavel,
                  label: 'Your Highest Bid',
                  value: '₱${bidDetail.userHighestBid.toStringAsFixed(0)}',
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark
                    ? ColorConstants.textSecondaryDark.withValues(alpha: 0.2)
                    : ColorConstants.textSecondaryLight.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.emoji_events,
                  label: 'Winning Bid',
                  value: '₱${(bidDetail.currentBid ?? bidDetail.startingPrice).toStringAsFixed(0)}',
                  valueColor: ColorConstants.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.trending_down,
                  color: ColorConstants.error,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outbid By',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₱${difference.toStringAsFixed(0)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.error,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: ColorConstants.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${bidDetail.userBidCount} bids placed',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Icon(
          icon,
          color: valueColor ?? ColorConstants.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
