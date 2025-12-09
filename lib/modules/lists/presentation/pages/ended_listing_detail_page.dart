import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../../../app/core/config/supabase_config.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../../data/datasources/listing_supabase_datasource.dart';

/// Detail page for ended auctions awaiting seller decision
/// Seller can choose to proceed to transaction or cancel the auction
class EndedListingDetailPage extends StatefulWidget {
  final ListingDetailEntity listing;

  const EndedListingDetailPage({
    super.key,
    required this.listing,
  });

  @override
  State<EndedListingDetailPage> createState() => _EndedListingDetailPageState();
}

class _EndedListingDetailPageState extends State<EndedListingDetailPage> {
  bool _isProcessing = false;

  Future<void> _handleDecision(bool proceed) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(proceed ? 'Proceed to Transaction?' : 'Cancel Auction?'),
        content: Text(
          proceed
              ? 'Are you sure you want to proceed with this transaction? The winning bidder will be notified.'
              : 'Are you sure you want to cancel this auction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: proceed ? ColorConstants.primary : ColorConstants.error,
            ),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      final dataSource = ListingSupabaseDataSource(SupabaseConfig.client);
      await dataSource.sellerDecideAfterAuction(
        widget.listing.id,
        proceed,
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            proceed
                ? 'Auction moved to transaction. Check the Transactions tab.'
                : 'Auction cancelled successfully.',
          ),
          backgroundColor: proceed ? ColorConstants.success : ColorConstants.warning,
        ),
      );

      // Navigate back and trigger reload
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: ColorConstants.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasReservePrice = widget.listing.reservePrice != null;
    final isReserveMet = hasReservePrice &&
        widget.listing.currentBid != null &&
        widget.listing.currentBid! >= widget.listing.reservePrice!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auction Ended'),
      ),
      body: _isProcessing
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Listing Image
                  if (widget.listing.photoUrls != null &&
                      widget.listing.photoUrls!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          widget.listing.photoUrls!.values.first.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            child: const Center(
                              child: Icon(Icons.directions_car, size: 64),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Listing Title
                  Text(
                    '${widget.listing.year} ${widget.listing.brand} ${widget.listing.model}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.listing.variant != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.listing.variant!,
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Auction Results
                  _buildResultCard(isReserveMet, hasReservePrice),
                  const SizedBox(height: 24),

                  // Decision Guidance
                  _buildGuidanceCard(isReserveMet),
                  const SizedBox(height: 24),

                  // Bid Statistics
                  _buildBidStats(),
                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildResultCard(bool isReserveMet, bool hasReservePrice) {
    return Card(
      color: isReserveMet
          ? ColorConstants.success.withOpacity(0.1)
          : ColorConstants.warning.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isReserveMet ? Icons.check_circle : Icons.info,
                  color: isReserveMet ? ColorConstants.success : ColorConstants.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  isReserveMet ? 'Reserve Price Met' : 'Reserve Price Not Met',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isReserveMet ? ColorConstants.success : ColorConstants.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPriceRow('Starting Price', widget.listing.startingPrice),
            if (hasReservePrice) ...[
              const SizedBox(height: 8),
              _buildPriceRow('Reserve Price', widget.listing.reservePrice!),
            ],
            const SizedBox(height: 8),
            _buildPriceRow(
              'Highest Bid',
              widget.listing.currentBid ?? widget.listing.startingPrice,
              isHighlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double price, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isHighlight ? 16 : 14,
            fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            color: ColorConstants.textSecondaryLight,
          ),
        ),
        Text(
          '₱${price.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isHighlight ? 18 : 16,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGuidanceCard(bool isReserveMet) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'What happens next?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (isReserveMet) ...[
              _buildGuidancePoint(
                Icons.handshake,
                'Proceed to Transaction',
                'Accept the highest bid and move to transaction phase. The winning bidder will be notified.',
              ),
              const SizedBox(height: 12),
              _buildGuidancePoint(
                Icons.cancel,
                'Cancel Auction',
                'Decline the current bid and cancel the auction. This listing will be moved to cancelled.',
              ),
            ] else ...[
              _buildGuidancePoint(
                Icons.info_outline,
                'Reserve Not Met',
                'The highest bid did not reach your reserve price. You can still proceed if you\'re willing to accept the current bid, or cancel the auction.',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuidancePoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: ColorConstants.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: ColorConstants.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBidStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auction Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    Icons.gavel,
                    'Total Bids',
                    widget.listing.totalBids.toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.visibility,
                    'Views',
                    widget.listing.viewsCount.toString(),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    Icons.bookmark,
                    'Watchers',
                    widget.listing.watchersCount.toString(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 24, color: ColorConstants.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: ColorConstants.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _handleDecision(true),
            icon: const Icon(Icons.handshake),
            label: const Text('Proceed to Transaction'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _handleDecision(false),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Auction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.error,
              side: BorderSide(color: ColorConstants.error),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
