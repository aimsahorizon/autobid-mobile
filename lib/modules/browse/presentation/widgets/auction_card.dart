import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/browse/domain/entities/auction_entity.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/profile_supabase_datasource.dart';
import 'package:autobid_mobile/modules/profile/domain/entities/user_profile_entity.dart';

bool _isAssetPath(String url) => url.startsWith('assets/');

class AuctionCard extends StatelessWidget {
  final AuctionEntity auction;
  final VoidCallback? onTap;
  final bool isListLayout;

  const AuctionCard({
    super.key,
    required this.auction,
    this.onTap,
    this.isListLayout = false,
  });

  String _formatTimeRemaining() {
    final minutes = auction.timeRemainingMinutes;

    if (minutes < 0) return 'Ended';
    if (minutes == 0) return '< 1 min';
    if (minutes == 1) return '< 2 mins';
    if (minutes < 60) return '$minutes mins';

    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hrs';

    final days = hours ~/ 24;
    return '$days days';
  }

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark
              ? ColorConstants.borderDark
              : ColorConstants.borderLight,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: isListLayout
            ? _buildListLayout(theme, isDark)
            : _buildGridLayout(theme, isDark),
      ),
    );
  }

  Widget _buildListLayout(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(isListLayout: true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCarName(theme),
                const SizedBox(height: 4),
                _buildSellerInfo(theme, isDark),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildCurrentBid(theme), _buildTimeRemaining()],
                ),
                const SizedBox(height: 8),
                _buildStats(theme, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLayout(ThemeData theme, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildImage(),
        Flexible(
          fit: FlexFit.loose,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCarName(theme),
                const SizedBox(height: 6),
                _buildSellerInfo(theme, isDark),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [_buildCurrentBid(theme), _buildTimeRemaining()],
                ),
                const SizedBox(height: 8),
                _buildStats(theme, isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage({bool isListLayout = false}) {
    final isExclusive = auction.visibility == 'exclusive';
    final isMystery = auction.visibility == 'mystery';

    final imageChild = _isAssetPath(auction.carImageUrl)
        ? Image.asset(
            auction.carImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: ColorConstants.backgroundSecondaryLight,
              child: const Icon(
                Icons.directions_car,
                size: 48,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
          )
        : CachedNetworkImage(
            imageUrl: auction.carImageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: ColorConstants.backgroundSecondaryLight,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: ColorConstants.backgroundSecondaryLight,
              child: const Icon(
                Icons.directions_car,
                size: 48,
                color: ColorConstants.textSecondaryLight,
              ),
            ),
          );

    final badge = Positioned(
      top: 8,
      left: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isExclusive
              ? ColorConstants.warning.withValues(alpha: 0.9)
              : isMystery
              ? Colors.purple.withValues(alpha: 0.9)
              : ColorConstants.success.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExclusive
                  ? Icons.lock_outline
                  : isMystery
                  ? Icons.visibility_off
                  : Icons.public,
              size: 12,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              isExclusive
                  ? 'Exclusive'
                  : isMystery
                  ? 'Mystery'
                  : 'Open',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

    if (isListLayout) {
      return Stack(fit: StackFit.expand, children: [imageChild, badge]);
    }

    // Grid layout: AspectRatio must wrap the Stack so the Column child has
    // bounded height. StackFit.expand is safe once the Stack is constrained.
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(fit: StackFit.expand, children: [imageChild, badge]),
    );
  }

  Widget _buildCarName(ThemeData theme) {
    return Text(
      auction.carName,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        height: 1.2,
      ),
    );
  }

  Widget _buildSellerInfo(ThemeData theme, bool isDark) {
    final sellerName = (auction.sellerDisplayName ?? '').trim();
    if (sellerName.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        if ((auction.sellerProfileImageUrl ?? '').isNotEmpty)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: auction.sellerProfileImageUrl!,
              width: 18,
              height: 18,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Icon(
                Icons.person_rounded,
                size: 18,
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          )
        else
          Icon(
            Icons.person_rounded,
            size: 18,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            sellerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentBid(ThemeData theme) {
    final isMystery = auction.visibility == 'mystery';

    if (isMystery) {
      return Text(
        '₱${_formatPrice(auction.currentBid)}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      );
    }
    return Text(
      '₱${_formatPrice(auction.currentBid)}',
      style: theme.textTheme.titleMedium?.copyWith(
        color: ColorConstants.primary,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  Widget _buildTimeRemaining() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: auction.hasEnded
            ? ColorConstants.error.withValues(alpha: 0.1)
            : ColorConstants.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 12,
            color: auction.hasEnded
                ? ColorConstants.error
                : ColorConstants.success,
          ),
          const SizedBox(width: 4),
          Text(
            _formatTimeRemaining(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: auction.hasEnded
                  ? ColorConstants.error
                  : ColorConstants.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(ThemeData theme, bool isDark) {
    return _SellerStatsRow(
      sellerId: auction.sellerId,
      theme: theme,
      isDark: isDark,
    );
  }
}

// ---------------------------------------------------------------------------
// Seller stats row — lazily fetches seller reputation via getUserBiddingStats
// ---------------------------------------------------------------------------

class _SellerStatsRow extends StatefulWidget {
  final String sellerId;
  final ThemeData theme;
  final bool isDark;

  const _SellerStatsRow({
    required this.sellerId,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_SellerStatsRow> createState() => _SellerStatsRowState();
}

class _SellerStatsRowState extends State<_SellerStatsRow> {
  late final Future<UserProfileEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = ProfileSupabaseDataSource(
      Supabase.instance.client,
    ).getUserBiddingStats(widget.sellerId);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark
        ? ColorConstants.textSecondaryDark
        : ColorConstants.textSecondaryLight;
    final style = widget.theme.textTheme.bodySmall?.copyWith(
      color: textColor,
      fontWeight: FontWeight.w500,
      fontSize: 11,
    );

    return FutureBuilder<UserProfileEntity?>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 28);
        }
        final p = snapshot.data!;
        final totalBids = p.totalBids ?? 0;
        final totalWins = p.totalWins ?? 0;
        final biddingRate = p.biddingRate ?? 0.0;
        final totalDeals = p.totalTransactions ?? 0;
        final successRate = p.successRate ?? 0.0;
        final cancelRate = p.cancellationRate ?? 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1 — Bidding Activity
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_rounded, size: 12, color: textColor),
                const SizedBox(width: 3),
                Text('$totalBids bids', style: style),
                const SizedBox(width: 8),
                Icon(Icons.emoji_events_rounded, size: 12, color: textColor),
                const SizedBox(width: 3),
                Text('$totalWins wins', style: style),
                if (biddingRate > 0) ...[
                  const SizedBox(width: 6),
                  _RateBadge(rate: biddingRate, color: ColorConstants.primary),
                ],
                const SizedBox(width: 8),
                Icon(Icons.handshake_rounded, size: 12, color: textColor),
                Text('$totalDeals deals', style: style),
              ],
            ),
            const SizedBox(height: 3),
            // Row 2 — Transaction History
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (successRate > 0) ...[
                  const SizedBox(width: 6),
                  _RateBadge(
                    rate: successRate,
                    color: ColorConstants.success,
                    prefix: 'Success: ',
                  ),
                ],
                if (cancelRate > 5) ...[
                  const SizedBox(width: 4),
                  _RateBadge(
                    rate: cancelRate,
                    color: ColorConstants.error,
                    prefix: 'Cancel: ',
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RateBadge extends StatelessWidget {
  final double rate;
  final Color color;
  final String prefix;

  const _RateBadge({required this.rate, required this.color, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$prefix${rate.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
