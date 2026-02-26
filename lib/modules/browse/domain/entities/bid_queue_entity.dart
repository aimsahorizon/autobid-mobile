/// Entity representing the state of a bid queue cycle for an auction.
///
/// The Raise Hand queue operates in cycles:
/// - [idle]       — No cycle active, waiting for first raise hand
/// - [open]       — Grace period: manual bidders can raise hand (queue-only)
/// - [processing] — Turn-based: each bidder gets 60s to place a manual bid
/// - [complete]   — Cycle finished, will restart on next raise hand
class BidQueueCycleEntity {
  final String state; // idle, open, locked, processing, complete
  final int cycleNumber;
  final List<BidQueueEntry> queue;
  final int remainingMs; // grace period remaining in milliseconds
  final String? activeTurnBidderId; // who currently has the floor (60s)
  final int turnRemainingMs; // milliseconds left in active turn
  final DateTime? openedAt;
  final DateTime? lockedAt;
  final DateTime? processingAt;
  final DateTime? completedAt;

  const BidQueueCycleEntity({
    required this.state,
    required this.cycleNumber,
    required this.queue,
    required this.remainingMs,
    this.activeTurnBidderId,
    this.turnRemainingMs = 0,
    this.openedAt,
    this.lockedAt,
    this.processingAt,
    this.completedAt,
  });

  /// Whether manual bidders can currently raise their hand.
  /// Always true except during brief processing — concurrent cycles allow
  /// raising hand for the NEXT cycle while current one processes.
  bool get canRaiseHand => true;

  /// Whether the queue is currently being processed
  bool get isProcessing => state == 'processing' || state == 'locked';

  /// Whether this is a fresh/idle state (no active cycle)
  bool get isIdle => state == 'idle';

  /// Whether a turn is currently active (someone has the floor)
  bool get hasTurnActive => activeTurnBidderId != null && turnRemainingMs > 0;

  factory BidQueueCycleEntity.idle() => const BidQueueCycleEntity(
    state: 'idle',
    cycleNumber: 0,
    queue: [],
    remainingMs: 0,
  );

  factory BidQueueCycleEntity.fromJson(Map<String, dynamic> json) {
    final queueList = json['queue'] as List<dynamic>? ?? [];
    return BidQueueCycleEntity(
      state: json['state'] as String? ?? 'idle',
      cycleNumber: json['cycle_number'] as int? ?? 0,
      queue: queueList
          .map((e) => BidQueueEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
      remainingMs: json['remaining_ms'] as int? ?? 0,
      activeTurnBidderId: json['active_turn_bidder_id'] as String?,
      turnRemainingMs: json['turn_remaining_ms'] as int? ?? 0,
      openedAt: json['opened_at'] != null
          ? DateTime.tryParse(json['opened_at'] as String)
          : null,
      lockedAt: json['locked_at'] != null
          ? DateTime.tryParse(json['locked_at'] as String)
          : null,
      processingAt: json['processing_at'] != null
          ? DateTime.tryParse(json['processing_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.tryParse(json['completed_at'] as String)
          : null,
    );
  }
}

/// A single entry in the bid queue (one raise-hand or auto-bidder injection).
class BidQueueEntry {
  final String id;
  final String bidderId;
  final String type; // 'manual' or 'auto'
  final String
  status; // 'pending', 'active_turn', 'executed', 'skipped', 'expired', 'withdrawn', 'failed'
  final int position;
  final double? bidAmount;
  final DateTime? turnStartedAt;

  const BidQueueEntry({
    required this.id,
    required this.bidderId,
    required this.type,
    required this.status,
    required this.position,
    this.bidAmount,
    this.turnStartedAt,
  });

  bool get isManual => type == 'manual';
  bool get isAuto => type == 'auto';
  bool get isPending => status == 'pending';
  bool get isActiveTurn => status == 'active_turn';
  bool get isExecuted => status == 'executed';
  bool get isSkipped => status == 'skipped';
  bool get isWithdrawn => status == 'withdrawn';
  bool get isExpired => status == 'expired';

  factory BidQueueEntry.fromJson(Map<String, dynamic> json) {
    return BidQueueEntry(
      id: json['id'] as String? ?? '',
      bidderId: json['bidder_id'] as String? ?? '',
      type: json['type'] as String? ?? 'manual',
      status: json['status'] as String? ?? 'pending',
      position: json['position'] as int? ?? 0,
      bidAmount: (json['bid_amount'] as num?)?.toDouble(),
      turnStartedAt: json['turn_started_at'] != null
          ? DateTime.tryParse(json['turn_started_at'] as String)
          : null,
    );
  }
}
