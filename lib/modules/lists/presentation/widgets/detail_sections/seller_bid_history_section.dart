import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/widgets/user_profile_bottom_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/profile_supabase_datasource.dart';
import 'package:autobid_mobile/modules/profile/data/models/user_profile_model.dart';
import 'package:intl/intl.dart';

class SellerBidHistorySection extends StatefulWidget {
  final List<Map<String, dynamic>> bids;
  final bool isLoading;

  const SellerBidHistorySection({
    super.key,
    required this.bids,
    this.isLoading = false,
  });

  @override
  State<SellerBidHistorySection> createState() =>
      _SellerBidHistorySectionState();
}

class _SellerBidHistorySectionState extends State<SellerBidHistorySection> {
  final Map<String, UserProfileModel?> _bidderStats = {};

  @override
  void initState() {
    super.initState();
    _loadBidderStats();
  }

  @override
  void didUpdateWidget(SellerBidHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bids != widget.bids) _loadBidderStats();
  }

  Future<void> _loadBidderStats() async {
    final ds = ProfileSupabaseDataSource(Supabase.instance.client);
    for (final bid in widget.bids) {
      final userId = bid['user_id'] as String?;
      if (userId != null && !_bidderStats.containsKey(userId)) {
        final stats = await ds.getUserBiddingStats(userId);
        if (mounted) setState(() => _bidderStats[userId] = stats);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bid History',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.bids.isNotEmpty)
                Text(
                  '${widget.bids.length} Bids',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (widget.bids.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'No bids yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: widget.bids.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final bid = widget.bids[index];
                  final amount = (bid['bid_amount'] as num).toDouble();
                  final createdAt = DateTime.parse(bid['created_at']);
                  final profile = bid['user_profiles'] as Map<String, dynamic>?;
                  final bidderId = bid['user_id'] as String?;
                  final bidderName =
                      profile?['username'] ??
                      profile?['full_name'] ??
                      'Unknown Bidder';
                  final stats = bidderId != null
                      ? _bidderStats[bidderId]
                      : null;

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: bidderId != null
                        ? () => UserProfileBottomSheet.show(
                            context,
                            userId: bidderId,
                          )
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: ColorConstants.primary.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        bidderName.isNotEmpty
                            ? bidderName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: ColorConstants.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      '₱${NumberFormat('#,##0').format(amount)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$bidderName • ${DateFormat('MMM d, h:mm a').format(createdAt)}',
                          style: theme.textTheme.bodySmall,
                        ),
                        if (stats != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                _buildMiniStat(
                                  'Win Rate',
                                  '${(stats.biddingRate ?? 0).toStringAsFixed(0)}%',
                                  isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  'Success',
                                  '${(stats.successRate ?? 0).toStringAsFixed(0)}%',
                                  isDark,
                                ),
                                const SizedBox(width: 8),
                                _buildMiniStat(
                                  'Cancel',
                                  '${(stats.cancellationRate ?? 0).toStringAsFixed(0)}%',
                                  isDark,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    trailing: index == 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Highest',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: ColorConstants.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 10,
          color: ColorConstants.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
