import 'dart:math';
import 'package:flutter/material.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/utils/auction_alias_generator.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/mystery_bid_entity.dart';

/// Animated tiebreaker widget for mystery auctions.
/// Shows coin flip (2-way tie) or lottery draw (3+ tie).
/// If [isReplay] is true, shows a "REPLAY" indicator.
class MysteryTiebreakerWidget extends StatefulWidget {
  final MysteryTiebreakerEntity tiebreaker;
  final String auctionId;
  final String? currentUserId;
  final bool isReplay;

  const MysteryTiebreakerWidget({
    super.key,
    required this.tiebreaker,
    required this.auctionId,
    this.currentUserId,
    this.isReplay = false,
  });

  @override
  State<MysteryTiebreakerWidget> createState() =>
      _MysteryTiebreakerWidgetState();
}

class _MysteryTiebreakerWidgetState extends State<MysteryTiebreakerWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _glowController;
  bool _animationComplete = false;
  int _highlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startAnimation();
  }

  void _startAnimation() {
    // Use the seed for deterministic "randomness" in the animation
    final seed = int.tryParse(widget.tiebreaker.resultSeed) ?? 1;
    final rng = Random(seed);
    final winnerIndex = widget.tiebreaker.tiedBidderIds.indexOf(
      widget.tiebreaker.winnerId,
    );

    if (widget.tiebreaker.isCoinFlip) {
      _runCoinFlipAnimation(winnerIndex);
    } else {
      _runLotteryAnimation(rng, winnerIndex);
    }
  }

  void _runCoinFlipAnimation(int winnerIndex) async {
    // Spin through candidates rapidly, then settle on winner
    for (int i = 0; i < 8; i++) {
      if (!mounted) return;
      setState(() => _highlightedIndex = i % 2);
      await Future.delayed(Duration(milliseconds: 150 + (i * 40)));
    }
    if (!mounted) return;
    setState(() {
      _highlightedIndex = winnerIndex;
      _animationComplete = true;
    });
    _mainController.forward();
  }

  void _runLotteryAnimation(Random rng, int winnerIndex) async {
    final count = widget.tiebreaker.tiedBidderIds.length;
    // Cycle through all candidates with increasing delay
    for (int i = 0; i < count * 3 + winnerIndex; i++) {
      if (!mounted) return;
      setState(() => _highlightedIndex = i % count);
      final baseDelay = 80 + (i * 20);
      await Future.delayed(Duration(milliseconds: baseDelay.clamp(80, 500)));
    }
    if (!mounted) return;
    setState(() {
      _highlightedIndex = winnerIndex;
      _animationComplete = true;
    });
    _mainController.forward();
  }

  @override
  void dispose() {
    _mainController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  String _aliasFor(String bidderId) {
    if (bidderId == widget.currentUserId) return 'You';
    return AuctionAliasGenerator.generate(widget.auctionId, bidderId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.surfaceDark
            : ColorConstants.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(theme, isDark),
          Padding(
            padding: const EdgeInsets.all(20),
            child: widget.tiebreaker.isCoinFlip
                ? _buildCoinFlipContent(theme, isDark)
                : _buildLotteryContent(theme, isDark),
          ),
          if (_animationComplete) _buildWinnerBanner(theme, isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final isCoin = widget.tiebreaker.isCoinFlip;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(
            isCoin ? Icons.monetization_on : Icons.casino,
            size: 22,
            color: Colors.amber.shade700,
          ),
          const SizedBox(width: 10),
          Text(
            isCoin ? 'Coin Flip Tiebreaker' : 'Lottery Draw Tiebreaker',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.amber.shade800,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (widget.isReplay)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.replay, size: 12, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'REPLAY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoinFlipContent(ThemeData theme, bool isDark) {
    final bidders = widget.tiebreaker.tiedBidderIds;
    return Row(
      children: [
        Expanded(
          child: _buildParticipantCard(
            theme,
            isDark,
            bidders[0],
            0,
            icon: Icons.looks_one,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _animationComplete
                          ? Colors.amber.withValues(alpha: 0.2)
                          : Colors.amber.withValues(
                              alpha: 0.1 + _glowController.value * 0.15,
                            ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      _animationComplete ? Icons.check : Icons.monetization_on,
                      color: Colors.amber.shade700,
                      size: 24,
                    ),
                  );
                },
              ),
              const SizedBox(height: 4),
              Text(
                'VS',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildParticipantCard(
            theme,
            isDark,
            bidders[1],
            1,
            icon: Icons.looks_two,
          ),
        ),
      ],
    );
  }

  Widget _buildLotteryContent(ThemeData theme, bool isDark) {
    final bidders = widget.tiebreaker.tiedBidderIds;
    return Column(
      children: [
        Text(
          '${bidders.length} bidders tied — drawing winner...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: bidders.asMap().entries.map((entry) {
            return _buildLotteryChip(theme, isDark, entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildParticipantCard(
    ThemeData theme,
    bool isDark,
    String bidderId,
    int index, {
    IconData icon = Icons.person,
  }) {
    final isHighlighted = _highlightedIndex == index;
    final isWinner = _animationComplete && isHighlighted;
    final alias = _aliasFor(bidderId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWinner
            ? ColorConstants.success.withValues(alpha: 0.1)
            : isHighlighted
            ? Colors.amber.withValues(alpha: 0.15)
            : (isDark
                  ? ColorConstants.backgroundSecondaryDark
                  : ColorConstants.backgroundSecondaryLight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isWinner
              ? ColorConstants.success
              : isHighlighted
              ? Colors.amber
              : Colors.transparent,
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 28,
            color: isWinner
                ? ColorConstants.success
                : isHighlighted
                ? Colors.amber.shade700
                : (isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight),
          ),
          const SizedBox(height: 8),
          Text(
            alias,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isWinner ? ColorConstants.success : null,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          if (isWinner) ...[
            const SizedBox(height: 4),
            const Icon(
              Icons.emoji_events,
              size: 18,
              color: ColorConstants.success,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLotteryChip(
    ThemeData theme,
    bool isDark,
    String bidderId,
    int index,
  ) {
    final isHighlighted = _highlightedIndex == index;
    final isWinner = _animationComplete && isHighlighted;
    final alias = _aliasFor(bidderId);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isWinner
            ? ColorConstants.success.withValues(alpha: 0.15)
            : isHighlighted
            ? Colors.amber.withValues(alpha: 0.2)
            : (isDark
                  ? ColorConstants.backgroundSecondaryDark
                  : ColorConstants.backgroundSecondaryLight),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWinner
              ? ColorConstants.success
              : isHighlighted
              ? Colors.amber
              : (isDark
                    ? ColorConstants.borderDark
                    : ColorConstants.borderLight),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(right: 6),
              child: Icon(
                Icons.emoji_events,
                size: 14,
                color: ColorConstants.success,
              ),
            ),
          Text(
            alias,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
              color: isWinner
                  ? ColorConstants.success
                  : isHighlighted
                  ? Colors.amber.shade800
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner(ThemeData theme, bool isDark) {
    final winnerAlias = _aliasFor(widget.tiebreaker.winnerId);
    final isCurrentUserWinner =
        widget.tiebreaker.winnerId == widget.currentUserId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: ColorConstants.success.withValues(alpha: 0.1),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            color: ColorConstants.success,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            isCurrentUserWinner
                ? 'You won the tiebreaker! 🎉'
                : '$winnerAlias wins the tiebreaker!',
            style: theme.textTheme.titleSmall?.copyWith(
              color: ColorConstants.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
