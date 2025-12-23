import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../app/core/constants/color_constants.dart';

class BiddingInfoSection extends StatefulWidget {
  final DateTime endTime;
  final double currentBid;
  final double? reservePrice;
  final bool isReserveMet;
  final bool showReservePrice;
  final int totalBids;
  final int watchersCount;

  const BiddingInfoSection({
    super.key,
    required this.endTime,
    required this.currentBid,
    this.reservePrice,
    required this.isReserveMet,
    required this.showReservePrice,
    required this.totalBids,
    required this.watchersCount,
  });

  @override
  State<BiddingInfoSection> createState() => _BiddingInfoSectionState();
}

class _BiddingInfoSectionState extends State<BiddingInfoSection> {
  late Timer _timer;
  Duration _timeRemaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTimeRemaining();
    });
  }

  @override
  void didUpdateWidget(BiddingInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If endTime changed (due to snipe guard extension), recalculate immediately
    if (oldWidget.endTime != widget.endTime) {
      _updateTimeRemaining();
    }
  }

  void _updateTimeRemaining() {
    setState(() {
      _timeRemaining = widget.endTime.difference(DateTime.now());
      if (_timeRemaining.isNegative) _timeRemaining = Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
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
          _buildTimerHeader(theme, isDark),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildBidAmount(theme, isDark),
                const SizedBox(height: 16),
                _buildReserveStatus(theme, isDark),
                const SizedBox(height: 20),
                _buildStatsRow(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerHeader(ThemeData theme, bool isDark) {
    final isUrgent =
        _timeRemaining.inMinutes < 10 && _timeRemaining.inSeconds > 0;
    final hasEnded = _timeRemaining.inSeconds <= 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: hasEnded
            ? ColorConstants.textSecondaryLight.withValues(alpha: 0.1)
            : isUrgent
            ? ColorConstants.error.withValues(alpha: 0.1)
            : ColorConstants.primary.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            hasEnded ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 22,
            color: hasEnded
                ? ColorConstants.textSecondaryLight
                : isUrgent
                ? ColorConstants.error
                : ColorConstants.primary,
          ),
          const SizedBox(width: 10),
          Text(
            hasEnded ? 'Auction Ended' : 'Time Remaining',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasEnded
                  ? ColorConstants.textSecondaryLight
                  : isUrgent
                  ? ColorConstants.error
                  : ColorConstants.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (!hasEnded) _buildCountdownDisplay(theme, isUrgent),
        ],
      ),
    );
  }

  Widget _buildCountdownDisplay(ThemeData theme, bool isUrgent) {
    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;
    final seconds = _timeRemaining.inSeconds % 60;
    final color = isUrgent ? ColorConstants.error : ColorConstants.primary;

    if (days > 0) {
      return Row(
        children: [
          _buildTimeBlock('$days', 'd', color),
          _buildTimeSeparator(color),
          _buildTimeBlock('${hours.toString().padLeft(2, '0')}', 'h', color),
          _buildTimeSeparator(color),
          _buildTimeBlock('${minutes.toString().padLeft(2, '0')}', 'm', color),
        ],
      );
    }

    return Row(
      children: [
        _buildTimeBlock('${hours.toString().padLeft(2, '0')}', 'h', color),
        _buildTimeSeparator(color),
        _buildTimeBlock('${minutes.toString().padLeft(2, '0')}', 'm', color),
        _buildTimeSeparator(color),
        _buildTimeBlock('${seconds.toString().padLeft(2, '0')}', 's', color),
      ],
    );
  }

  Widget _buildTimeBlock(String value, String unit, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(unit, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    );
  }

  Widget _buildTimeSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: TextStyle(fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildBidAmount(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          'Current Bid',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '₱${_formatNumber(widget.currentBid)}',
          style: theme.textTheme.headlineLarge?.copyWith(
            color: ColorConstants.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildReserveStatus(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isReserveMet
            ? ColorConstants.success.withValues(alpha: 0.1)
            : ColorConstants.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            widget.isReserveMet ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: widget.isReserveMet
                ? ColorConstants.success
                : ColorConstants.warning,
          ),
          const SizedBox(width: 6),
          Text(
            widget.isReserveMet ? 'Reserve Met' : 'Reserve Not Met',
            style: theme.textTheme.bodySmall?.copyWith(
              color: widget.isReserveMet
                  ? ColorConstants.success
                  : ColorConstants.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.showReservePrice && widget.reservePrice != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 1,
              height: 14,
              color: widget.isReserveMet
                  ? ColorConstants.success.withValues(alpha: 0.3)
                  : ColorConstants.warning.withValues(alpha: 0.3),
            ),
            Text(
              '₱${_formatNumber(widget.reservePrice!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: widget.isReserveMet
                    ? ColorConstants.success
                    : ColorConstants.warning,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.gavel_rounded,
            value: widget.totalBids.toString(),
            label: 'Bids',
            theme: theme,
            isDark: isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility_outlined,
            value: widget.watchersCount.toString(),
            label: 'Watchers',
            theme: theme,
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.backgroundSecondaryDark
            : ColorConstants.backgroundSecondaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: ColorConstants.primary.withValues(alpha: 0.8),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return number
          .toStringAsFixed(0)
          .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (m) => '${m[1]},',
          );
    }
    return number.toStringAsFixed(0);
  }
}
