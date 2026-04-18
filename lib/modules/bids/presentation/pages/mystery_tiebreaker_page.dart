import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/mystery_tiebreaker_session_entity.dart';
import 'package:autobid_mobile/modules/bids/presentation/controllers/mystery_tiebreaker_controller.dart';
import 'package:autobid_mobile/modules/bids/presentation/widgets/rps_game_widget.dart';
import 'package:autobid_mobile/modules/bids/presentation/widgets/wheel_of_names_widget.dart';

/// Full-page tiebreaker experience for mystery auctions.
/// Buyer sees: ready countdown, RPS game or wheel spin.
/// Seller sees: participant status, RPS log, wheel result.
class MysteryTiebreakerPage extends StatefulWidget {
  final String auctionId;
  final String? currentUserId;
  final bool isSeller;

  const MysteryTiebreakerPage({
    super.key,
    required this.auctionId,
    this.currentUserId,
    this.isSeller = false,
  });

  @override
  State<MysteryTiebreakerPage> createState() => _MysteryTiebreakerPageState();
}

class _MysteryTiebreakerPageState extends State<MysteryTiebreakerPage> {
  late MysteryTiebreakerController _controller;
  Timer? _countdownTimer;
  Timer? _timeoutChecker;

  @override
  void initState() {
    super.initState();
    _controller = MysteryTiebreakerController(
      auctionId: widget.auctionId,
      currentUserId: widget.currentUserId,
    );
    _controller.init();
    _controller.addListener(_onControllerUpdate);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _timeoutChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      _controller.checkTimeout();
    });
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _timeoutChecker?.cancel();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mystery Tiebreaker'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.load(),
          ),
        ],
      ),
      body: _controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _controller.session == null
          ? _buildNoSession()
          : _buildContent(isDark),
    );
  }

  Widget _buildNoSession() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_open, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'No active tiebreaker',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'The tiebreaker may have already been resolved.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _controller.load(),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final session = _controller.session!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TiebreakerHeader(session: session, isSeller: widget.isSeller),
          const SizedBox(height: 20),
          _buildBody(isDark, session),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark, TiebreakerSessionEntity session) {
    return switch (session.status) {
      TiebreakerStatus.waitingReady => _buildWaitingReady(isDark, session),
      TiebreakerStatus.rpsInProgress => _buildRps(isDark, session),
      TiebreakerStatus.wheelInProgress => _buildWheel(isDark, session, false),
      TiebreakerStatus.completed => _buildCompleted(isDark, session),
      TiebreakerStatus.dqAll => _buildDqAll(isDark),
    };
  }

  // ─── Waiting Ready ─────────────────────────────────────────────────────────

  Widget _buildWaitingReady(bool isDark, TiebreakerSessionEntity session) {
    final isRps = session.type == TiebreakerType.rps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CountdownCard(
          deadline: session.readyDeadline,
          label: isRps
              ? '1-hour window to set Ready'
              : '12-hour window to set Ready',
        ),
        const SizedBox(height: 20),
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isRps
                        ? 'Rock-Paper-Scissors Rules'
                        : 'Wheel of Names Rules',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (isRps) ...[
                _infoRow('Both players must set Ready within 1 hour.'),
                _infoRow('1 ready → automatic win. 0 ready → both DQ\'d.'),
                _infoRow(
                  'Both ready → simultaneous RPS. Endless rounds until winner.',
                ),
              ] else ...[
                _infoRow(
                  'All ${session.initialTiedCount} players must set Ready within 12 hours.',
                ),
                _infoRow('If all set ready → wheel spins immediately.'),
                _infoRow('Non-ready players are excluded from the wheel.'),
                _infoRow('0 ready after deadline → all DQ\'d, next bid tier.'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Ready list
        _ReadyList(session: session),
        const SizedBox(height: 20),
        // Ready button (participant only)
        if (session.isParticipant && !session.isReady && !widget.isSeller)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              onPressed: _controller.isProcessing ? null : _onSetReady,
              style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
              icon: _controller.isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Set Ready', style: TextStyle(fontSize: 16)),
            ),
          )
        else if (session.isReady)
          _ReadyConfirmBanner(),
        if (_controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _controller.errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Future<void> _onSetReady() async {
    final ok = await _controller.setReady();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Failed to set ready'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  // ─── RPS ────────────────────────────────────────────────────────────────────

  Widget _buildRps(bool isDark, TiebreakerSessionEntity session) {
    if (widget.isSeller) {
      return _buildSellerRpsView(isDark, session);
    }
    if (!session.isParticipant) {
      return _buildSpectatorView(isDark, 'RPS in progress...');
    }
    return RpsGameWidget(
      session: session,
      isProcessing: _controller.isProcessing,
      showReveal: _controller.showReveal,
      revealP1Choice: _controller.lastRevealedP1Choice,
      revealP2Choice: _controller.lastRevealedP2Choice,
      onSubmitChoice: _onSubmitRpsChoice,
      onRevealDone: _controller.clearReveal,
    );
  }

  Future<void> _onSubmitRpsChoice(String choice) async {
    final ok = await _controller.submitChoice(choice);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Failed to submit choice'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  Widget _buildSellerRpsView(bool isDark, TiebreakerSessionEntity session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SellerViewBanner(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? ColorConstants.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Round ${session.rpsCurrentRound + 1} in progress',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              // Show ready aliases
              ...session.readyAliases.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 16),
                      const SizedBox(width: 6),
                      Text(p.alias),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (session.rpsRounds.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'Round Log',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...session.rpsRounds.asMap().entries.map(
            (e) => _SellerRpsRoundTile(
              round: e.value,
              readyAliases: session.readyAliases,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Wheel ─────────────────────────────────────────────────────────────────

  Widget _buildWheel(
    bool isDark,
    TiebreakerSessionEntity session,
    bool isReplay,
  ) {
    final aliases = session.readyAliases.map((p) => p.alias).toList();
    final idx = session.wheelWinnerIndex ?? 1;
    final seed = session.wheelSeed ?? session.id;

    return Column(
      children: [
        if (widget.isSeller) _SellerViewBanner(),
        const SizedBox(height: 16),
        WheelOfNamesWidget(
          aliases: aliases,
          winnerIndex: idx,
          seed: seed,
          isReplay: isReplay || widget.isSeller,
          autoSpin: true,
        ),
        if (session.wheelSeed != null) ...[
          const SizedBox(height: 16),
          _SeedInfoCard(seed: session.wheelSeed!),
        ],
      ],
    );
  }

  // ─── Completed ─────────────────────────────────────────────────────────────

  Widget _buildCompleted(bool isDark, TiebreakerSessionEntity session) {
    final isWinner = session.winnerId == widget.currentUserId;
    final isTieType = session.type == TiebreakerType.wheel;

    return Column(
      children: [
        // Result banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isWinner
                  ? [const Color(0xFF00B894), const Color(0xFF00CEC9)]
                  : [Colors.grey.shade600, Colors.grey.shade700],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                isWinner ? '🏆' : '😔',
                style: const TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 12),
              Text(
                isWinner ? 'You Won!' : 'Better Luck Next Time',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isWinner
                    ? 'Congratulations! You\'re the highest bidder.'
                    : 'The tiebreaker did not go your way.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Show wheel replay or RPS log
        if (isTieType && session.wheelSeed != null) ...[
          const Text(
            'Watch the Replay',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildWheel(isDark, session, true),
        ] else if (session.rpsRounds.isNotEmpty) ...[
          const Text(
            'RPS Summary',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          ...session.rpsRounds.map(
            (r) => _SellerRpsRoundTile(
              round: r,
              readyAliases: session.readyAliases,
            ),
          ),
        ],
      ],
    );
  }

  // ─── DQ All ─────────────────────────────────────────────────────────────────

  Widget _buildDqAll(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 64, color: Colors.red.shade400),
            const SizedBox(height: 16),
            const Text(
              'All Participants Disqualified',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No one set Ready within the deadline. Deposits have been refunded. '
              'The system is proceeding to the next tier of bidders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpectatorView(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.sports_esports, size: 48, color: Colors.deepPurple),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _infoRow(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: Colors.deepPurple)),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );
}

// ─── Reusable subwidgets ─────────────────────────────────────────────────────

class _TiebreakerHeader extends StatelessWidget {
  final TiebreakerSessionEntity session;
  final bool isSeller;

  const _TiebreakerHeader({required this.session, required this.isSeller});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.15),
            Colors.indigo.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                session.type == TiebreakerType.rps
                    ? Icons.sports_esports
                    : Icons.rotate_right,
                color: Colors.deepPurple,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                session.type == TiebreakerType.rps
                    ? 'Rock-Paper-Scissors'
                    : 'Wheel of Names',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              _StatusChip(status: session.status),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.people_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '${session.initialTiedCount} tied at ₱${session.tiedAmount.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          if (!isSeller) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.badge_outlined, size: 16, color: Colors.deepPurple),
                const SizedBox(width: 4),
                Text(
                  'Your alias: ${session.myAlias}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final TiebreakerStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      TiebreakerStatus.waitingReady => ('Waiting Ready', Colors.orange),
      TiebreakerStatus.rpsInProgress => ('RPS Live', Colors.green),
      TiebreakerStatus.wheelInProgress => ('Wheel Spinning', Colors.blue),
      TiebreakerStatus.completed => ('Completed', Colors.green),
      TiebreakerStatus.dqAll => ('DQ\'d', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

class _CountdownCard extends StatelessWidget {
  final DateTime deadline;
  final String label;
  const _CountdownCard({required this.deadline, required this.label});

  @override
  Widget build(BuildContext context) {
    final remaining = deadline.difference(DateTime.now());
    final passed = remaining.isNegative;
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final s = remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: passed
            ? Colors.red.withValues(alpha: 0.1)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: passed
              ? Colors.red.withValues(alpha: 0.4)
              : Colors.orange.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            passed ? Icons.timer_off : Icons.timer,
            color: passed ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: passed ? Colors.red : Colors.orange,
                  ),
                ),
                Text(
                  passed
                      ? 'Deadline passed'
                      : '${h}h ${m.toString().padLeft(2, '0')}m ${s.toString().padLeft(2, '0')}s remaining',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: passed ? Colors.red : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyList extends StatelessWidget {
  final TiebreakerSessionEntity session;
  const _ReadyList({required this.session});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Ready: ${session.readyCount} / ${session.initialTiedCount}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: session.initialTiedCount > 0
                    ? session.readyCount / session.initialTiedCount
                    : 0,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: Colors.deepPurple,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...session.readyAliases.map(
          (p) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(p.alias, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyConfirmBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text(
            'You are ready!',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

class _SellerViewBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility, size: 14, color: Colors.deepPurple),
          SizedBox(width: 6),
          Text(
            'Seller View',
            style: TextStyle(
              fontSize: 12,
              color: Colors.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeedInfoCard extends StatelessWidget {
  final String seed;
  const _SeedInfoCard({required this.seed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.key, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wheel Seed (for verification)',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                SelectableText(
                  seed,
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerRpsRoundTile extends StatelessWidget {
  final RpsRoundEntity round;
  final List<ReadyParticipant> readyAliases;

  const _SellerRpsRoundTile({required this.round, required this.readyAliases});

  String _aliasFor(String uid) {
    return readyAliases
            .where((p) => p.userId == uid)
            .map((p) => p.alias)
            .firstOrNull ??
        uid.substring(0, 8);
  }

  @override
  Widget build(BuildContext context) {
    final isTie = round.result == 'tie';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isTie
            ? Colors.orange.withValues(alpha: 0.08)
            : Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.deepPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${round.round + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_aliasFor(round.p1Id)}: ${_choiceEmoji(round.p1Choice)}  vs  '
                  '${_aliasFor(round.p2Id)}: ${_choiceEmoji(round.p2Choice)}',
                  style: const TextStyle(fontSize: 13),
                ),
                if (!isTie && round.winnerId != null)
                  Text(
                    'Winner: ${_aliasFor(round.winnerId!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isTie
                  ? Colors.orange.withValues(alpha: 0.15)
                  : Colors.green.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isTie ? 'Tie' : 'Done',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isTie ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _choiceEmoji(String c) => switch (c) {
    'rock' => '🪨',
    'paper' => '📄',
    'scissors' => '✂️',
    _ => c,
  };
}
