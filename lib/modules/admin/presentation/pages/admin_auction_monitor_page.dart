import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../browse/data/datasources/qa_supabase_datasource.dart';
import '../../../browse/domain/entities/qa_entity.dart';
import '../../domain/entities/auction_monitor_entity.dart';
import '../controllers/auction_monitor_controller.dart';

/// Admin page for monitoring live auctions, bid activity, and Q&A.
class AuctionMonitorPage extends StatefulWidget {
  final AuctionMonitorController controller;

  const AuctionMonitorPage({super.key, required this.controller});

  @override
  State<AuctionMonitorPage> createState() => _AuctionMonitorPageState();
}

class _AuctionMonitorPageState extends State<AuctionMonitorPage> {
  final TextEditingController _searchController = TextEditingController();
  late final QASupabaseDataSource _qaDataSource;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    widget.controller.init();
    widget.controller.addListener(_onControllerUpdate);
    _qaDataSource = QASupabaseDataSource(Supabase.instance.client);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (widget.controller.isLoading && widget.controller.auctions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.controller.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ColorConstants.error),
            const SizedBox(height: 16),
            const Text(
              'Failed to load auctions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.errorMessage ?? 'Unknown error',
              style: TextStyle(color: ColorConstants.textSecondaryLight),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: widget.controller.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredAuctions = widget.controller.searchAuctions(_searchQuery);
    final stats = widget.controller.getStatistics();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: isDark ? ColorConstants.surfaceDark : Colors.grey.shade50,
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatCard(
                    'Active Auctions',
                    '${stats['totalActive']}',
                    Icons.gavel,
                    ColorConstants.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Ending Soon',
                    '${stats['endingSoon']}',
                    Icons.access_time,
                    Colors.orange,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'High Activity',
                    '${stats['highActivity']}',
                    Icons.trending_up,
                    Colors.red,
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    'Total Bids',
                    '${stats['totalBids']}',
                    Icons.shopping_cart,
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search auctions by title, vehicle, or seller...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? ColorConstants.surfaceLight
                      : Colors.white,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredAuctions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isEmpty
                            ? Icons.gavel_outlined
                            : Icons.search_off,
                        size: 64,
                        color: ColorConstants.textSecondaryLight,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No live auctions'
                            : 'No auctions found',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'There are currently no active auctions to monitor'
                            : 'Try a different search term',
                        style: TextStyle(
                          color: ColorConstants.textSecondaryLight,
                        ),
                      ),
                      if (_searchQuery.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: ElevatedButton.icon(
                            onPressed: widget.controller.refresh,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAuctions.length,
                  itemBuilder: (context, index) {
                    final auction = filteredAuctions[index];
                    return _buildAuctionCard(auction, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionCard(AuctionMonitorEntity auction, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showAuctionDetail(auction),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (auction.primaryImageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        auction.primaryImageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.directions_car, size: 40),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.directions_car, size: 40),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                auction.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (auction.isFinalTwoMinutes)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'ENDING SOON',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${auction.vehicleYear} ${auction.vehicleMake} ${auction.vehicleModel}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 14,
                              color: isDark
                                  ? ColorConstants.textSecondaryDark
                                  : ColorConstants.textSecondaryLight,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              auction.sellerName,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? ColorConstants.textSecondaryDark
                                    : ColorConstants.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _buildInfoChip(
                    Icons.gavel,
                    '${auction.totalBids} bids',
                    ColorConstants.primary,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.access_time,
                    _formatTimeRemaining(auction.minutesRemaining),
                    auction.isFinalTwoMinutes ? Colors.red : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _buildInfoChip(
                    Icons.trending_up,
                    auction.activityLevel,
                    _getActivityColor(auction.activityLevel),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Bid',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                      Text(
                        _formatCurrency(auction.currentPrice),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ],
                  ),
                  if (auction.latestBidderName != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Latest Bidder',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? ColorConstants.textSecondaryDark
                                : ColorConstants.textSecondaryLight,
                          ),
                        ),
                        Text(
                          auction.latestBidderName!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String level) {
    switch (level) {
      case 'Very High':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Moderate':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimeRemaining(int minutes) {
    if (minutes <= 0) return 'Ended';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    if (hours < 24) return '${hours}h';
    final days = hours ~/ 24;
    return '${days}d';
  }

  String _formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(parts[i]);
    }
    return '₱$buffer';
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[timestamp.month - 1];
    final hour = timestamp.hour == 0
        ? 12
        : (timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour);
    final amPm = timestamp.hour >= 12 ? 'PM' : 'AM';
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$month ${timestamp.day}, $hour:$minute $amPm';
  }

  void _showAuctionDetail(AuctionMonitorEntity auction) {
    widget.controller.selectAuction(auction.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auction.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Bid History',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorConstants.textSecondaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          widget.controller.deselectAuction();
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListenableBuilder(
                    listenable: widget.controller,
                    builder: (context, _) {
                      final bids = widget.controller.selectedAuctionBids;
                      final uniqueBidders = bids
                          .map((b) => b.bidderId)
                          .toSet()
                          .length;
                      final timeRemaining = _formatTimeRemaining(
                        auction.minutesRemaining,
                      );

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Row(
                            children: [
                              _buildMetaChip(
                                icon: Icons.timer,
                                label: 'Time Left',
                                value: timeRemaining,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              _buildMetaChip(
                                icon: Icons.people_alt_outlined,
                                label: 'Bidders',
                                value: uniqueBidders.toString(),
                                color: Colors.teal,
                              ),
                              const SizedBox(width: 8),
                              _buildMetaChip(
                                icon: Icons.gavel,
                                label: 'Total Bids',
                                value: auction.totalBids.toString(),
                                color: Colors.indigo,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Bid History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (bids.isEmpty)
                            const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: Text('No bids yet')),
                              ),
                            )
                          else
                            ...bids.map((bid) {
                              final timeAgo = _formatTimeAgo(bid.timestamp);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: ColorConstants.primary
                                        .withOpacity(0.2),
                                    child: Text(
                                      bid.bidderName.isNotEmpty
                                          ? bid.bidderName[0].toUpperCase()
                                          : '?',
                                      style: const TextStyle(
                                        color: ColorConstants.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          bid.bidderName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (bid.isAutoBid)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: const Text(
                                            'Auto-bid',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    '$timeAgo • ${_formatCurrency(bid.amount)}',
                                  ),
                                ),
                              );
                            }),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Q&A (Admin View)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAdminQASection(auction.id),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminQASection(String auctionId) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return StreamBuilder<List<QAEntity>>(
      stream: _qaDataSource.subscribeToQA(
        auctionId,
        currentUserId: currentUserId,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No questions yet')),
            ),
          );
        }

        return Column(
          children: items.map((qa) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            qa.question,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: qa.isAnswered
                                ? Colors.green.withOpacity(0.12)
                                : Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            qa.isAnswered ? 'Answered' : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: qa.isAnswered
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Asked by ${qa.askedBy} • ${_formatTimeAgo(qa.askedAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorConstants.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (qa.answers.isEmpty)
                      Text(
                        'No answers yet',
                        style: TextStyle(
                          fontSize: 12,
                          color: ColorConstants.textSecondaryLight,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: qa.answers.asMap().entries.map((entry) {
                          final answer = entry.value;
                          final idx = entry.key + 1;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blueGrey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Ans $idx',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        answer.answer,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatTimeAgo(answer.createdAt),
                                        style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              ColorConstants.textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
