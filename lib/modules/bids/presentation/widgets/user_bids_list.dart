import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/user_bid_entity.dart';
import 'user_bid_card.dart';

/// Grid list widget for displaying user bids
/// Shows loading state, empty state, or 2-column grid of bid cards
/// Used in Active, Won, and Lost tabs
///
/// Features:
/// - Responsive 2-column grid layout
/// - Customizable empty state for each tab
/// - Loading indicator while data fetches
/// - Optional tap callback for navigation to auction detail
class UserBidsList extends StatelessWidget {
  final List<UserBidEntity> bids;
  final bool isLoading;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final VoidCallback? onBidTap;

  const UserBidsList({
    super.key,
    required this.bids,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.emptyIcon,
    this.isLoading = false,
    this.onBidTap,
  });

  @override
  Widget build(BuildContext context) {
    // Show loading spinner while data is being fetched
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state if no bids exist
    if (bids.isEmpty) {
      return _EmptyState(
        title: emptyTitle,
        subtitle: emptySubtitle,
        icon: emptyIcon,
      );
    }

    // Display bids in 2-column grid
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72, // Card height ratio
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: bids.length,
      itemBuilder: (context, index) => UserBidCard(
        bid: bids[index],
        onTap: onBidTap,
      ),
    );
  }
}

/// Empty state widget shown when no bids exist for current tab
/// Displays icon, title, and subtitle with appropriate messaging
class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: isDark
                  ? ColorConstants.textSecondaryDark.withValues(alpha: 0.5)
                  : ColorConstants.textSecondaryLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
