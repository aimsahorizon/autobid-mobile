import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../domain/entities/bid_detail_entity.dart';
import 'dart:async';

class BidInfoSection extends StatefulWidget {
  final BidDetailEntity bidDetail;

  const BidInfoSection({
    super.key,
    required this.bidDetail,
  });

  @override
  State<BidInfoSection> createState() => _BidInfoSectionState();
}

class _BidInfoSectionState extends State<BidInfoSection> {
  Timer? _timer;
  Duration? _remaining;

  @override
  void initState() {
    super.initState();
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimer() {
    if (widget.bidDetail.auctionEndDate != null) {
      setState(() {
        _remaining = widget.bidDetail.timeRemaining;
      });
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Ended';

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 24) {
      final days = hours ~/ 24;
      return '$days day${days > 1 ? 's' : ''} left';
    }

    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoItem(
                  icon: Icons.access_time,
                  label: 'Time Left',
                  value: _remaining != null ? _formatDuration(_remaining!) : 'N/A',
                  valueColor: _remaining != null && _remaining!.inHours < 2
                      ? ColorConstants.error
                      : null,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark
                    ? ColorConstants.textSecondaryDark.withValues(alpha: 0.2)
                    : ColorConstants.textSecondaryLight.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _InfoItem(
                  icon: Icons.gavel,
                  label: 'Your Bids',
                  value: '${widget.bidDetail.userBidCount}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ColorConstants.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: ColorConstants.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deposit Status',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ColorConstants.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.bidDetail.hasDeposited
                            ? 'Paid ₱${widget.bidDetail.depositAmount.toStringAsFixed(0)}'
                            : 'Not Paid',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: ColorConstants.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  widget.bidDetail.hasDeposited
                      ? Icons.check_circle
                      : Icons.warning_rounded,
                  color: widget.bidDetail.hasDeposited
                      ? ColorConstants.success
                      : ColorConstants.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Icon(
          icon,
          color: ColorConstants.primary,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
