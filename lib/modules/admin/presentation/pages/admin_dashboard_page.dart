import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../controllers/admin_controller.dart';
import 'admin_listing_review_page.dart';

/// Admin dashboard with stats and pending listings
class AdminDashboardPage extends StatefulWidget {
  final AdminController controller;

  const AdminDashboardPage({
    super.key,
    required this.controller,
  });

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 24),
            SizedBox(width: 8),
            Text('Admin Dashboard'),
          ],
        ),
        backgroundColor: ColorConstants.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => widget.controller.refresh(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.controller,
        builder: (context, _) {
          if (widget.controller.isLoading && widget.controller.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading dashboard',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

          final stats = widget.controller.stats;
          final pendingListings = widget.controller.pendingListings;

          return RefreshIndicator(
            onRefresh: widget.controller.refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Stats Cards
                if (stats != null) ...[
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatsGrid(stats),
                  const SizedBox(height: 32),
                ],

                // Pending Listings
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pending Review',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to all listings page
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (pendingListings.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 64,
                            color: ColorConstants.success,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No pending listings',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'All listings have been reviewed',
                            style: TextStyle(color: ColorConstants.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...pendingListings.map((listing) => _buildListingCard(context, listing)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(dynamic stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Pending Review',
          stats.pendingListings.toString(),
          Icons.pending_actions,
          ColorConstants.warning,
        ),
        _buildStatCard(
          'Active Listings',
          stats.activeListings.toString(),
          Icons.check_circle,
          ColorConstants.success,
        ),
        _buildStatCard(
          'Total Listings',
          stats.totalListings.toString(),
          Icons.list_alt,
          ColorConstants.info,
        ),
        _buildStatCard(
          'Today',
          stats.todaySubmissions.toString(),
          Icons.today,
          ColorConstants.primary,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: ColorConstants.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListingCard(BuildContext context, dynamic listing) {
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
}
