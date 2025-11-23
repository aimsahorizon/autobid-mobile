import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/seller_listing_entity.dart';
import '../controllers/lists_controller.dart';
import '../widgets/listings_grid.dart';

class ListsPage extends StatefulWidget {
  final ListsController controller;

  const ListsPage({
    super.key,
    required this.controller,
  });

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    ListingStatus.active,
    ListingStatus.pending,
    ListingStatus.inTransaction,
    ListingStatus.draft,
    ListingStatus.sold,
    ListingStatus.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    widget.controller.loadListings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Listings'),
        actions: [
          ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) => IconButton(
              icon: Icon(
                widget.controller.isGridView
                    ? Icons.view_list_rounded
                    : Icons.grid_view_rounded,
              ),
              onPressed: widget.controller.toggleViewMode,
              tooltip: widget.controller.isGridView ? 'List view' : 'Grid view',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: ListenableBuilder(
            listenable: widget.controller,
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
                count: widget.controller.getCountByStatus(status),
                color: _getStatusColor(status),
              )).toList(),
            ),
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: _tabs.map((status) => ListingsGrid(
              listings: widget.controller.getListingsByStatus(status),
              isGridView: widget.controller.isGridView,
              isLoading: widget.controller.isLoading,
              emptyTitle: _getEmptyTitle(status),
              emptySubtitle: _getEmptySubtitle(status),
              emptyIcon: _getEmptyIcon(status),
            )).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New Listing'),
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return ColorConstants.success;
      case ListingStatus.pending:
        return ColorConstants.warning;
      case ListingStatus.inTransaction:
        return ColorConstants.primary;
      case ListingStatus.draft:
        return ColorConstants.textSecondaryLight;
      case ListingStatus.sold:
        return ColorConstants.info;
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
      case ListingStatus.inTransaction:
        return 'No transactions';
      case ListingStatus.draft:
        return 'No drafts';
      case ListingStatus.sold:
        return 'No sold listings';
      case ListingStatus.cancelled:
        return 'No cancelled listings';
    }
  }

  String _getEmptySubtitle(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return 'Your approved listings will appear here';
      case ListingStatus.pending:
        return 'Listings awaiting review will appear here';
      case ListingStatus.inTransaction:
        return 'Listings in buyer discussion will appear here';
      case ListingStatus.draft:
        return 'Your saved drafts will appear here';
      case ListingStatus.sold:
        return 'Successfully sold listings will appear here';
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
      case ListingStatus.inTransaction:
        return Icons.handshake_outlined;
      case ListingStatus.draft:
        return Icons.edit_note;
      case ListingStatus.sold:
        return Icons.sell_outlined;
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
