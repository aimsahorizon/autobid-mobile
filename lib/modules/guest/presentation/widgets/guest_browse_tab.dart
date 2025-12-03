import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/guest_controller.dart';
import 'guest_auction_card.dart';

class GuestBrowseTab extends StatelessWidget {
  final GuestController controller;

  const GuestBrowseTab({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.isLoadingAuctions) {
          return _buildLoadingState();
        }

        if (controller.auctions.isEmpty) {
          return _buildEmptyState(theme, isDark);
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadGuestAuctions(),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: controller.auctions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final auction = controller.auctions[index];
              return GuestAuctionCard(auction: auction);
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
          const SizedBox(height: 16),
          Text(
            'No Auctions Available',
            style: theme.textTheme.titleLarge?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new listings',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
