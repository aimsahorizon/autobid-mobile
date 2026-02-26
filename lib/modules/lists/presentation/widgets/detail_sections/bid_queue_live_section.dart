import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';

/// Live bucket/queue lifecycle view for sellers.
/// Shows the current bid queue cycle state, entries, and
/// realtime updates as the bucket fills, locks and processes.
class BidQueueLiveSection extends StatefulWidget {
  final String auctionId;
  final SupabaseClient supabase;

  const BidQueueLiveSection({
    super.key,
    required this.auctionId,
    required this.supabase,
  });

  @override
  State<BidQueueLiveSection> createState() => _BidQueueLiveSectionState();
}

class _BidQueueLiveSectionState extends State<BidQueueLiveSection> {
  List<Map<String, dynamic>> _cycles = [];
  bool _isLoading = true;
  String? _error;
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final response = await widget.supabase.rpc(
        'get_seller_queue_status',
        params: {'p_auction_id': widget.auctionId},
      );

      if (!mounted) return;

      final data = response as Map<String, dynamic>?;

      if (data != null && data['cycles'] != null) {
        setState(() {
          _cycles = List<Map<String, dynamic>>.from(data['cycles'] as List);
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _cycles = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading seller queue status: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load queue status';
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToUpdates() {
    _subscription = widget.supabase
        .from('bid_queue_cycles')
        .stream(primaryKey: ['id'])
        .eq('auction_id', widget.auctionId)
        .listen((_) {
          // Reload full data on any cycle change
          _loadData();
        });
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
        border: Border.all(
          color: isDark
              ? ColorConstants.surfaceLight.withValues(alpha: 0.2)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorConstants.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.back_hand,
                  color: ColorConstants.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bid Queue',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Live bucket lifecycle',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _loadData,
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Content
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: ColorConstants.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: ColorConstants.error),
                    ),
                  ],
                ),
              ),
            )
          else if (_cycles.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No bidding activity yet',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ),
            )
          else
            ..._cycles.asMap().entries.map(
              (entry) => _buildCycleCard(
                theme,
                isDark,
                entry.value,
                isLatest: entry.key == 0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCycleCard(
    ThemeData theme,
    bool isDark,
    Map<String, dynamic> cycle, {
    bool isLatest = false,
  }) {
    final state = cycle['state'] as String? ?? 'unknown';
    final cycleNumber = cycle['cycle_number'] as int? ?? 0;
    final queue = (cycle['queue'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final createdAt = cycle['created_at'] as String?;

    final stateInfo = _getStateInfo(state);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLatest
            ? stateInfo.color.withValues(alpha: 0.06)
            : (isDark
                  ? ColorConstants.backgroundSecondaryDark
                  : ColorConstants.backgroundSecondaryLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLatest
              ? stateInfo.color.withValues(alpha: 0.3)
              : (isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight),
          width: isLatest ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cycle header
          Row(
            children: [
              Icon(stateInfo.icon, color: stateInfo.color, size: 18),
              const SizedBox(width: 8),
              Text(
                'Cycle #$cycleNumber',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stateInfo.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  stateInfo.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: stateInfo.color,
                  ),
                ),
              ),
              const Spacer(),
              if (createdAt != null)
                Text(
                  _formatTime(createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          // State progress bar
          if (isLatest) ...[
            const SizedBox(height: 10),
            _buildStateProgressBar(state),
          ],
          // Queue entries
          if (queue.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...queue.map((entry) => _buildQueueEntry(theme, isDark, entry)),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'No entries in this cycle',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStateProgressBar(String currentState) {
    final states = ['open', 'locked', 'processing', 'complete'];
    final currentIdx = states.indexOf(currentState);

    return Row(
      children: [
        for (int i = 0; i < states.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                color: i <= currentIdx
                    ? ColorConstants.primary
                    : ColorConstants.primary.withValues(alpha: 0.2),
              ),
            ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i <= currentIdx
                  ? ColorConstants.primary
                  : ColorConstants.primary.withValues(alpha: 0.2),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQueueEntry(
    ThemeData theme,
    bool isDark,
    Map<String, dynamic> entry,
  ) {
    final bidderName = entry['bidder_name'] as String? ?? 'Unknown';
    final bidType = entry['bid_type'] as String? ?? 'manual';
    final bidAmount = (entry['bid_amount'] as num?)?.toDouble();
    final status = entry['status'] as String? ?? 'waiting';
    final position = entry['position'] as int?;

    final statusInfo = _getEntryStatusInfo(status);
    final isAuto = bidType == 'auto';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // Position
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusInfo.color.withValues(alpha: 0.15),
            ),
            child: Text(
              position != null ? '$position' : '–',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: statusInfo.color,
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Bidder info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      bidderName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isAuto) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AUTO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Bid amount
          if (bidAmount != null)
            Text(
              '₱${_formatNumber(bidAmount)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: ColorConstants.primary,
              ),
            ),
          const SizedBox(width: 8),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: statusInfo.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusInfo.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusInfo.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StateInfo _getStateInfo(String state) {
    switch (state) {
      case 'open':
        return _StateInfo(
          icon: Icons.lock_open,
          label: 'OPEN',
          color: ColorConstants.success,
        );
      case 'locked':
        return _StateInfo(
          icon: Icons.lock,
          label: 'LOCKED',
          color: Colors.orange,
        );
      case 'processing':
        return _StateInfo(
          icon: Icons.hourglass_bottom,
          label: 'PROCESSING',
          color: Colors.blue,
        );
      case 'complete':
        return _StateInfo(
          icon: Icons.check_circle,
          label: 'COMPLETE',
          color: ColorConstants.textSecondaryLight,
        );
      default:
        return _StateInfo(
          icon: Icons.circle_outlined,
          label: state.toUpperCase(),
          color: ColorConstants.textSecondaryLight,
        );
    }
  }

  _StateInfo _getEntryStatusInfo(String status) {
    switch (status) {
      case 'waiting':
        return _StateInfo(
          icon: Icons.hourglass_empty,
          label: 'Waiting',
          color: Colors.orange,
        );
      case 'won':
        return _StateInfo(
          icon: Icons.emoji_events,
          label: 'Won',
          color: ColorConstants.success,
        );
      case 'skipped':
        return _StateInfo(
          icon: Icons.skip_next,
          label: 'Skipped',
          color: ColorConstants.textSecondaryLight,
        );
      case 'processed':
        return _StateInfo(
          icon: Icons.check,
          label: 'Processed',
          color: Colors.blue,
        );
      default:
        return _StateInfo(
          icon: Icons.circle,
          label: status,
          color: ColorConstants.textSecondaryLight,
        );
    }
  }

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatTime(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}

class _StateInfo {
  final IconData icon;
  final String label;
  final Color color;

  const _StateInfo({
    required this.icon,
    required this.label,
    required this.color,
  });
}
