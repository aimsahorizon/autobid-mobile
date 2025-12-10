import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/admin_listing_entity.dart';
import '../controllers/admin_controller.dart';
import 'admin_listing_review_page.dart';

/// Admin page for managing all listings by status
class AdminListingsPage extends StatefulWidget {
  final AdminController controller;

  const AdminListingsPage({super.key, required this.controller});

  @override
  State<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends State<AdminListingsPage>
    with AutomaticKeepAliveClientMixin {
  final List<String> _statusFilters = [
    'all',
    'pending_approval',
    'scheduled',
    'live',
    'ended',
    'cancelled',
    'in_transaction',
    'sold',
    'deal_failed',
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Load all listings initially
    widget.controller.loadListingsByStatus('pending_approval');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // Status Filter Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: ColorConstants.surfaceVariantLight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                return Row(
                  children: _statusFilters.map((status) {
                    final isSelected =
                        widget.controller.selectedStatus == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_formatStatusName(status)),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            widget.controller.loadListingsByStatus(status);
                          }
                        },
                        backgroundColor: Colors.white,
                        selectedColor: ColorConstants.primary.withValues(
                          alpha: 0.2,
                        ),
                        checkmarkColor: ColorConstants.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? ColorConstants.primary
                              : ColorConstants.textPrimaryLight,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),

        // Listings List
        Expanded(
          child: ListenableBuilder(
            listenable: widget.controller,
            builder: (context, _) {
              if (widget.controller.isLoading &&
                  widget.controller.allListings.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (widget.controller.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: ColorConstants.error,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error loading listings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.controller.error!),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () => widget.controller.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final listings = widget.controller.allListings;

              if (listings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No listings found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No listings with status: ${_formatStatusName(widget.controller.selectedStatus)}',
                        style: TextStyle(
                          color: ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: widget.controller.refresh,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listings.length,
                  itemBuilder: (context, index) {
                    return _buildListingCard(context, listings[index]);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatStatusName(String status) {
    if (status == 'all') return 'All';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  Widget _buildListingCard(BuildContext context, AdminListingEntity listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: listing.coverPhotoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  listing.coverPhotoUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    color: ColorConstants.surfaceVariantLight,
                    child: const Icon(Icons.directions_car),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: ColorConstants.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car),
              ),
        title: Text(
          listing.carName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('by ${listing.sellerName}'),
            Text('₱${listing.startingPrice.toStringAsFixed(0)}'),
            const SizedBox(height: 4),
            _buildStatusBadge(listing.status),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminListingReviewPage(
                listing: listing,
                controller: widget.controller,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        _formatStatusName(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending_approval':
        return ColorConstants.warning;
      case 'scheduled':
        return ColorConstants.info;
      case 'live':
        return ColorConstants.success;
      case 'ended':
        return ColorConstants.primary;
      case 'cancelled':
      case 'deal_failed':
        return ColorConstants.error;
      case 'in_transaction':
        return Colors.orange;
      case 'sold':
        return Colors.green;
      default:
        return ColorConstants.textSecondaryLight;
    }
  }
}
