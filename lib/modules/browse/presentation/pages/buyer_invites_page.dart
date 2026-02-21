import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../controllers/buyer_invites_controller.dart';

/// Page for buyers to view and respond to auction invites
class BuyerInvitesPage extends StatefulWidget {
  const BuyerInvitesPage({super.key});

  @override
  State<BuyerInvitesPage> createState() => _BuyerInvitesPageState();
}

class _BuyerInvitesPageState extends State<BuyerInvitesPage> {
  late final BuyerInvitesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<BuyerInvitesController>();
    _controller.loadInvites();
    _controller.subscribeToInvites();
  }

  @override
  void dispose() {
    // Don't dispose — controller is a singleton shared for badge count
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Auction Invites'), centerTitle: true),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.invites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null && _controller.invites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    _controller.errorMessage!,
                    style: TextStyle(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _controller.loadInvites,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_controller.invites.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mail_outline, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No auction invites yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'When sellers invite you to private auctions,\nthey\'ll appear here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final pending = _controller.invites
              .where((i) => i['status'] == 'pending')
              .toList();
          final responded = _controller.invites
              .where((i) => i['status'] != 'pending')
              .toList();

          return RefreshIndicator(
            onRefresh: _controller.loadInvites,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (pending.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Pending Invites',
                    pending.length,
                    Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  ...pending.map(
                    (invite) =>
                        _buildInviteCard(invite, isDark, isPending: true),
                  ),
                  const SizedBox(height: 24),
                ],
                if (responded.isNotEmpty) ...[
                  _buildSectionHeader(
                    'Past Invites',
                    responded.length,
                    Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  ...responded.map(
                    (invite) =>
                        _buildInviteCard(invite, isDark, isPending: false),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha((0.15 * 255).toInt()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInviteCard(
    Map<String, dynamic> invite,
    bool isDark, {
    required bool isPending,
  }) {
    final auctionTitle =
        invite['auction_title'] as String? ?? 'Private Auction';
    final sellerName =
        invite['inviter_username'] as String? ?? 'Unknown Seller';
    final status = invite['status'] as String? ?? 'pending';
    final inviteId = invite['id'] as String;
    final createdAt = invite['created_at'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isPending
            ? BorderSide(
                color: Colors.orange.withAlpha((0.4 * 255).toInt()),
                width: 1.5,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Lock icon + auction title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConstants.primary.withAlpha(
                      (0.1 * 255).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock,
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
                        auctionTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Invited by $sellerName',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPending) _buildStatusBadge(status),
              ],
            ),

            if (createdAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Received: ${_formatDate(createdAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? ColorConstants.textSecondaryDark
                      : ColorConstants.textSecondaryLight,
                ),
              ),
            ],

            // Action buttons for pending invites
            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _handleReject(inviteId),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _handleAccept(inviteId),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorConstants.success,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final Color color;
    final String label;
    final IconData icon;

    switch (status) {
      case 'accepted':
        color = ColorConstants.success;
        label = 'Accepted';
        icon = Icons.check_circle;
      case 'rejected':
        color = Colors.red;
        label = 'Declined';
        icon = Icons.cancel;
      default:
        color = Colors.orange;
        label = 'Pending';
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  Future<void> _handleAccept(String inviteId) async {
    final success = await _controller.acceptInvite(inviteId);
    if (!mounted) return;

    (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Invite accepted! You can now view and bid on this auction.'
              : _controller.errorMessage ?? 'Failed to accept invite',
        ),
        backgroundColor: success ? ColorConstants.success : Colors.red,
      ),
    );
  }

  Future<void> _handleReject(String inviteId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Decline Invite?'),
        content: const Text(
          'You won\'t be able to view or bid on this private auction.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _controller.rejectInvite(inviteId);
    if (!mounted) return;

    (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Invite declined'
              : _controller.errorMessage ?? 'Failed to decline invite',
        ),
        backgroundColor: success ? Colors.grey : Colors.red,
      ),
    );
  }
}
