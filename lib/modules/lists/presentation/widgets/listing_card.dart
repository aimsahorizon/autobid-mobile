import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/core/constants/color_constants.dart';
import '../../domain/entities/seller_listing_entity.dart';

class ListingCard extends StatefulWidget {
  final SellerListingEntity listing;
  final bool isGridView;
  final VoidCallback? onTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.isGridView = true,
    this.onTap,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.listing.status == ListingStatus.active &&
        widget.listing.endTime != null) {
      _updateTimeRemaining();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTimeRemaining(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeRemaining() {
    if (widget.listing.endTime == null) return;
    setState(() {
      _timeRemaining = widget.listing.endTime!.difference(DateTime.now());
      if (_timeRemaining.isNegative) {
        _timer?.cancel();
        _timeRemaining = Duration.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.isGridView
        ? _buildGridCard(context)
        : _buildListCard(context);
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.surfaceDark
              : ColorConstants.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? ColorConstants.borderDark
                : ColorConstants.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardImage(
              imageUrl: widget.listing.imageUrl,
              status: widget.listing.status,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.listing.carName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _PriceInfo(listing: widget.listing),
                  const SizedBox(height: 8),
                  _StatsRow(listing: widget.listing),
                  const SizedBox(height: 8),
                  _StatusInfo(
                    listing: widget.listing,
                    timeRemaining: _timeRemaining,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? ColorConstants.surfaceDark
              : ColorConstants.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? ColorConstants.borderDark
                : ColorConstants.borderLight,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.listing.imageUrl,
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) =>
                    Container(color: ColorConstants.backgroundSecondaryLight),
                errorWidget: (_, __, ___) => Container(
                  color: ColorConstants.backgroundSecondaryLight,
                  child: const Icon(Icons.directions_car),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.listing.carName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _StatusBadge(status: widget.listing.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _PriceInfo(listing: widget.listing, compact: true),
                  const SizedBox(height: 4),
                  _StatsRow(listing: widget.listing, compact: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final ListingStatus status;

  const _CardImage({required this.imageUrl, required this.status});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: ColorConstants.backgroundSecondaryLight,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => Container(
                color: ColorConstants.backgroundSecondaryLight,
                child: const Icon(Icons.directions_car, size: 40),
              ),
            ),
          ),
          Positioned(top: 8, right: 8, child: _StatusBadge(status: status)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(ListingStatus status) {
    switch (status) {
      case ListingStatus.active:
        return ColorConstants.success;
      case ListingStatus.pending:
        return ColorConstants.warning;
      case ListingStatus.approved:
        return ColorConstants.info;
      case ListingStatus.scheduled:
        return ColorConstants.info;
      case ListingStatus.ended:
        return ColorConstants.primary;
      case ListingStatus.draft:
        return ColorConstants.textSecondaryLight;
      case ListingStatus.cancelled:
        return ColorConstants.error;
      case ListingStatus.inTransaction:
        return ColorConstants.info;
      case ListingStatus.sold:
        return ColorConstants.success;
      case ListingStatus.dealFailed:
        return ColorConstants.error;
    }
  }
}

class _PriceInfo extends StatelessWidget {
  final SellerListingEntity listing;
  final bool compact;

  const _PriceInfo({required this.listing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasCurrentBid = listing.currentBid != null;
    final displayPrice = listing.currentBid ?? listing.startingPrice;
    final priceLabel = hasCurrentBid ? 'Current' : 'Starting';

    return Row(
      children: [
        Text(
          '$priceLabel: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
            fontSize: compact ? 11 : 12,
          ),
        ),
        Text(
          '₱${_formatAmount(displayPrice)}',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: ColorConstants.primary,
            fontSize: compact ? 13 : 14,
          ),
        ),
        if (listing.isReserveMet) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: ColorConstants.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Reserve Met',
              style: TextStyle(
                color: ColorConstants.success,
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    }
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _StatsRow extends StatelessWidget {
  final SellerListingEntity listing;
  final bool compact;

  const _StatsRow({required this.listing, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? ColorConstants.textSecondaryDark
        : ColorConstants.textSecondaryLight;
    final iconSize = compact ? 12.0 : 14.0;
    final fontSize = compact ? 10.0 : 11.0;

    return Row(
      children: [
        Icon(Icons.gavel, size: iconSize, color: textColor),
        const SizedBox(width: 4),
        Text(
          '${listing.totalBids}',
          style: TextStyle(fontSize: fontSize, color: textColor),
        ),
        const SizedBox(width: 12),
        Icon(Icons.visibility_outlined, size: iconSize, color: textColor),
        const SizedBox(width: 4),
        Text(
          '${listing.viewsCount}',
          style: TextStyle(fontSize: fontSize, color: textColor),
        ),
        const SizedBox(width: 12),
        Icon(Icons.bookmark_outline, size: iconSize, color: textColor),
        const SizedBox(width: 4),
        Text(
          '${listing.watchersCount}',
          style: TextStyle(fontSize: fontSize, color: textColor),
        ),
      ],
    );
  }
}

class _StatusInfo extends StatelessWidget {
  final SellerListingEntity listing;
  final Duration timeRemaining;

  const _StatusInfo({required this.listing, required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    switch (listing.status) {
      case ListingStatus.active:
        return _TimeChip(timeRemaining: timeRemaining);
      case ListingStatus.pending:
        return _InfoChip(
          icon: Icons.hourglass_empty,
          label: 'Awaiting Review',
          color: ColorConstants.warning,
        );
      case ListingStatus.approved:
        return _InfoChip(
          icon: Icons.rocket_launch_outlined,
          label: 'Ready to Publish',
          color: ColorConstants.info,
        );
      case ListingStatus.scheduled:
        return _InfoChip(
          icon: Icons.schedule,
          label: 'Scheduled',
          color: ColorConstants.info,
        );
      case ListingStatus.ended:
        return _InfoChip(
          icon: Icons.flag_outlined,
          label: 'Awaiting Decision',
          color: ColorConstants.primary,
        );
      case ListingStatus.draft:
        return _InfoChip(
          icon: Icons.edit_outlined,
          label: 'Incomplete',
          color: ColorConstants.textSecondaryLight,
        );
      case ListingStatus.cancelled:
        return _InfoChip(
          icon: Icons.cancel_outlined,
          label: 'Cancelled',
          color: ColorConstants.error,
        );
      case ListingStatus.inTransaction:
        return _InfoChip(
          icon: Icons.handshake_outlined,
          label: 'In Transaction',
          color: ColorConstants.info,
        );
      case ListingStatus.sold:
        return _InfoChip(
          icon: Icons.check_circle_outlined,
          label: 'Sold',
          color: ColorConstants.success,
        );
      case ListingStatus.dealFailed:
        return _InfoChip(
          icon: Icons.cancel_outlined,
          label: 'Deal Failed',
          color: ColorConstants.error,
        );
    }
  }
}

class _TimeChip extends StatelessWidget {
  final Duration timeRemaining;

  const _TimeChip({required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    final isUrgent = timeRemaining.inHours < 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? ColorConstants.error.withValues(alpha: 0.1)
            : ColorConstants.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 12,
            color: isUrgent ? ColorConstants.error : ColorConstants.success,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(timeRemaining),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isUrgent ? ColorConstants.error : ColorConstants.success,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h left';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m left';
    return '${d.inMinutes}m ${d.inSeconds % 60}s left';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
