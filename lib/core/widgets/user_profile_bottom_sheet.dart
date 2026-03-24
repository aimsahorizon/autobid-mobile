import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/modules/profile/data/models/user_profile_model.dart';
import 'package:autobid_mobile/modules/profile/data/datasources/profile_supabase_datasource.dart';

/// Bottom sheet to view another user's public profile and stats.
/// Shows bidding rate, transaction success/cancellation rate.
class UserProfileBottomSheet extends StatefulWidget {
  final String userId;

  /// Whether to show bidding stats (hide for buyer-to-buyer context)
  final bool showBiddingRate;

  const UserProfileBottomSheet({
    super.key,
    required this.userId,
    this.showBiddingRate = true,
  });

  /// Show the bottom sheet from any context
  static Future<void> show(
    BuildContext context, {
    required String userId,
    bool showBiddingRate = true,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileBottomSheet(
        userId: userId,
        showBiddingRate: showBiddingRate,
      ),
    );
  }

  @override
  State<UserProfileBottomSheet> createState() => _UserProfileBottomSheetState();
}

class _UserProfileBottomSheetState extends State<UserProfileBottomSheet> {
  UserProfileModel? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final datasource = ProfileSupabaseDataSource(Supabase.instance.client);
    final profile = await datasource.getUserBiddingStats(widget.userId);
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            )
          else if (_profile == null)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Text('Could not load profile'),
            )
          else
            _buildProfileContent(theme, isDark),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildProfileContent(ThemeData theme, bool isDark) {
    final p = _profile!;
    final location = [
      p.province,
      p.city,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar + Name
          CircleAvatar(
            radius: 36,
            backgroundColor: ColorConstants.primary.withValues(alpha: 0.1),
            backgroundImage: p.profilePhotoUrl.isNotEmpty
                ? CachedNetworkImageProvider(p.profilePhotoUrl)
                : null,
            child: p.profilePhotoUrl.isEmpty
                ? Text(
                    p.fullName.isNotEmpty ? p.fullName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            p.fullName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (p.username.isNotEmpty)
            Text(
              '@${p.username}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          if (location.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
                const SizedBox(width: 2),
                Text(
                  location,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),

          // Stats grid
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? ColorConstants.backgroundDark
                  : ColorConstants.backgroundSecondaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                if (widget.showBiddingRate) ...[
                  _buildSectionLabel(
                    'Bidding Activity',
                    Icons.gavel,
                    theme,
                    isDark,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatTile('Bids', '${p.totalBids ?? 0}', isDark),
                      _buildStatTile('Wins', '${p.totalWins ?? 0}', isDark),
                      _buildStatTile(
                        'Win Rate',
                        '${(p.biddingRate ?? 0).toStringAsFixed(1)}%',
                        isDark,
                        color: _rateColor(p.biddingRate ?? 0),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                ],
                _buildSectionLabel(
                  'Transaction History',
                  Icons.handshake,
                  theme,
                  isDark,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildStatTile(
                      'Total',
                      '${p.totalTransactions ?? 0}',
                      isDark,
                    ),
                    _buildStatTile(
                      'Success',
                      '${(p.successRate ?? 0).toStringAsFixed(1)}%',
                      isDark,
                      color: _rateColor(p.successRate ?? 0),
                    ),
                    _buildStatTile(
                      'Cancelled',
                      '${(p.cancellationRate ?? 0).toStringAsFixed(1)}%',
                      isDark,
                      color: _cancelColor(p.cancellationRate ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(
    String label,
    IconData icon,
    ThemeData theme,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ColorConstants.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark
                ? ColorConstants.textSecondaryDark
                : ColorConstants.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  color ??
                  (isDark
                      ? ColorConstants.textPrimaryDark
                      : ColorConstants.textPrimaryLight),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Color _rateColor(double rate) {
    if (rate >= 70) return ColorConstants.success;
    if (rate >= 40) return ColorConstants.warning;
    return ColorConstants.error;
  }

  Color _cancelColor(double rate) {
    if (rate <= 10) return ColorConstants.success;
    if (rate <= 30) return ColorConstants.warning;
    return ColorConstants.error;
  }
}
