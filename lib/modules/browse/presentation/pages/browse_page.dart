import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../../lists/presentation/pages/active_listing_detail_page.dart';
import '../../../lists/presentation/pages/approved_listing_detail_page.dart';
import '../../../lists/domain/entities/listing_detail_entity.dart';
import '../../../lists/domain/entities/seller_listing_entity.dart';
import '../../../notifications/notifications_module.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../../data/datasources/auction_supabase_datasource.dart';
import '../../domain/entities/auction_detail_entity.dart';
import '../controllers/auction_detail_controller.dart';
import '../controllers/browse_controller.dart';
import '../widgets/auction_card.dart';
import '../widgets/auction_filter_sheet.dart';
import 'auction_detail_page.dart';

class BrowsePage extends StatefulWidget {
  final BrowseController controller;

  const BrowsePage({
    super.key,
    required this.controller,
  });

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final _searchController = TextEditingController();
  bool _isGridView = true; // Toggle between grid and list view

  BrowseController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _controller.loadAuctions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    _controller.updateSearchQuery(query);
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AuctionFilterSheet(
        initialFilter: _controller.currentFilter,
        onApply: (filter) {
          _controller.applyFilter(filter);
        },
      ),
    );
  }

  /// Build a filter chip with delete functionality
  Widget _buildFilterChip({
    required String label,
    required VoidCallback onDeleted,
  }) {
    return Chip(
      label: Text(label),
      onDeleted: onDeleted,
      deleteIcon: const Icon(Icons.close, size: 18),
    );
  }

  /// Convert AuctionDetailEntity to ListingDetailEntity for seller view
  ListingDetailEntity _convertAuctionToListingDetail(AuctionDetailEntity auction) {
    return ListingDetailEntity(
      id: auction.id,
      status: ListingStatus.active,
      startingPrice: auction.minimumBid,
      currentBid: auction.currentBid,
      reservePrice: auction.reservePrice,
      totalBids: auction.totalBids,
      watchersCount: auction.watchersCount,
      viewsCount: 0, // Not available in auction detail
      createdAt: DateTime.now(), // Not available in auction detail
      endTime: auction.endTime,
      winnerName: null,
      soldPrice: null,
      brand: auction.brand,
      model: auction.model,
      variant: auction.variant,
      year: auction.year,
      engineType: auction.engineType,
      engineDisplacement: auction.engineDisplacement,
      cylinderCount: auction.cylinderCount,
      horsepower: auction.horsepower,
      torque: auction.torque,
      transmission: auction.transmission,
      fuelType: auction.fuelType,
      driveType: auction.driveType,
      length: auction.length,
      width: auction.width,
      height: auction.height,
      wheelbase: auction.wheelbase,
      groundClearance: auction.groundClearance,
      seatingCapacity: auction.seatingCapacity,
      doorCount: auction.doorCount,
      fuelTankCapacity: auction.fuelTankCapacity,
      curbWeight: auction.curbWeight,
      grossWeight: auction.grossWeight,
      exteriorColor: auction.exteriorColor,
      paintType: auction.paintType,
      rimType: auction.rimType,
      rimSize: auction.rimSize,
      tireSize: auction.tireSize,
      tireBrand: auction.tireBrand,
      condition: auction.condition,
      mileage: auction.mileage,
      previousOwners: auction.previousOwners,
      hasModifications: auction.hasModifications,
      modificationsDetails: auction.modificationsDetails,
      hasWarranty: auction.hasWarranty,
      warrantyDetails: auction.warrantyDetails,
      usageType: auction.usageType,
      plateNumber: auction.plateNumber,
      orcrStatus: auction.orcrStatus,
      registrationStatus: auction.registrationStatus,
      registrationExpiry: auction.registrationExpiry,
      province: auction.province,
      cityMunicipality: auction.cityMunicipality,
      photoUrls: {
        'exterior': auction.photos.exterior,
        'interior': auction.photos.interior,
        'engine': auction.photos.engine,
        'details': auction.photos.details,
        'documents': auction.photos.documents,
      },
      description: auction.description,
      knownIssues: auction.knownIssues,
      features: auction.features,
      auctionEndDate: auction.endTime,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Browse Auctions'),
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          // Filter button with badge showing active filter count
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                onPressed: _openFilterSheet,
                tooltip: 'Filter',
              ),
              if (_controller.hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: ColorConstants.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_controller.activeFilterCount}',
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
          ),
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.loadAuctions(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _handleSearch,
              decoration: InputDecoration(
                hintText: 'Search cars by brand, model, color, location...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          _controller.updateSearchQuery('');
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark
                    ? ColorConstants.backgroundSecondaryDark
                    : ColorConstants.backgroundSecondaryLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          // Active filter chips
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (!_controller.hasActiveFilters) {
                return const SizedBox.shrink();
              }

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (_controller.currentFilter.make != null)
                      _buildFilterChip(
                        label: 'Brand: ${_controller.currentFilter.make}',
                        onDeleted: () => _controller.updateFilter(make: ''),
                      ),
                    if (_controller.currentFilter.model != null)
                      _buildFilterChip(
                        label: 'Model: ${_controller.currentFilter.model}',
                        onDeleted: () => _controller.updateFilter(model: ''),
                      ),
                    if (_controller.currentFilter.yearFrom != null || _controller.currentFilter.yearTo != null)
                      _buildFilterChip(
                        label: 'Year: ${_controller.currentFilter.yearFrom ?? ''}-${_controller.currentFilter.yearTo ?? ''}',
                        onDeleted: () => _controller.updateFilter(yearFrom: null, yearTo: null),
                      ),
                    if (_controller.currentFilter.priceMin != null || _controller.currentFilter.priceMax != null)
                      _buildFilterChip(
                        label: 'Price: ₱${_controller.currentFilter.priceMin ?? 0} - ₱${_controller.currentFilter.priceMax ?? '∞'}',
                        onDeleted: () => _controller.updateFilter(priceMin: null, priceMax: null),
                      ),
                    if (_controller.currentFilter.transmission != null)
                      _buildFilterChip(
                        label: _controller.currentFilter.transmission!,
                        onDeleted: () => _controller.updateFilter(transmission: ''),
                      ),
                    if (_controller.currentFilter.fuelType != null)
                      _buildFilterChip(
                        label: _controller.currentFilter.fuelType!,
                        onDeleted: () => _controller.updateFilter(fuelType: ''),
                      ),
                    if (_controller.currentFilter.driveType != null)
                      _buildFilterChip(
                        label: _controller.currentFilter.driveType!,
                        onDeleted: () => _controller.updateFilter(driveType: ''),
                      ),
                    if (_controller.currentFilter.condition != null)
                      _buildFilterChip(
                        label: _controller.currentFilter.condition!,
                        onDeleted: () => _controller.updateFilter(condition: ''),
                      ),
                    if (_controller.currentFilter.exteriorColor != null)
                      _buildFilterChip(
                        label: _controller.currentFilter.exteriorColor!,
                        onDeleted: () => _controller.updateFilter(exteriorColor: ''),
                      ),
                    if (_controller.currentFilter.province != null)
                      _buildFilterChip(
                        label: _controller.currentFilter.province!,
                        onDeleted: () => _controller.updateFilter(province: ''),
                      ),
                    if (_controller.currentFilter.maxMileage != null)
                      _buildFilterChip(
                        label: 'Max ${_controller.currentFilter.maxMileage}km',
                        onDeleted: () => _controller.updateFilter(maxMileage: null),
                      ),
                    if (_controller.currentFilter.endingSoon == true)
                      _buildFilterChip(
                        label: 'Ending Soon',
                        onDeleted: () => _controller.updateFilter(endingSoon: false),
                      ),
                    // Clear all button
                    ActionChip(
                      label: const Text('Clear All'),
                      avatar: const Icon(Icons.clear_all, size: 18),
                      onPressed: _controller.clearFilters,
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (_controller.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: ColorConstants.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _controller.errorMessage!,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _controller.loadAuctions,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (_controller.auctions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No auctions found',
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _controller.loadAuctions,
                  child: _isGridView
                      ? GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _controller.auctions.length,
                          itemBuilder: (context, index) {
                            final auction = _controller.auctions[index];
                            return AuctionCard(
                              auction: auction,
                              onTap: () async {
                          // Check if user is trying to bid on their own listing
                          final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
                          if (currentUserId != null && currentUserId == auction.sellerId) {
                            // User is the seller - show loading and navigate to seller view
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(child: CircularProgressIndicator()),
                            );

                            try {
                              // Fetch the full auction detail from the database
                              final datasource = AuctionSupabaseDataSource(SupabaseConfig.client);
                              final auctionDetail = await datasource.getAuctionDetail(auction.id, currentUserId);

                              if (!context.mounted) return;
                              Navigator.pop(context); // Close loading

                              // Show notification
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('This is your listing! Opening in seller view...'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: ColorConstants.info,
                                ),
                              );

                              // Convert AuctionDetailEntity to ListingDetailEntity for seller view
                              final listingDetail = _convertAuctionToListingDetail(auctionDetail);

                              // Navigate to active listing detail page (seller view)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActiveListingDetailPage(listing: listingDetail),
                                ),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              Navigator.pop(context); // Close loading

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to load listing: $e'),
                                  backgroundColor: ColorConstants.error,
                                ),
                              );
                            }
                          } else {
                            // Not the seller - proceed to auction detail
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AuctionDetailPage(
                                  auctionId: auction.id,
                                  controller: GetIt.instance<AuctionDetailController>(),
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _controller.auctions.length,
                          itemBuilder: (context, index) {
                            final auction = _controller.auctions[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AuctionCard(
                                auction: auction,
                                onTap: () async {
                                  // Check if user is trying to bid on their own listing
                                  final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
                                  if (currentUserId != null && currentUserId == auction.sellerId) {
                                    // User is the seller - show loading and navigate to seller view
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator()),
                                    );

                                    try {
                                      // Fetch the full auction detail from the database
                                      final datasource = AuctionSupabaseDataSource(SupabaseConfig.client);
                                      final auctionDetail = await datasource.getAuctionDetail(auction.id, currentUserId);

                                      if (!context.mounted) return;
                                      Navigator.pop(context); // Close loading

                                      // Show notification
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('This is your listing! Opening in seller view...'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: ColorConstants.info,
                                        ),
                                      );

                                      // Navigate to seller view
                                      final listing = _convertAuctionToListingDetail(auctionDetail);
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ApprovedListingDetailPage(listing: listing),
                                        ),
                                      );
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      Navigator.pop(context); // Close loading
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: ColorConstants.error,
                                        ),
                                      );
                                    }
                                  } else {
                                    // User is a bidder - navigate to bidding view
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AuctionDetailPage(
                                          auctionId: auction.id,
                                          controller: GetIt.instance<AuctionDetailController>(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
