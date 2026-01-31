import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../browse/presentation/pages/auction_detail_page.dart';
import '../../../browse/presentation/controllers/auction_detail_controller.dart';
import '../../../notifications/notifications_module.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../controllers/bids_controller.dart';
import '../widgets/user_bids_list.dart';
import '../../domain/entities/user_bid_entity.dart';
import 'won_bid_detail_page.dart';
import 'lost_bid_detail_page.dart';

/// Main page for Bids module displaying user's auction participation
/// Features three tabs: Active, Won, and Lost bids
class BidsPage extends StatefulWidget {
  final BidsController controller;

  const BidsPage({super.key, required this.controller});

  @override
  State<BidsPage> createState() => _BidsPageState();
}

class _BidsPageState extends State<BidsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGridView = true; // Toggle between grid and list view

  @override
  void initState() {
    super.initState();
    // Initialize tab controller for 4 tabs
    _tabController = TabController(length: 4, vsync: this);
    // Load bids on page init
    widget.controller.loadUserBids();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handles pull-to-refresh action
  Future<void> _handleRefresh() async {
    await widget.controller.loadUserBids();
  }

  void _navigateToActiveBid(BuildContext context, UserBidEntity bid) {
    debugPrint(
      '[BidsPage] _navigateToActiveBid called with auctionId=${bid.auctionId}',
    );

    // Navigate to auction detail page from browse module
    // This shows the actual auction with live bidding functionality
    final controller = GetIt.instance<AuctionDetailController>();
    debugPrint(
      '[BidsPage] Created AuctionDetailController, navigating to AuctionDetailPage',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AuctionDetailPage(auctionId: bid.auctionId, controller: controller),
      ),
    );
  }

  void _navigateToWonBid(BuildContext context, UserBidEntity bid) {
    if (!bid.canAccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Waiting for seller to proceed to transaction.'),
          backgroundColor: ColorConstants.warning,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }
    debugPrint(
      '[BidsPage] _navigateToWonBid called with auctionId=${bid.auctionId}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WonBidDetailPage(auctionId: bid.auctionId),
      ),
    );
  }

  void _navigateToLostBid(BuildContext context, UserBidEntity bid) {
    debugPrint(
      '[BidsPage] _navigateToLostBid called with auctionId=${bid.auctionId}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LostBidDetailPage(auctionId: bid.auctionId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('My Bids'),
        centerTitle: true,
        actions: [
          // Notification bell with unread count badge
          ListenableBuilder(
            listenable: NotificationsModule.instance.controller,
            builder: (context, _) {
              final notificationController =
                  NotificationsModule.instance.controller;
              final unreadCount = notificationController.unreadCount;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsPage(),
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => widget.controller.loadUserBids(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          // Show error state with retry button
          if (widget.controller.hasError && widget.controller.totalBidsCount == 0) {
            return _buildErrorState();
          }

          return Column(
            children: [
              // Tab bar with badges showing bid counts
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorConstants.backgroundDark
                      : ColorConstants.backgroundSecondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  padding: const EdgeInsets.all(4),
                  indicator: BoxDecoration(
                    color: isDark ? ColorConstants.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: ColorConstants.primary,
                  unselectedLabelColor: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    _TabWithBadge(
                      label: 'Active',
                      count: widget.controller.activeBids.length,
                      color: ColorConstants.primary,
                    ),
                    _TabWithBadge(
                      label: 'Won',
                      count: widget.controller.wonBids.length,
                      color: ColorConstants.success,
                    ),
                    _TabWithBadge(
                      label: 'Lost',
                      count: widget.controller.lostBids.length,
                      color: ColorConstants.error,
                    ),
                    _TabWithBadge(
                      label: 'Cancelled',
                      count: widget.controller.cancelledBids.length,
                      color: ColorConstants.warning,
                    ),
                  ],
                ),
              ),
              // Tab view content with pull-to-refresh
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active bids tab
                      UserBidsList(
                        bids: widget.controller.activeBids,
                        isLoading: widget.controller.isLoading,
                        emptyTitle: 'No Active Bids',
                        emptySubtitle:
                            'Browse auctions and place a bid to get started!',
                        emptyIcon: Icons.gavel_rounded,
                        onBidTap: (bid) => _navigateToActiveBid(context, bid),
                        isGridView: _isGridView,
                      ),
                      // Won bids tab
                      UserBidsList(
                        bids: widget.controller.wonBids,
                        isLoading: widget.controller.isLoading,
                        emptyTitle: 'No Won Auctions',
                        emptySubtitle:
                            'Keep bidding to win your first auction!',
                        emptyIcon: Icons.emoji_events_outlined,
                        onBidTap: (bid) => _navigateToWonBid(context, bid),
                        isGridView: _isGridView,
                      ),
                      // Lost bids tab
                      UserBidsList(
                        bids: widget.controller.lostBids,
                        isLoading: widget.controller.isLoading,
                        emptyTitle: 'No Lost Auctions',
                        emptySubtitle:
                            'You haven\'t lost any auctions yet. Good luck!',
                        emptyIcon: Icons.sentiment_neutral_outlined,
                        onBidTap: (bid) => _navigateToLostBid(context, bid),
                        isGridView: _isGridView,
                      ),
                      // Cancelled bids tab
                      UserBidsList(
                        bids: widget.controller.cancelledBids,
                        isLoading: widget.controller.isLoading,
                        emptyTitle: 'No Cancelled Deals',
                        emptySubtitle:
                            'Deals you\'ve cancelled will appear here.',
                        emptyIcon: Icons.cancel_outlined,
                        onBidTap: (bid) =>
                            _navigateToCancelledBid(context, bid),
                        isGridView: _isGridView,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _navigateToCancelledBid(BuildContext context, UserBidEntity bid) {
    // Cancelled bids are read-only - just show auction details
    debugPrint(
      '[BidsPage] _navigateToCancelledBid called with auctionId=${bid.auctionId}',
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LostBidDetailPage(auctionId: bid.auctionId),
      ),
    );
  }

  /// Error state widget with retry button
  Widget _buildErrorState() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: ColorConstants.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 40,
                color: ColorConstants.error,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Bids',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: widget.controller.loadUserBids,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}



/// Tab widget with badge showing count
/// Badge only appears when count > 0
class _TabWithBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _TabWithBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          // Show badge only when there are bids
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
