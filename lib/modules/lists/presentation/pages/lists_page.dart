import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/app/di/app_module.dart';
import '../../../notifications/presentation/controllers/notification_controller.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../controllers/lists_controller.dart';
import '../controllers/listing_draft_controller.dart';
import '../widgets/listings_grid.dart';
import '../widgets/invite_management_dialog.dart';
import 'create_listing_page.dart';

class ListsPage extends StatefulWidget {
  final ListsController? controller;

  const ListsPage({super.key, this.controller});

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  static const _currentTabs = [
    ListingStatus.active,
    ListingStatus.pending,
    ListingStatus.approved,
    ListingStatus.scheduled,
    ListingStatus.draft,
  ];

  static const _allTabs = [
    ListingStatus.active,
    ListingStatus.pending,
    ListingStatus.approved,
    ListingStatus.scheduled,
    ListingStatus.ended,
    ListingStatus.sold,
    ListingStatus.dealFailed,
    ListingStatus.draft,
    ListingStatus.cancelled,
  ];

  List<ListingStatus> get _tabs =>
      _controller.showAll ? _allTabs : _currentTabs;

  bool _lastShowAll = false;

  @override
  void initState() {
    super.initState();
    // Initialize controller listener
    _controller.addListener(_onControllerChanged);
    _lastShowAll = _controller.showAll;
    
    _tabController = TabController(length: _tabs.length, vsync: this);
    _controller.loadListings();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (_controller.showAll != _lastShowAll) {
      _lastShowAll = _controller.showAll;
      _recreateTabController();
    }
  }

  void _recreateTabController() {
    final newIndex = 0; // Reset to first tab when toggling views for simplicity
    _tabController.dispose();
    _tabController = TabController(
      length: _tabs.length,
      initialIndex: newIndex,
      vsync: this,
    );
    if (mounted) setState(() {});
  }

  ListsController get _controller => widget.controller ?? sl<ListsController>();

  void _navigateToCreateListing(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to create a listing')),
      );
      return;
    }

    final controller = sl<ListingDraftController>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateListingPage(controller: controller, sellerId: userId),
      ),
    ).then((result) {
      _controller.loadListings();

      // Navigate to Pending tab if submission was successful
      if (result is Map &&
          result['success'] == true &&
          result['navigateTo'] == 'pending') {
        _tabController.animateTo(1); // Index 1 is Pending tab
      }
    });
  }

  Future<void> _confirmDelete() async {
    final count = _controller.selectedCount;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count items?'),
        content: const Text(
          'Are you sure you want to delete the selected items? '
          'Active listings will be cancelled, drafts and ended listings will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteSelected();
    }
  }

  void _showInviteManagement(SellerListingEntity listing) {
    showDialog(
      context: context,
      builder: (context) => InviteManagementDialog(
        controller: _controller,
        auctionId: listing.id,
        carName: listing.carName,
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
        leading: _controller.isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _controller.clearSelection,
              )
            : null,
        title: _controller.isSelectionMode
            ? Text('${_controller.selectedCount} Selected')
            : const Text('My Listings'),
        actions: _controller.isSelectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                  onPressed: _confirmDelete,
                  tooltip: 'Delete Selected',
                ),
              ]
            : [
                // Notification bell with unread count badge
          ListenableBuilder(
            listenable: sl<NotificationController>(),
            builder: (context, _) {
              final notificationController = sl<NotificationController>();
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
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    _controller.showAll
                        ? Icons.filter_list_off
                        : Icons.filter_list,
                  ),
                  onPressed: _controller.toggleShowAll,
                  tooltip: _controller.showAll ? 'Show Current' : 'Show All',
                ),
                IconButton(
                  icon: Icon(
                    _controller.isGridView
                        ? Icons.view_list_rounded
                        : Icons.grid_view_rounded,
                  ),
                  onPressed: _controller.toggleViewMode,
                  tooltip: _controller.isGridView ? 'List view' : 'Grid view',
                ),
              ],
            ),
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
              tabs: _tabs
                  .map(
                    (status) => _TabWithBadge(
                      label: status.tabLabel,
                      count: _controller.getCountByStatus(status),
                      color: _getStatusColor(status),
                    ),
                  )
                  .toList(),
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

          return RefreshIndicator(
            onRefresh: () => _controller.loadListings(),
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((status) {
              final needsController =
                  status == ListingStatus.draft ||
                  status == ListingStatus.cancelled;
              final needsSellerId = needsController;
              final userId = SupabaseConfig.client.auth.currentUser?.id;

              return ListingsGrid(
                listings: _controller.getListingsByStatus(status),
                isGridView: _controller.isGridView,
                isLoading: _controller.isLoading,
                emptyTitle: _getEmptyTitle(status),
                emptySubtitle: _getEmptySubtitle(status),
                emptyIcon: _getEmptyIcon(status),
                enableNavigation: !_controller.isSelectionMode,
                draftController: needsController
                    ? sl<ListingDraftController>()
                    : null,
                sellerId: needsSellerId ? userId : null,
                onListingUpdated: () => _controller.loadListings(),
                isSelectionMode: _controller.isSelectionMode,
                selectedIds: _controller.selectedListingIds,
                onSelectionToggle: _controller.toggleSelection,
                onInviteTap: _showInviteManagement,
              );
            }).toList(),
            ),
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
      case ListingStatus.scheduled:
        return Colors.purple;
      case ListingStatus.ended:
        return ColorConstants.primary;
      case ListingStatus.draft:
        return ColorConstants.textSecondaryLight;
      case ListingStatus.cancelled:
        return ColorConstants.error;
      case ListingStatus.inTransaction:
        return ColorConstants.info;
      case ListingStatus.sold:
        return ColorConstants.success;
      case ListingStatus.dealFailed:
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
      case ListingStatus.scheduled:
        return 'No scheduled listings';
      case ListingStatus.ended:
        return 'No ended auctions';
      case ListingStatus.draft:
        return 'No drafts';
      case ListingStatus.cancelled:
        return 'No cancelled listings';
      case ListingStatus.inTransaction:
        return 'No active transactions';
      case ListingStatus.sold:
        return 'No sold listings';
      case ListingStatus.dealFailed:
        return 'No failed transactions';
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
      case ListingStatus.scheduled:
        return 'Scheduled auctions will appear here';
      case ListingStatus.ended:
        return 'Auctions awaiting your decision will appear here';
      case ListingStatus.draft:
        return 'Your saved drafts will appear here';
      case ListingStatus.cancelled:
        return 'Cancelled listings will appear here';
      case ListingStatus.inTransaction:
        return 'Active negotiations will appear here';
      case ListingStatus.sold:
        return 'Successfully sold listings will appear here';
      case ListingStatus.dealFailed:
        return 'Cancelled transactions will appear here';
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
      case ListingStatus.scheduled:
        return Icons.schedule;
      case ListingStatus.ended:
        return Icons.flag_outlined;
      case ListingStatus.draft:
        return Icons.edit_note;
      case ListingStatus.cancelled:
        return Icons.cancel_outlined;
      case ListingStatus.inTransaction:
        return Icons.handshake_outlined;
      case ListingStatus.sold:
        return Icons.check_circle_outline;
      case ListingStatus.dealFailed:
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
                count.toString(),
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