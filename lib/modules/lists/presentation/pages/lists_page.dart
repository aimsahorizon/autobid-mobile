import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/config/supabase_config.dart';
import '../../../notifications/notifications_module.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../controllers/lists_controller.dart';
import '../widgets/listings_grid.dart';
import '../../lists_module.dart';
import 'create_listing_page.dart';

class ListsPage extends StatefulWidget {
  final ListsController? controller;

  const ListsPage({
    super.key,
    this.controller,
  });

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ListingStatus.active,
    ListingStatus.pending,
    ListingStatus.approved,
    ListingStatus.ended,
    ListingStatus.draft,
    ListingStatus.cancelled,
  ];

  // Get controller from module directly to handle toggling
  ListsController get _controller => ListsModule.controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _controller.loadListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToCreateListing(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create a listing')),
      );
      return;
    }

    final controller = ListsModule.createListingDraftController();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateListingPage(
          controller: controller,
          sellerId: userId,
        ),
      ),
    ).then((result) {
      _controller.loadListings();

      // Navigate to Pending tab if submission was successful
      if (result is Map && result['success'] == true && result['navigateTo'] == 'pending') {
        _tabController.animateTo(1); // Index 1 is Pending tab
      }
    });
  }

  void _toggleDemoMode(BuildContext context) {
    final wasUsingMock = ListsModule.useMockData;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Switch Data Source'),
        content: Text(
          wasUsingMock
              ? 'Switch to Supabase database?\n\nThis will show real data from your backend.'
              : 'Switch to mock data?\n\nThis will show demo data for testing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Toggle mode - this disposes old controller and creates new one
              ListsModule.toggleDemoMode();

              // Trigger rebuild and load data from new controller
              setState(() {
                _controller.loadListings();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ListsModule.useMockData
                        ? 'Switched to mock data'
                        : 'Switched to database',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Switch'),
          ),
        ],
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
        title: const Text('My Listings'),
        actions: [
          // Notification bell with unread count badge
          ListenableBuilder(
            listenable: NotificationsModule.instance.controller,
            builder: (context, _) {
              final notificationController = NotificationsModule.instance.controller;
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
            onPressed: () => _controller.loadListings(),
            tooltip: 'Refresh',
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => IconButton(
              icon: Icon(
                _controller.isGridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: _controller.toggleViewMode,
              tooltip: _controller.isGridView ? 'List view' : 'Grid view',
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'toggle_demo') {
                _toggleDemoMode(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'toggle_demo',
                child: Row(
                  children: [
                    Icon(
                      ListsModule.useMockData
                          ? Icons.cloud_outlined
                          : Icons.storage_outlined,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      ListsModule.useMockData
                          ? 'Switch to Database'
                          : 'Switch to Mock Data',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              labelColor: ColorConstants.primary,
              unselectedLabelColor: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: _tabs.map((status) => _TabWithBadge(
                label: status.tabLabel,
                count: _controller.getCountByStatus(status),
                color: _getStatusColor(status),
              )).toList(),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((status) {
              final needsController = status == ListingStatus.draft || status == ListingStatus.cancelled;
              final needsSellerId = needsController;
              final userId = SupabaseConfig.client.auth.currentUser?.id;

              return ListingsGrid(
                listings: _controller.getListingsByStatus(status),
                isGridView: _controller.isGridView,
                isLoading: _controller.isLoading,
                emptyTitle: _getEmptyTitle(status),
                emptySubtitle: _getEmptySubtitle(status),
                emptyIcon: _getEmptyIcon(status),
                enableNavigation: true,
                draftController: needsController ? ListsModule.createListingDraftController() : null,
                sellerId: needsSellerId ? userId : null,
                onListingUpdated: () => _controller.loadListings(),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateListing(context),
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return ColorConstants.success;
      case ListingStatus.pending:
        return ColorConstants.warning;
      case ListingStatus.approved:
        return ColorConstants.info;
      case ListingStatus.ended:
        return ColorConstants.primary;
      case ListingStatus.draft:
        return ColorConstants.textSecondaryLight;
      case ListingStatus.cancelled:
        return ColorConstants.error;
    }
  }

  String _getEmptyTitle(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return 'No active listings';
      case ListingStatus.pending:
        return 'No pending listings';
      case ListingStatus.approved:
        return 'No approved listings';
      case ListingStatus.ended:
        return 'No ended auctions';
      case ListingStatus.draft:
        return 'No drafts';
      case ListingStatus.cancelled:
        return 'No cancelled listings';
    }
  }

  String _getEmptySubtitle(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return 'Your live auctions will appear here';
      case ListingStatus.pending:
        return 'Listings awaiting review will appear here';
      case ListingStatus.approved:
        return 'Approved listings ready to publish will appear here';
      case ListingStatus.ended:
        return 'Auctions awaiting your decision will appear here';
      case ListingStatus.draft:
        return 'Your saved drafts will appear here';
      case ListingStatus.cancelled:
        return 'Cancelled listings will appear here';
    }
  }

  IconData _getEmptyIcon(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return Icons.local_offer_outlined;
      case ListingStatus.pending:
        return Icons.hourglass_empty;
      case ListingStatus.approved:
        return Icons.check_circle_outline;
      case ListingStatus.ended:
        return Icons.flag_outlined;
      case ListingStatus.draft:
        return Icons.edit_note;
      case ListingStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}

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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
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
