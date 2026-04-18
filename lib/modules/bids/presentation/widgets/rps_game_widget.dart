import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/bids/domain/entities/mystery_tiebreaker_session_entity.dart';

/// Simultaneous rock-paper-scissors game UI.
/// Both players pick secretly; choices are revealed together.
class RpsGameWidget extends StatefulWidget {
  final TiebreakerSessionEntity session;
  final bool isProcessing;
  final bool showReveal;
  final String? revealP1Choice;
  final String? revealP2Choice;
  final void Function(String choice) onSubmitChoice;
  final VoidCallback onRevealDone;

  const RpsGameWidget({
    super.key,
    required this.session,
    required this.isProcessing,
    required this.showReveal,
    this.revealP1Choice,
    this.revealP2Choice,
    required this.onSubmitChoice,
    required this.onRevealDone,
  });

  @override
  State<RpsGameWidget> createState() => _RpsGameWidgetState();
}

class _RpsGameWidgetState extends State<RpsGameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _revealController;
  late Animation<double> _scaleAnim;
  String? _pendingChoice;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _revealController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void didUpdateWidget(RpsGameWidget old) {
    super.didUpdateWidget(old);
    if (widget.showReveal && !old.showReveal) {
      _revealController.forward(from: 0);
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) widget.onRevealDone();
      });
    }
  }

  @override
  void dispose() {
    _revealController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = widget.session;
    final myChoice = session.myRpsChoice;
    final hasChosen = myChoice != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        _RpsHeader(round: session.rpsCurrentRound + 1),
        const SizedBox(height: 20),

        // VS arena
        _buildArena(isDark, session, myChoice, hasChosen),
        const SizedBox(height: 24),

        // Choice buttons or waiting state
        if (!hasChosen && !widget.showReveal)
          _buildChoiceButtons(isDark)
        else if (hasChosen && !session.bothSubmitted && !widget.showReveal)
          _buildWaitingState(isDark, myChoice)
        else if (widget.showReveal)
          _buildRevealState(isDark)
        else
          _buildWaitingState(isDark, myChoice),

        // Round history
        if (session.rpsRounds.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildRoundHistory(isDark, session),
        ],
      ],
    );
  }

  Widget _buildArena(
    bool isDark,
    TiebreakerSessionEntity session,
    String? myChoice,
    bool hasChosen,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withValues(alpha: 0.15),
            Colors.indigo.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // My side
          Expanded(
            child: _ArenaSide(
              label: 'You',
              alias: session.myAlias,
              choice: widget.showReveal ? widget.revealP1Choice : myChoice,
              isRevealing: widget.showReveal,
              scaleAnim: _scaleAnim,
              isMe: true,
            ),
          ),
          // VS divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Round ${session.rpsCurrentRound + 1}',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Opponent side
          Expanded(
            child: _ArenaSide(
              label: 'Opponent',
              alias: '???',
              choice: widget.showReveal ? widget.revealP2Choice : null,
              isRevealing: widget.showReveal,
              scaleAnim: _scaleAnim,
              opponentSubmitted: session.opponentSubmitted,
              isMe: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceButtons(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Make your choice — your opponent won\'t see it until you both submit.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
        if (_pendingChoice != null)
          _buildConfirmRow(isDark)
        else
          Row(
            children: [
              Expanded(
                child: _RpsChoiceButton(choice: 'rock', onTap: _onChoiceTap),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RpsChoiceButton(choice: 'paper', onTap: _onChoiceTap),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RpsChoiceButton(
                  choice: 'scissors',
                  onTap: _onChoiceTap,
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _onChoiceTap(String choice) => setState(() => _pendingChoice = choice);

  Widget _buildConfirmRow(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _pendingChoice = null),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Change'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: widget.isProcessing
                ? null
                : () {
                    widget.onSubmitChoice(_pendingChoice!);
                    setState(() => _pendingChoice = null);
                  },
            style: FilledButton.styleFrom(backgroundColor: Colors.deepPurple),
            icon: widget.isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(_rpsIcon(_pendingChoice!), size: 18),
            label: Text('Lock in ${_rpsLabel(_pendingChoice!)}'),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState(bool isDark, String? myChoice) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              myChoice != null
                  ? 'Waiting for your opponent to submit...'
                  : 'Waiting...',
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealState(bool isDark) {
    final p1 = widget.revealP1Choice ?? '';
    final p2 = widget.revealP2Choice ?? '';
    final isTie = p1 == p2;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isTie
              ? Colors.orange.withValues(alpha: 0.12)
              : ColorConstants.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isTie ? Colors.orange : ColorConstants.success,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isTie ? Icons.sync : Icons.emoji_events,
              color: isTie ? Colors.orange : ColorConstants.success,
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              isTie ? '🤝 It\'s a Tie! Next Round...' : '🎉 Round Result!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isTie ? Colors.orange : ColorConstants.success,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundHistory(bool isDark, TiebreakerSessionEntity session) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Round History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...session.rpsRounds.map(
          (r) => _RoundHistoryRow(round: r, myId: session.myAlias),
        ),
      ],
    );
  }

  IconData _rpsIcon(String choice) => switch (choice) {
    'rock' => Icons.circle,
    'paper' => Icons.article,
    'scissors' => Icons.content_cut,
    _ => Icons.help,
  };

  String _rpsLabel(String choice) => switch (choice) {
    'rock' => 'Rock 🪨',
    'paper' => 'Paper 📄',
    'scissors' => 'Scissors ✂️',
    _ => choice,
  };
}

// ─── Subwidgets ─────────────────────────────────────────────────────────────

class _RpsHeader extends StatelessWidget {
  final int round;
  const _RpsHeader({required this.round});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.sports_esports,
                size: 18,
                color: Colors.deepPurple,
              ),
              const SizedBox(width: 6),
              Text(
                'Rock · Paper · Scissors',
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Round $round',
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _ArenaSide extends StatelessWidget {
  final String label;
  final String alias;
  final String? choice;
  final bool isRevealing;
  final Animation<double> scaleAnim;
  final bool isMe;
  final bool opponentSubmitted;

  const _ArenaSide({
    required this.label,
    required this.alias,
    this.choice,
    required this.isRevealing,
    required this.scaleAnim,
    required this.isMe,
    this.opponentSubmitted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          alias,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        if (choice != null)
          ScaleTransition(
            scale: isRevealing ? scaleAnim : const AlwaysStoppedAnimation(1),
            child: _RpsChoiceDisplay(choice: choice!),
          )
        else
          _ChoicePlaceholder(
            submitted: isMe ? false : opponentSubmitted,
            isMe: isMe,
          ),
      ],
    );
  }
}

class _RpsChoiceDisplay extends StatelessWidget {
  final String choice;
  const _RpsChoiceDisplay({required this.choice});

  @override
  Widget build(BuildContext context) {
    final (icon, color, emoji) = switch (choice) {
      'rock' => (Icons.circle, Colors.grey.shade600, '🪨'),
      'paper' => (Icons.article, Colors.blue.shade400, '📄'),
      'scissors' => (Icons.content_cut, Colors.red.shade400, '✂️'),
      _ => (Icons.help, Colors.grey, '?'),
    };

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }
}

class _ChoicePlaceholder extends StatelessWidget {
  final bool submitted;
  final bool isMe;
  const _ChoicePlaceholder({required this.submitted, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: submitted
            ? Colors.deepPurple.withValues(alpha: 0.15)
            : Colors.grey.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: submitted
              ? Colors.deepPurple.withValues(alpha: 0.5)
              : Colors.grey.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          submitted ? Icons.check_circle : Icons.question_mark,
          color: submitted ? Colors.deepPurple : Colors.grey,
          size: 28,
        ),
      ),
    );
  }
}

class _RpsChoiceButton extends StatelessWidget {
  final String choice;
  final void Function(String) onTap;
  const _RpsChoiceButton({required this.choice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = switch (choice) {
      'rock' => ('🪨', 'Rock', Colors.grey.shade600),
      'paper' => ('📄', 'Paper', Colors.blue.shade400),
      'scissors' => ('✂️', 'Scissors', Colors.red.shade400),
      _ => ('?', choice, Colors.grey),
    };

    return InkWell(
      onTap: () => onTap(choice),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundHistoryRow extends StatelessWidget {
  final RpsRoundEntity round;
  final String myId;
  const _RoundHistoryRow({required this.round, required this.myId});

  @override
  Widget build(BuildContext context) {
    final isTie = round.result == 'tie';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isTie
              ? Colors.orange.withValues(alpha: 0.08)
              : Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              'R${round.round + 1}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            _choiceChip(round.p1Choice),
            const Text(' vs '),
            _choiceChip(round.p2Choice),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
      ),
    );
  }

  Widget _choiceChip(String choice) {
    final emoji = switch (choice) {
      'rock' => '🪨',
      'paper' => '📄',
      'scissors' => '✂️',
      _ => '?',
    };
    return Text(emoji, style: const TextStyle(fontSize: 16));
  }
}
