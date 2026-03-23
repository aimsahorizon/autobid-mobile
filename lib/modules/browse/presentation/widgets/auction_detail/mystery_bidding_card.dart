import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/mystery_bid_entity.dart';

/// Sealed-bid card for mystery auctions.
/// Bidders can only bid ONCE. Everything is hidden during the auction.
class MysteryBiddingCard extends StatefulWidget {
  final double minimumBid;
  final bool isProcessing;
  final MysteryBidStatusEntity? mysteryStatus;
  final bool isLoadingStatus;
  final Function(double) onPlaceMysteryBid;

  const MysteryBiddingCard({
    super.key,
    required this.minimumBid,
    required this.isProcessing,
    required this.mysteryStatus,
    required this.isLoadingStatus,
    required this.onPlaceMysteryBid,
  });

  @override
  State<MysteryBiddingCard> createState() => _MysteryBiddingCardState();
}

class _MysteryBiddingCardState extends State<MysteryBiddingCard> {
  final _bidController = TextEditingController();
  bool _showConfirmation = false;
  bool _isEditing = false;

  @override
  void didUpdateWidget(MysteryBiddingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset editing state after a successful bid update
    if (_isEditing &&
        widget.mysteryStatus?.hasBid == true &&
        widget.mysteryStatus?.userBidAmount !=
            oldWidget.mysteryStatus?.userBidAmount) {
      _isEditing = false;
      _bidController.clear();
      _showConfirmation = false;
    }
  }

  @override
  void dispose() {
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(theme, isDark),
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildContent(theme, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 22, color: Colors.deepPurple),
          const SizedBox(width: 10),
          Text(
            'Sealed Bid Auction',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'MYSTERY',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, bool isDark) {
    if (widget.isLoadingStatus) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final status = widget.mysteryStatus;

    // Seller view during active auction
    if (status != null && status.isSeller && !status.auctionEnded) {
      return _buildSellerView(theme, isDark, status);
    }

    // Auction ended — show results
    if (status != null && status.auctionEnded) {
      return _buildRevealedResults(theme, isDark, status);
    }

    // User already placed a bid — show edit form or placed state
    if (status != null && status.hasBid) {
      if (_isEditing) {
        return _buildBidForm(theme, isDark, isEdit: true);
      }
      return _buildBidPlacedState(theme, isDark, status);
    }

    // Show bid form
    return _buildBidForm(theme, isDark);
  }

  Widget _buildBidForm(ThemeData theme, bool isDark, {bool isEdit = false}) {
    if (_showConfirmation) {
      return _buildConfirmationView(theme, isDark, isEdit: isEdit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isEdit ? Icons.edit_note : Icons.info_outline,
                size: 18,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isEdit
                      ? 'Update your sealed bid. You can keep editing until the auction ends.'
                      : 'Place a sealed bid. You can edit it anytime before the auction ends.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.deepPurple.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Minimum bid indicator
        Text(
          'Minimum Bid: ₱${_formatNumber(widget.minimumBid)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 8),

        // Bid amount field
        TextField(
          controller: _bidController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            labelText: 'Your Bid Amount',
            prefixText: '₱ ',
            hintText: widget.minimumBid.toStringAsFixed(0),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Edit hint
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isEdit
                    ? 'Your previous bid will be replaced with this new amount.'
                    : 'You can edit your bid anytime before the deadline.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Place/Update bid button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton.icon(
            onPressed: widget.isProcessing ? null : _onSubmitPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: widget.isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(isEdit ? Icons.edit : Icons.lock),
            label: Text(
              widget.isProcessing
                  ? (isEdit ? 'Updating Bid...' : 'Placing Bid...')
                  : (isEdit ? 'Update Sealed Bid' : 'Place Sealed Bid'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        if (isEdit) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() {
                _isEditing = false;
                _bidController.clear();
                _showConfirmation = false;
              }),
              child: const Text('Cancel'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConfirmationView(
    ThemeData theme,
    bool isDark, {
    bool isEdit = false,
  }) {
    final amount = double.tryParse(_bidController.text) ?? 0;

    return Column(
      children: [
        Icon(
          isEdit ? Icons.edit_note : Icons.help_outline,
          size: 48,
          color: Colors.deepPurple,
        ),
        const SizedBox(height: 16),
        Text(
          isEdit ? 'Confirm Bid Update' : 'Confirm Your Sealed Bid',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₱${_formatNumber(amount)}',
          style: theme.textTheme.headlineMedium?.copyWith(
            color: Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isEdit
              ? 'Your previous bid will be replaced with this new amount.'
              : 'You can edit your bid later before the auction ends.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isEdit
                ? ColorConstants.warning
                : Colors.deepPurple.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _showConfirmation = false),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: widget.isProcessing
                    ? null
                    : () {
                        setState(() => _showConfirmation = false);
                        widget.onPlaceMysteryBid(amount);
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isEdit ? 'Update Bid' : 'Confirm Bid',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBidPlacedState(
    ThemeData theme,
    bool isDark,
    MysteryBidStatusEntity status,
  ) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: ColorConstants.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 36,
            color: ColorConstants.success,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Sealed Bid Placed',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorConstants.success,
          ),
        ),
        const SizedBox(height: 8),
        if (status.userBidAmount != null)
          Text(
            '₱${_formatNumber(status.userBidAmount!)}',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.deepPurple,
              fontWeight: FontWeight.bold,
            ),
          ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? ColorConstants.backgroundSecondaryDark
                : ColorConstants.backgroundSecondaryLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.people_outline,
                size: 18,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 8),
              Text(
                '${status.bidCount} sealed bid${status.bidCount == 1 ? '' : 's'} placed',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
                _bidController.text =
                    status.userBidAmount?.toStringAsFixed(0) ?? '';
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.deepPurple,
              side: const BorderSide(color: Colors.deepPurple),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.edit, size: 18),
            label: const Text(
              'Edit Bid',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Results will be revealed when the auction ends.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildSellerView(
    ThemeData theme,
    bool isDark,
    MysteryBidStatusEntity status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility, size: 20, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(
              'Seller View',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${status.bidCount} bid${status.bidCount == 1 ? '' : 's'}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        if (status.allBids.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...status.allBids.map(
            (bid) => _buildBidRow(theme, isDark, bid, isSellerView: true),
          ),
        ] else ...[
          const SizedBox(height: 16),
          Center(
            child: Text(
              'No bids placed yet',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRevealedResults(
    ThemeData theme,
    bool isDark,
    MysteryBidStatusEntity status,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.visibility, size: 20, color: Colors.deepPurple),
            const SizedBox(width: 8),
            Text(
              'Bids Revealed',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (status.allBids.isEmpty)
          Center(
            child: Text(
              'No bids were placed on this auction.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          )
        else
          ...status.allBids.asMap().entries.map((entry) {
            final bid = entry.value;
            return _buildBidRow(
              theme,
              isDark,
              bid,
              isWinner: bid.bidderId == status.winnerId,
              rank: entry.key + 1,
            );
          }),
        if (status.tiebreaker != null) ...[
          const SizedBox(height: 16),
          _buildTiebreakerSummary(theme, isDark, status.tiebreaker!),
        ],
      ],
    );
  }

  Widget _buildBidRow(
    ThemeData theme,
    bool isDark,
    MysteryBidEntry bid, {
    bool isSellerView = false,
    bool isWinner = false,
    int? rank,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner
            ? ColorConstants.success.withValues(alpha: 0.08)
            : (isDark
                  ? ColorConstants.backgroundSecondaryDark
                  : ColorConstants.backgroundSecondaryLight),
        borderRadius: BorderRadius.circular(10),
        border: isWinner
            ? Border.all(color: ColorConstants.success.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          if (rank != null) ...[
            SizedBox(
              width: 24,
              child: Text(
                '#$rank',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isWinner ? ColorConstants.success : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (isSellerView)
            Icon(
              Icons.person_outline,
              size: 16,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Bidder ${bid.bidderId.substring(0, 8)}…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₱${_formatNumber(bid.bidAmount)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isWinner ? ColorConstants.success : Colors.deepPurple,
            ),
          ),
          if (isWinner) ...[
            const SizedBox(width: 6),
            const Icon(
              Icons.emoji_events,
              size: 16,
              color: ColorConstants.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTiebreakerSummary(
    ThemeData theme,
    bool isDark,
    MysteryTiebreakerEntity tiebreaker,
  ) {
    final type = tiebreaker.isCoinFlip ? 'Coin Flip' : 'Lottery Draw';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            tiebreaker.isCoinFlip ? Icons.monetization_on : Icons.casino,
            size: 20,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiebreaker: $type',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
                Text(
                  '${tiebreaker.tiedBidderIds.length} bidders tied at the same amount',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.amber.shade700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onSubmitPressed() {
    final text = _bidController.text.trim();
    if (text.isEmpty) return;
    final amount = double.tryParse(text);
    if (amount == null || amount < widget.minimumBid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum bid is ₱${_formatNumber(widget.minimumBid)}'),
          backgroundColor: ColorConstants.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _showConfirmation = true);
  }

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
