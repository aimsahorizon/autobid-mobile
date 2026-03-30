import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/utils/auction_alias_generator.dart';
import '../../../domain/entities/bid_history_entity.dart';

/// Displays chronological bid history for an auction
/// Shows all bids placed on this auction in timeline format
/// Different from user bids (Active/Won/Lost) which are in Bids module
///
/// Features:
/// - Timeline showing all bids from highest to lowest
/// - Highlights current user's bids
/// - Shows winning bid indicator
/// - Relative timestamps (e.g., "2h ago")
class BidHistoryTab extends StatelessWidget {
  final List<BidHistoryEntity> bidHistory;
  final bool isLoading;
  final bool isMystery;
  final bool isMysteryEnded;

  const BidHistoryTab({
    super.key,
    this.bidHistory = const [],
    this.isLoading = false,
    this.isMystery = false,
    this.isMysteryEnded = false,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while fetching bid history
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mystery auction: bids are sealed until ended
    if (isMystery && !isMysteryEnded) {
      return _buildSealedState(context);
    }

    // Show empty state if no bids have been placed
    if (bidHistory.isEmpty) {
      return _buildEmptyState(context);
    }

    // Display bid timeline
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bidHistory.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _BidHistoryCard(
        bid: bidHistory[index],
        isLatest: index == 0, // First item is the latest/highest bid
      ),
    );
  }

  /// Sealed state for mystery auctions (bids hidden until end)
  Widget _buildSealedState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 64,
              color: Colors.deepPurple.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Bids Are Sealed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All bids will be revealed when the auction ends.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state when no bids exist
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 64,
              color: isDark
                  ? ColorConstants.textSecondaryDark.withValues(alpha: 0.5)
                  : ColorConstants.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Bids Yet',
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to place a bid on this auction!',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Individual bid card in the timeline
/// Shows bidder name, amount, timestamp, and status indicators
class _BidHistoryCard extends StatelessWidget {
  final BidHistoryEntity bid;
  final bool isLatest;

  const _BidHistoryCard({required this.bid, required this.isLatest});

  /// Get display name: alias for other users, real name for current user
  String get _displayName {
    if (bid.isCurrentUser) return bid.bidderName;
    if (bid.bidderId != null) {
      return AuctionAliasGenerator.generate(bid.auctionId, bid.bidderId!);
    }
    return 'Anonymous';
  }

  /// Only show username for current user
  bool get _showUsername => bid.isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Highlight current user's bids with primary color border
          color: bid.isCurrentUser
              ? ColorConstants.primary
              : (isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight),
          width: bid.isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Bid rank indicator
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isLatest
                  ? ColorConstants.success.withValues(alpha: 0.1)
                  : (bid.isCurrentUser
                        ? ColorConstants.primary.withValues(alpha: 0.1)
                        : (isDark
                              ? ColorConstants.backgroundSecondaryDark
                              : ColorConstants.backgroundSecondaryLight)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isLatest ? Icons.emoji_events : Icons.gavel,
              size: 16,
              color: isLatest
                  ? ColorConstants.success
                  : (bid.isCurrentUser
                        ? ColorConstants.primary
                        : (isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight)),
            ),
          ),
          const SizedBox(width: 12),
          // Bid details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Bidder name
                    Flexible(
                      child: Text(
                        _displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: bid.isCurrentUser
                              ? ColorConstants.primary
                              : null,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // "You" badge for current user
                    if (bid.isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ColorConstants.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: ColorConstants.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (_showUsername &&
                    bid.username != null &&
                    bid.username != bid.bidderName)
                  Text(
                    '@${bid.username}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  _formatTimestamp(bid.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          // Bid amount with winning indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${_formatAmount(bid.amount)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isLatest ? ColorConstants.success : null,
                ),
              ),
              // Show "Winning" badge for latest bid
              if (isLatest) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: ColorConstants.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 10,
                        color: ColorConstants.success,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Winning',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.success,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Formats amount with comma separators
  String _formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  /// Formats timestamp to relative time (e.g., "2h ago", "3d ago")
  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      // Show actual date for older bids
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }
}
