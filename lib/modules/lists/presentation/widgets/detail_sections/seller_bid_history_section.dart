import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:intl/intl.dart';

class SellerBidHistorySection extends StatelessWidget {
  final List<Map<String, dynamic>> bids;
  final bool isLoading;

  const SellerBidHistorySection({
    super.key,
    required this.bids,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      color: isDark
          ? ColorConstants.surfaceDark
          : ColorConstants.surfaceLight,
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
              if (bids.isNotEmpty)
                Text(
                  '${bids.length} Bids',
                  style: theme.textTheme.bodySmall,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (bids.isEmpty)
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
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bids.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final bid = bids[index];
                final amount = (bid['bid_amount'] as num).toDouble();
                final createdAt = DateTime.parse(bid['created_at']);
                final profile = bid['user_profiles'] as Map<String, dynamic>?;
                final bidderName = profile?['username'] ?? profile?['full_name'] ?? 'Unknown Bidder';
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
                    child: Text(
                      bidderName.isNotEmpty ? bidderName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: ColorConstants.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    '₱${NumberFormat('#,##0').format(amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$bidderName • ${DateFormat('MMM d, h:mm a').format(createdAt)}',
                    style: theme.textTheme.bodySmall,
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
        ],
      ),
    );
  }
}
