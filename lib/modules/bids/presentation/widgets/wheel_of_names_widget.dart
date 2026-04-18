import 'dart:math';
import 'package:flutter/material.dart';

/// Animated spinning wheel of names for 3+ player mystery tiebreakers.
/// Deterministic: same [seed] always produces same winner highlight.
/// Shows a REPLAY badge when [isReplay] is true.
class WheelOfNamesWidget extends StatefulWidget {
  final List<String> aliases;
  final int winnerIndex; // 1-based, matching DB wheel_winner_index
  final String seed;
  final bool isReplay;
  final bool autoSpin;

  const WheelOfNamesWidget({
    super.key,
    required this.aliases,
    required this.winnerIndex,
    required this.seed,
    this.isReplay = false,
    this.autoSpin = true,
  });

  @override
  State<WheelOfNamesWidget> createState() => _WheelOfNamesWidgetState();
}

class _WheelOfNamesWidgetState extends State<WheelOfNamesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  bool _spinStarted = false;
  bool _spinComplete = false;

  static const _segmentColors = [
    Color(0xFF6C5CE7),
    Color(0xFF00B894),
    Color(0xFFE17055),
    Color(0xFF0984E3),
    Color(0xFFFFBE76),
    Color(0xFFB03A2E),
    Color(0xFF1E8BC3),
    Color(0xFF27AE60),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );

    _buildRotationAnim();

    if (widget.autoSpin) {
      Future.delayed(const Duration(milliseconds: 600), _spin);
    }
  }

  void _buildRotationAnim() {
    final count = widget.aliases.length;
    final segmentAngle = 2 * pi / count;
    // Winner segment center in radians (0 = top after rotation adjustment)
    // winnerIndex is 1-based. Segment i starts at i * segmentAngle from top.
    final targetAngle = (widget.winnerIndex - 1) * segmentAngle;
    // Total rotation: many full spins + land on target
    // The wheel stops so winner is at top (pointer at 12 o'clock)
    // Pointer is at top, segment 0 starts at top.
    final fullSpins = 5 * 2 * pi;
    final endAngle = fullSpins + (2 * pi - targetAngle) + segmentAngle / 2;

    _rotation = Tween<double>(begin: 0, end: endAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  void _spin() {
    if (_spinStarted) return;
    _spinStarted = true;
    _controller.forward().then((_) {
      if (mounted) setState(() => _spinComplete = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final winnerAlias =
        widget.aliases.isNotEmpty &&
            widget.winnerIndex >= 1 &&
            widget.winnerIndex <= widget.aliases.length
        ? widget.aliases[widget.winnerIndex - 1]
        : 'Unknown';

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rotate_right, color: Color(0xFF6C5CE7), size: 20),
            const SizedBox(width: 8),
            Text(
              'Wheel of Names',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6C5CE7),
              ),
            ),
            if (widget.isReplay) ...[const SizedBox(width: 8), _ReplayBadge()],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Seed: ${widget.seed.substring(0, min(8, widget.seed.length))}...',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Wheel + pointer
        Stack(
          alignment: Alignment.topCenter,
          children: [
            AnimatedBuilder(
              animation: _rotation,
              builder: (_, __) => Transform.rotate(
                angle: _rotation.value,
                child: _WheelPainterWidget(
                  aliases: widget.aliases,
                  colors: _segmentColors,
                ),
              ),
            ),
            // Pointer arrow at 12 o'clock
            Positioned(
              top: 0,
              child: Icon(
                Icons.arrow_drop_down,
                size: 40,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Winner banner (after spin)
        if (_spinComplete)
          _WinnerBanner(alias: winnerAlias)
        else if (!_spinStarted)
          FilledButton.icon(
            onPressed: _spin,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF6C5CE7),
            ),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Spin the Wheel!'),
          ),

        // Participants list
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: widget.aliases.asMap().entries.map((e) {
            final color = _segmentColors[e.key % _segmentColors.length];
            final isWinner = _spinComplete && e.key == widget.winnerIndex - 1;
            return Chip(
              avatar: CircleAvatar(
                backgroundColor: color,
                radius: 8,
                child: isWinner
                    ? const Icon(
                        Icons.emoji_events,
                        size: 10,
                        color: Colors.white,
                      )
                    : null,
              ),
              label: Text(
                e.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              backgroundColor: isWinner ? color.withValues(alpha: 0.15) : null,
              side: isWinner ? BorderSide(color: color, width: 1.5) : null,
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WheelPainterWidget extends StatelessWidget {
  final List<String> aliases;
  final List<Color> colors;

  const _WheelPainterWidget({required this.aliases, required this.colors});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 260,
      child: CustomPaint(
        painter: _WheelPainter(aliases: aliases, colors: colors),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<String> aliases;
  final List<Color> colors;

  const _WheelPainter({required this.aliases, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final count = aliases.length;
    final sweep = 2 * pi / count;

    for (int i = 0; i < count; i++) {
      final startAngle = i * sweep - pi / 2;
      final color = colors[i % colors.length];

      // Draw segment
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );

      // Segment border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        borderPaint,
      );

      // Label
      final mid = startAngle + sweep / 2;
      final labelR = radius * 0.62;
      final labelPos = Offset(
        center.dx + labelR * cos(mid),
        center.dy + labelR * sin(mid),
      );

      final alias = aliases[i];
      final display = alias.length > 10 ? '${alias.substring(0, 9)}…' : alias;

      final tp = TextPainter(
        text: TextSpan(
          text: display,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 2, color: Colors.black54)],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: radius * 0.6);

      canvas.save();
      canvas.translate(labelPos.dx, labelPos.dy);
      canvas.rotate(mid + pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }

    // Center circle
    canvas.drawCircle(center, 18, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      18,
      Paint()
        ..color = Colors.deepPurple.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.aliases != aliases || old.colors != colors;
}

class _WinnerBanner extends StatelessWidget {
  final String alias;
  const _WinnerBanner({required this.alias});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF00B894)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text('🎉', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 6),
          const Text(
            'Winner!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            alias,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReplayBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.replay, size: 12, color: Colors.orange),
          SizedBox(width: 3),
          Text(
            'REPLAY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
