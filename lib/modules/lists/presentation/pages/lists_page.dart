import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import 'package:autobid_mobile/app/di/app_module.dart';
import '../../../notifications/presentation/widgets/notification_bell_widget.dart';
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  static const _currentTabs = [
    null, // "All" tab
    ListingStatus.active,
    ListingStatus.pending,
    ListingStatus.rejected,
    ListingStatus.approved,
    ListingStatus.scheduled,
    ListingStatus.ended,
    ListingStatus.draft,
    ListingStatus.cancelled,
  ];

  List<ListingStatus?> get _tabs => _currentTabs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_onControllerChanged);

    _tabController = TabController(length: _tabs.length, vsync: this);
    _controller.loadListings();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.loadListings(isBackground: true);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  ListsController get _controller => widget.controller ?? sl<ListsController>();

  List<SellerListingEntity> _getAllListings() {
    final all = _controller.listings.values.expand((l) => l).toList();
    all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  void _navigateToCreateListing(BuildContext context) {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
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
      // Force reload to ensure new listing appears immediately
      _controller.loadListings();

      // Navigate to Pending tab if submission was successful
      if (result is Map &&
          result['success'] == true &&
          result['navigateTo'] == 'pending') {
        _tabController.animateTo(
          2,
        ); // Index 2 is Pending tab (after All, Active)
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
    // Safety check for hot-reload or dynamic tab changes
    if (_tabController.length != _tabs.length) {
      _tabController.dispose();
      _tabController = TabController(length: _tabs.length, vsync: this);
    }

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
                const NotificationBellWidget(),
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
              ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              return Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? ColorConstants.backgroundDark
                      : ColorConstants.backgroundSecondaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
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
                  tabs: _tabs.map((status) {
                    if (status == null) {
                      final allCount = _controller.listings.values
                          .expand((l) => l)
                          .length;
                      return _TabWithBadge(
                        label: 'All',
                        count: allCount,
                        color: ColorConstants.primary,
                      );
                    }
                    return _TabWithBadge(
                      label: status.tabLabel,
                      count: _controller.getCountByStatus(status),
                      color: _getStatusColor(status),
                    );
                  }).toList(),
                ),
              );
            },
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
                if (status == null) {
                  return _buildUnifiedView();
                }
                return _buildGridForStatus(status);
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

  Widget _buildUnifiedView() {
    final listings = _getAllListings();
    final userId = SupabaseConfig.client.auth.currentUser?.id;

    return ListingsGrid(
      listings: listings,
      isGridView: _controller.isGridView,
      isLoading: _controller.isLoading,
      emptyTitle: 'No listings found',
      emptySubtitle: 'Try changing the filter or add a new listing',
      emptyIcon: Icons.filter_alt_off,
      enableNavigation: !_controller.isSelectionMode,
      // Pass controller/sellerId if needed for actions, though they might not apply to all types
      draftController: sl<ListingDraftController>(),
      sellerId: userId,
      isSelectionMode: _controller.isSelectionMode,
      selectedIds: _controller.selectedListingIds,
      onSelectionToggle: _controller.toggleSelection,
      onInviteTap: _showInviteManagement,
    );
  }

  Widget _buildGridForStatus(ListingStatus status) {
    final needsController =
        status == ListingStatus.draft ||
        status == ListingStatus.cancelled ||
        status == ListingStatus.rejected;
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
      draftController: needsController ? sl<ListingDraftController>() : null,
      sellerId: needsSellerId ? userId : null,
      isSelectionMode: _controller.isSelectionMode,
      selectedIds: _controller.selectedListingIds,
      onSelectionToggle: _controller.toggleSelection,
      onInviteTap: _showInviteManagement,
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
      case ListingStatus.rejected:
        return Colors.deepOrange;
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
      case ListingStatus.rejected:
        return 'No rejected listings';
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
      case ListingStatus.rejected:
        return 'Listings rejected by admin will appear here';
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
      case ListingStatus.rejected:
        return Icons.block;
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
