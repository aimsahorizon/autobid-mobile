import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../domain/entities/seller_listing_entity.dart';

bool _isAssetPath(String url) => url.startsWith('assets/');

class ListingCard extends StatefulWidget {
  final SellerListingEntity listing;
  final bool isGridView;
  final VoidCallback? onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onInviteTap;

  const ListingCard({
    super.key,
    required this.listing,
    this.isGridView = true,
    this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onInviteTap,
  });

  @override
  State<ListingCard> createState() => _ListingCardState();
}

class _ListingCardState extends State<ListingCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  Duration _timeUntilStart = Duration.zero;

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
    } else if (widget.listing.status == ListingStatus.scheduled &&
        widget.listing.startTime != null) {
      _updateTimeUntilStart();
      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateTimeUntilStart(),
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

  void _updateTimeUntilStart() {
    if (widget.listing.startTime == null) return;
    setState(() {
      _timeUntilStart = widget.listing.startTime!.difference(DateTime.now());
      if (_timeUntilStart.isNegative) {
        _timer?.cancel();
        _timeUntilStart = Duration.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.isGridView
        ? _buildGridCard(context)
        : _buildListCard(context);

    if (widget.isSelectionMode) {
      return Stack(
        children: [
          card,
          Positioned.fill(
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? ColorConstants.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: widget.isSelected
                      ? Border.all(color: ColorConstants.primary, width: 2)
                      : null,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      widget.isSelected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: widget.isSelected
                          ? ColorConstants.primary
                          : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onLongPress: widget.onLongPress,
      onTap: widget.onTap,
      child: card,
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
            cancelledBy: widget.listing.cancelledBy,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.carName, // carName now includes variant
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
                  timeUntilStart: _timeUntilStart,
                ),
                if (widget.listing.status == ListingStatus.sold &&
                    widget.listing.hasReview != null) ...[
                  const SizedBox(height: 8),
                  _ReviewIndicator(
                    hasReview: widget.listing.hasReview!,
                    onTap: widget.onTap,
                  ),
                ],
                if (widget.listing.visibility == 'exclusive' &&
                    widget.onInviteTap != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onInviteTap,
                      icon: const Icon(Icons.people_outline, size: 14),
                      label: const Text(
                        'Invites',
                        style: TextStyle(fontSize: 11),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
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
            child: _isAssetPath(widget.listing.imageUrl)
                ? Image.asset(
                    widget.listing.imageUrl,
                    width: 100,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: ColorConstants.backgroundSecondaryLight,
                      child: const Icon(Icons.directions_car),
                    ),
                  )
                : CachedNetworkImage(
                    imageUrl: widget.listing.imageUrl,
                    width: 100,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: ColorConstants.backgroundSecondaryLight,
                    ),
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
                    _StatusBadge(
                      status: widget.listing.status,
                      cancelledBy: widget.listing.cancelledBy,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _PriceInfo(listing: widget.listing, compact: true),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: _StatsRow(listing: widget.listing, compact: true),
                    ),
                    if (widget.listing.visibility == 'exclusive' &&
                        widget.onInviteTap != null)
                      IconButton(
                        icon: const Icon(Icons.people_outline, size: 18),
                        onPressed: widget.onInviteTap,
                        tooltip: 'Manage Invites',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                      ),
                  ],
                ),
                if (widget.listing.status == ListingStatus.sold &&
                    widget.listing.hasReview != null) ...[
                  const SizedBox(height: 4),
                  _ReviewIndicator(
                    hasReview: widget.listing.hasReview!,
                    onTap: widget.onTap,
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final ListingStatus status;
  final String? cancelledBy;

  const _CardImage({
    required this.imageUrl,
    required this.status,
    this.cancelledBy,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: _isAssetPath(imageUrl)
                ? Image.asset(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: ColorConstants.backgroundSecondaryLight,
                      child: const Icon(Icons.directions_car, size: 40),
                    ),
                  )
                : CachedNetworkImage(
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
          Positioned(
            top: 8,
            right: 8,
            child: _StatusBadge(status: status, cancelledBy: cancelledBy),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ListingStatus status;
  final String? cancelledBy;

  const _StatusBadge({required this.status, this.cancelledBy});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getLabel(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getLabel() {
    if (status == ListingStatus.dealFailed) {
      if (cancelledBy == 'buyer') return 'Rejected';
      if (cancelledBy == 'seller') return 'Cancelled';
      return 'Cancelled';
    }
    if (status == ListingStatus.sold) return 'Completed';
    return status.label;
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
      case ListingStatus.rejected:
        return Colors.deepOrange;
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
        Flexible(
          child: Text(
            '₱${_formatAmount(displayPrice)}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: ColorConstants.primary,
              fontSize: compact ? 13 : 14,
            ),
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
  final Duration timeUntilStart;

  const _StatusInfo({
    required this.listing,
    required this.timeRemaining,
    required this.timeUntilStart,
  });

  @override
  Widget build(BuildContext context) {
    // Check for cancellation reason first
    if ((listing.status == ListingStatus.dealFailed ||
            listing.status == ListingStatus.cancelled) &&
        listing.cancellationReason != null &&
        listing.cancellationReason!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoChip(
            icon: Icons.cancel_outlined,
            label: listing.status == ListingStatus.dealFailed
                ? (listing.cancelledBy == 'buyer' ? 'Rejected' : 'Cancelled')
                : 'Cancelled',
            color: ColorConstants.error,
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${listing.cancellationReason}',
            style: TextStyle(
              fontSize: 11,
              color: ColorConstants.error,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    // Check for rejection reason
    if (listing.status == ListingStatus.rejected &&
        listing.rejectionReason != null &&
        listing.rejectionReason!.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoChip(
            icon: Icons.block,
            label: 'Rejected',
            color: Colors.deepOrange,
          ),
          const SizedBox(height: 4),
          Text(
            'Reason: ${listing.rejectionReason}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.deepOrange,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }

    switch (listing.status) {
      case ListingStatus.active:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TimeChip(timeRemaining: timeRemaining),
            if (listing.endTime != null) ...[
              const SizedBox(height: 4),
              _DateChip(
                icon: Icons.event,
                label:
                    'Ends ${DateFormat('MMM d, h:mm a').format(listing.endTime!.toLocal())}',
              ),
            ],
          ],
        );
      case ListingStatus.pending:
        return _InfoChip(
          icon: Icons.hourglass_empty,
          label: 'Awaiting Review',
          color: ColorConstants.warning,
        );
      case ListingStatus.approved:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoChip(
              icon: Icons.rocket_launch_outlined,
              label: 'Ready to Publish',
              color: ColorConstants.info,
            ),
            if (listing.endTime != null) ...[
              const SizedBox(height: 4),
              _DateChip(
                icon: Icons.event,
                label:
                    'Ends ${DateFormat('MMM d, h:mm a').format(listing.endTime!.toLocal())}',
              ),
            ],
          ],
        );
      case ListingStatus.scheduled:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (timeUntilStart > Duration.zero)
              _ScheduleCountdownChip(timeUntilStart: timeUntilStart)
            else
              _InfoChip(
                icon: Icons.schedule,
                label: 'Scheduled',
                color: ColorConstants.info,
              ),
            if (listing.startTime != null) ...[
              const SizedBox(height: 4),
              _DateChip(
                icon: Icons.play_arrow_rounded,
                label:
                    'Starts ${DateFormat('MMM d, h:mm a').format(listing.startTime!.toLocal())}',
              ),
            ],
            if (listing.endTime != null) ...[
              const SizedBox(height: 4),
              _DateChip(
                icon: Icons.event,
                label:
                    'Ends ${DateFormat('MMM d, h:mm a').format(listing.endTime!.toLocal())}',
              ),
            ],
          ],
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
      case ListingStatus.rejected:
        return _InfoChip(
          icon: Icons.block,
          label: 'Rejected by Admin',
          color: Colors.deepOrange,
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
          label: 'Completed',
          color: ColorConstants.success,
        );
      case ListingStatus.dealFailed:
        return _InfoChip(
          icon: Icons.cancel_outlined,
          label: listing.cancelledBy == 'buyer' ? 'Rejected' : 'Cancelled',
          color: ColorConstants.error,
        );
    }
  }
}

class _ReviewIndicator extends StatelessWidget {
  final bool hasReview;
  final VoidCallback? onTap;
  final bool compact;

  const _ReviewIndicator({
    required this.hasReview,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hasReview) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: compact ? 12 : 14,
            color: ColorConstants.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Reviewed',
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              color: ColorConstants.success,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: compact ? 28 : 32,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(Icons.star_outline, size: compact ? 14 : 16),
        label: Text(
          'Leave a Review',
          style: TextStyle(fontSize: compact ? 10 : 11),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: ColorConstants.warning,
          side: BorderSide(
            color: ColorConstants.warning.withValues(alpha: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
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

class _ScheduleCountdownChip extends StatelessWidget {
  final Duration timeUntilStart;

  const _ScheduleCountdownChip({required this.timeUntilStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorConstants.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 12, color: ColorConstants.info),
          const SizedBox(width: 4),
          Text(
            _formatDuration(timeUntilStart),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ColorConstants.info,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return 'Starts in ${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return 'Starts in ${d.inHours}h ${d.inMinutes % 60}m';
    return 'Starts in ${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class _DateChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DateChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = isDark
        ? ColorConstants.textSecondaryDark
        : ColorConstants.textSecondaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
