import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E2337) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImage(isDark),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(theme, isDark),
                const SizedBox(height: 12),
                _buildPriceAndTimer(theme, isDark),
                const SizedBox(height: 12),
                _buildCarDetails(theme, isDark),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: auction['image_url'] != null
                ? Image.network(
                    auction['image_url'],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(isDark),
                  )
                : _buildPlaceholder(isDark),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  'Preview',
                  style: const TextStyle(
                    color: Colors.white,
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
      color: isDark ? const Color(0xFF2A2F45) : const Color(0xFFE8EAF0),
      child: Center(
        child: Icon(
          Icons.directions_car_outlined,
          size: 48,
          color: isDark
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          auction['title'] ?? 'Untitled Auction',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (auction['category'] != null) ...[
          const SizedBox(height: 4),
          Text(
            auction['category'],
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriceAndTimer(ThemeData theme, bool isDark) {
    final currencyFormat = NumberFormat.currency(symbol: '₱', decimalDigits: 0);
    final currentPrice = (auction['current_price'] as num?)?.toDouble() ?? 0;
    final startingPrice = (auction['starting_price'] as num?)?.toDouble() ?? 0;
    final displayPrice = currentPrice > 0 ? currentPrice : startingPrice;
    final isCurrentBid = currentPrice > 0;

    // Calculate time remaining
    String timeRemaining = 'Ended';
    Color timerColor = Colors.red;
    
    if (auction['end_date'] != null) {
      final end = DateTime.tryParse(auction['end_date'].toString());
      if (end != null) {
        final diff = end.difference(DateTime.now());
        if (diff.isNegative) {
          timeRemaining = 'Ended';
        } else if (diff.inDays > 0) {
          timeRemaining = '${diff.inDays}d ${diff.inHours % 24}h left';
          timerColor = isDark ? Colors.white70 : Colors.grey[700]!;
        } else if (diff.inHours > 0) {
          timeRemaining = '${diff.inHours}h ${diff.inMinutes % 60}m left';
          timerColor = Colors.orange;
        } else {
          timeRemaining = '${diff.inMinutes}m ${diff.inSeconds % 60}s left';
          timerColor = Colors.red;
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isCurrentBid ? 'Current Bid' : 'Starting Price',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              currencyFormat.format(displayPrice),
              style: theme.textTheme.titleLarge?.copyWith(
                color: ColorConstants.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: timerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: timerColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: timerColor),
              const SizedBox(width: 6),
              Text(
                timeRemaining,
                style: TextStyle(
                  color: timerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCarDetails(ThemeData theme, bool isDark) {
    // Only show if we have data
    final mileage = auction['mileage'];
    final location = auction['location'];
    final totalBids = auction['total_bids'] ?? 0;

    return Row(
      children: [
        _buildDetailChip(
          Icons.speed, 
          mileage != null ? '${NumberFormat.decimalPattern().format(mileage)} km' : '--- km',
          isDark
        ),
        const SizedBox(width: 8),
        _buildDetailChip(
          Icons.gavel, 
          '$totalBids Bids', 
          isDark
        ),
        if (location != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _buildDetailChip(
              Icons.location_on_outlined, 
              location.toString(), 
              isDark
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white70 : Colors.grey[800],
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(ThemeData theme, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ColorConstants.info.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 16, color: ColorConstants.info),
          const SizedBox(width: 8),
          Text(
            'Login to bid & view full details',
            style: TextStyle(
              color: ColorConstants.info,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
