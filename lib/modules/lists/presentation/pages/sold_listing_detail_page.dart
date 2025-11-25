import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../widgets/detail_sections/listing_cover_section.dart';
import '../widgets/detail_sections/listing_info_section.dart';

class SoldListingDetailPage extends StatelessWidget {
  final ListingDetailEntity listing;

  const SoldListingDetailPage({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sold Listing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () {
              // TODO: Show transaction receipt
            },
          ),
        ],
      ),
      backgroundColor: isDark ? ColorConstants.backgroundDark : ColorConstants.backgroundLight,
      body: ListView(
        children: [
          ListingCoverSection(listing: listing),
          const SizedBox(height: 16),
          _buildSoldStatusCard(context, isDark),
          const SizedBox(height: 16),
          _buildTransactionDetailsCard(context, isDark),
          const SizedBox(height: 16),
          _buildBuyerInfoCard(context, isDark),
          const SizedBox(height: 16),
          ListingInfoSection(listing: listing),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSoldStatusCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.green.withValues(alpha: 0.2),
            Colors.green.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4), width: 2),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 48,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Successfully Sold',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sold on ${_formatDate(listing.endTime ?? listing.createdAt)}',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.surfaceLight.withValues(alpha: 0.3)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Text(
                      'Final Bid',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${(listing.soldPrice ?? listing.currentBid ?? listing.startingPrice).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionDetailsCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, size: 20, color: ColorConstants.primary),
              const SizedBox(width: 8),
              const Text(
                'Transaction Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailRow(
            label: 'Transaction ID',
            value: '#TXN${listing.id.substring(0, 8).toUpperCase()}',
            isDark: isDark,
          ),
          const Divider(height: 24),
          _DetailRow(
            label: 'Total Bids Received',
            value: '${listing.totalBids}',
            isDark: isDark,
          ),
          const Divider(height: 24),
          _DetailRow(
            label: 'Starting Price',
            value: '₱${listing.startingPrice.toStringAsFixed(0)}',
            isDark: isDark,
          ),
          const Divider(height: 24),
          _DetailRow(
            label: 'Final Sale Price',
            value: '₱${(listing.soldPrice ?? listing.currentBid ?? listing.startingPrice).toStringAsFixed(0)}',
            valueColor: Colors.green,
            isDark: isDark,
          ),
          if (listing.reservePrice != null) ...[
            const Divider(height: 24),
            _DetailRow(
              label: 'Reserve Price',
              value: listing.isReserveMet
                  ? '✓ Met (₱${listing.reservePrice!.toStringAsFixed(0)})'
                  : '✗ Not Met (₱${listing.reservePrice!.toStringAsFixed(0)})',
              valueColor: listing.isReserveMet ? Colors.green : Colors.orange,
              isDark: isDark,
            ),
          ],
          const Divider(height: 24),
          _DetailRow(
            label: 'Auction Duration',
            value: _calculateDuration(),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildBuyerInfoCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: ColorConstants.primary),
              const SizedBox(width: 8),
              const Text(
                'Buyer Information',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ColorConstants.primary.withValues(alpha: 0.2),
                child: Text(
                  (listing.winnerName ?? 'W')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.winnerName ?? 'Winning Bidder',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified Buyer',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified, size: 14, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to transaction page
            },
            icon: const Icon(Icons.swap_horiz, size: 18),
            label: const Text('View Transaction Details'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
              foregroundColor: ColorConstants.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _calculateDuration() {
    if (listing.endTime == null) return 'N/A';
    final duration = listing.endTime!.difference(listing.createdAt);
    final days = duration.inDays;
    return '$days ${days == 1 ? 'day' : 'days'}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
