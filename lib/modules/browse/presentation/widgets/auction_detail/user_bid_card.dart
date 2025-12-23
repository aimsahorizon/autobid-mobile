import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';
import '../../../domain/entities/user_bid_entity.dart';

class UserBidCard extends StatefulWidget {
  final UserBidEntity bid;
  final VoidCallback? onTap;

  const UserBidCard({super.key, required this.bid, this.onTap});

  @override
  State<UserBidCard> createState() => _UserBidCardState();
}

class _UserBidCardState extends State<UserBidCard> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.bid.status == UserBidStatus.active) {
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
    setState(() {
      _timeRemaining = widget.bid.endTime.difference(DateTime.now());
      if (_timeRemaining.isNegative) {
        _timer?.cancel();
        _timeRemaining = Duration.zero;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            color: _getBorderColor(isDark),
            width: widget.bid.isHighestBidder ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardImage(
              imageUrl: widget.bid.carImageUrl,
              status: widget.bid.status,
              isHighestBidder: widget.bid.isHighestBidder,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.bid.carName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _BidAmountRow(
                    label: 'Your Bid',
                    amount: widget.bid.userBidAmount,
                    isHighlight: widget.bid.isHighestBidder,
                  ),
                  const SizedBox(height: 4),
                  _BidAmountRow(
                    label: 'Highest',
                    amount: widget.bid.currentHighestBid,
                  ),
                  const SizedBox(height: 8),
                  if (widget.bid.status == UserBidStatus.active)
                    _TimeRemainingChip(timeRemaining: _timeRemaining)
                  else
                    _StatusChip(status: widget.bid.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBorderColor(bool isDark) {
    switch (widget.bid.status) {
      case UserBidStatus.active:
        return widget.bid.isHighestBidder
            ? ColorConstants.success
            : ColorConstants.warning;
      case UserBidStatus.won:
        return ColorConstants.success;
      case UserBidStatus.lost:
        return ColorConstants.error.withValues(alpha: 0.5);
      case UserBidStatus.cancelled:
        return Colors.grey.withValues(alpha: 0.5);
    }
  }
}

class _CardImage extends StatelessWidget {
  final String imageUrl;
  final UserBidStatus status;
  final bool isHighestBidder;

  const _CardImage({
    required this.imageUrl,
    required this.status,
    required this.isHighestBidder,
  });

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
          if (status == UserBidStatus.active)
            Positioned(
              top: 8,
              right: 8,
              child: _BidPositionBadge(isHighestBidder: isHighestBidder),
            ),
        ],
      ),
    );
  }
}

class _BidPositionBadge extends StatelessWidget {
  final bool isHighestBidder;

  const _BidPositionBadge({required this.isHighestBidder});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighestBidder
            ? ColorConstants.success
            : ColorConstants.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHighestBidder ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isHighestBidder ? 'Winning' : 'Outbid',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _BidAmountRow extends StatelessWidget {
  final String label;
  final double amount;
  final bool isHighlight;

  const _BidAmountRow({
    required this.label,
    required this.amount,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        Text(
          '₱${_formatAmount(amount)}',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHighlight ? ColorConstants.success : null,
          ),
        ),
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

class _TimeRemainingChip extends StatelessWidget {
  final Duration timeRemaining;

  const _TimeRemainingChip({required this.timeRemaining});

  @override
  Widget build(BuildContext context) {
    final isUrgent = timeRemaining.inHours < 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isUrgent
            ? ColorConstants.error.withValues(alpha: 0.1)
            : ColorConstants.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer_outlined,
            size: 14,
            color: isUrgent ? ColorConstants.error : ColorConstants.primary,
          ),
          const SizedBox(width: 4),
          Text(
            _formatDuration(timeRemaining),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isUrgent ? ColorConstants.error : ColorConstants.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d ${d.inHours % 24}h';
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes % 60}m';
    return '${d.inMinutes}m ${d.inSeconds % 60}s';
  }
}

class _StatusChip extends StatelessWidget {
  final UserBidStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isWon = status == UserBidStatus.won;
    final isCancelled = status == UserBidStatus.cancelled;

    Color backgroundColor;
    Color iconColor;
    IconData icon;
    String text;

    if (isCancelled) {
      backgroundColor = Colors.grey.withValues(alpha: 0.1);
      iconColor = Colors.grey;
      icon = Icons.cancel_outlined;
      text = 'Cancelled';
    } else if (isWon) {
      backgroundColor = ColorConstants.success.withValues(alpha: 0.1);
      iconColor = ColorConstants.success;
      icon = Icons.emoji_events;
      text = 'Won';
    } else {
      backgroundColor = ColorConstants.error.withValues(alpha: 0.1);
      iconColor = ColorConstants.error;
      icon = Icons.close;
      text = 'Lost';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
