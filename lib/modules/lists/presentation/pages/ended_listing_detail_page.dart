import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/listing_detail_entity.dart';
import '../../data/datasources/listing_supabase_datasource.dart';

/// Detail page for ended auctions awaiting seller decision
/// Seller can choose to proceed to transaction or cancel the auction
class EndedListingDetailPage extends StatefulWidget {
  final ListingDetailEntity listing;

  const EndedListingDetailPage({super.key, required this.listing});

  @override
  State<EndedListingDetailPage> createState() => _EndedListingDetailPageState();
}

class _EndedListingDetailPageState extends State<EndedListingDetailPage> {
  bool _isProcessing = false;
  late final ListingSupabaseDataSource _datasource;

  @override
  void initState() {
    super.initState();
    _datasource = ListingSupabaseDataSource(SupabaseConfig.client);
  }

  Future<void> _reauction() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reauction this Listing?'),
        content: const Text(
          'Are you sure you want to reauction this listing? It will be moved back to pending approval status.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.primary,
            ),
            child: const Text('Reauction'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _datasource.reauctiongListing(widget.listing.id);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listing reauctions. Check the Pending tab.'),
          backgroundColor: ColorConstants.success,
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

  Future<void> _cancelEnded() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this Auction?'),
        content: const Text(
          'Are you sure you want to cancel this auction? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.error,
            ),
            child: const Text('Cancel Auction'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      await _datasource.cancelEndedAuction(widget.listing.id);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Auction cancelled successfully.'),
          backgroundColor: ColorConstants.warning,
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

  Future<void> _proceedToTransaction() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proceed to Transaction'),
        content: const Text(
          'You will move this auction to the transactions tab where you can communicate with the winning bidder and complete the sale.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
            ),
            child: const Text('Proceed'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);

    try {
      // First, try to create a transaction record based on highest bid.
      // If there are no bids, handle gracefully and do NOT proceed.
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      bool transactionPrepared = false;
      if (currentUserId != null) {
        transactionPrepared = await _datasource.ensureTransactionCreated(
          widget.listing.id,
          currentUserId,
        );
      }

      if (!transactionPrepared) {
        // No bids found or transaction couldn't be prepared.
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No winning bid found. You can Reauction or Cancel this listing.',
            ),
            backgroundColor: ColorConstants.warning,
          ),
        );
        return;
      }

      // Update auction status to 'in_transaction' only after transaction is prepared
      await _datasource.updateListingStatusByName(
        widget.listing.id,
        'in_transaction',
      );

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Moved to Transactions tab. Go there to communicate with the winner.',
          ),
          backgroundColor: ColorConstants.success,
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
    final isReserveMet =
        hasReservePrice &&
        widget.listing.currentBid != null &&
        widget.listing.currentBid! >= widget.listing.reservePrice!;

    return Scaffold(
      appBar: AppBar(title: const Text('Auction Ended')),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
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
          ? ColorConstants.success.withAlpha((0.1 * 255).toInt())
          : ColorConstants.warning.withAlpha((0.1 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isReserveMet ? Icons.check_circle : Icons.info,
                  color: isReserveMet
                      ? ColorConstants.success
                      : ColorConstants.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  isReserveMet ? 'Reserve Price Met' : 'Reserve Price Not Met',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isReserveMet
                        ? ColorConstants.success
                        : ColorConstants.warning,
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

  Widget _buildPriceRow(
    String label,
    double price, {
    bool isHighlight = false,
  }) {
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
      color: isReserveMet
          ? ColorConstants.success.withAlpha((0.1 * 255).toInt())
          : ColorConstants.warning.withAlpha((0.1 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isReserveMet ? Icons.check_circle : Icons.info,
                  color: isReserveMet
                      ? ColorConstants.success
                      : ColorConstants.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isReserveMet
                        ? 'Auction Successful - Winner Selected'
                        : 'Reserve Price Not Met - Highest Bidder Selected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isReserveMet
                          ? ColorConstants.success
                          : ColorConstants.warning,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              isReserveMet
                  ? 'The highest bidder has automatically won this auction. Proceed to the transactions tab to communicate with them and complete the sale.'
                  : 'The reserve price was not met. However, you can still proceed to sell to the highest bidder in the transactions tab, or choose to reauction.',
              style: TextStyle(
                fontSize: 13,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withAlpha((0.5 * 255).toInt()),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What happens next?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  _buildGuidancePoint(
                    Icons.handshake,
                    'Proceed to Transaction',
                    'Move this auction to the Transactions tab where you can chat with the winning bidder and complete the sale.',
                  ),
                  const SizedBox(height: 8),
                  _buildGuidancePoint(
                    Icons.refresh,
                    'Reauction',
                    'Not satisfied with the bid? Reauction the item to restart the bidding process.',
                  ),
                  const SizedBox(height: 8),
                  _buildGuidancePoint(
                    Icons.cancel,
                    'Cancel',
                    'Permanently cancel the auction. Use only if you no longer want to sell.',
                  ),
                ],
              ),
            ),
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
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
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
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
        // Primary action: Proceed to Transaction
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _proceedToTransaction(),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Proceed to Transaction'),
            style: FilledButton.styleFrom(
              backgroundColor: ColorConstants.success,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary action: Reauction if not satisfied with winner
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _reauction(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reauction'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorConstants.primary,
              side: BorderSide(color: ColorConstants.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Tertiary action: Cancel auction
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _cancelEnded(),
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
