import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import '../../../browse/data/datasources/invites_supabase_datasource.dart';
import '../../data/datasources/notifications_supabase_datasource.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsSupabaseDatasource _notifDataSource;
  late final InvitesSupabaseDatasource _invitesDataSource;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supabase = Supabase.instance.client;
    _notifDataSource = NotificationsSupabaseDatasource(supabase: supabase);
    _invitesDataSource = InvitesSupabaseDatasource(supabase: supabase);
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifs = await _notifDataSource.listMyNotifications();
      setState(() {
        _notifications = notifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load notifications: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _respondToInvite(String inviteId, String decision) async {
    // Capture messenger before async gap
    final messenger = ScaffoldMessenger.of(context);

    try {
      await _invitesDataSource.respondInvite(
        inviteId: inviteId,
        decision: decision,
      );

      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accepted'
                ? 'Invite accepted! The auction is now visible in Browse.'
                : 'Invite rejected.',
          ),
          backgroundColor: decision == 'accepted'
              ? ColorConstants.success
              : ColorConstants.warning,
        ),
      );
      _loadNotifications(); // Refresh to update notification state
    } catch (e) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to respond: $e'),
          backgroundColor: ColorConstants.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !(n['is_read'] as bool)))
            TextButton(
              onPressed: () async {
                for (final notif in _notifications) {
                  if (!(notif['is_read'] as bool)) {
                    await _notifDataSource.markRead(notif['id'] as String);
                  }
                }
                _loadNotifications();
              },
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadNotifications,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDark
                        ? ColorConstants.textSecondaryDark
                        : ColorConstants.textSecondaryLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark
                          ? ColorConstants.textSecondaryDark
                          : ColorConstants.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  return _buildNotificationCard(notif, isDark);
                },
              ),
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notif, bool isDark) {
    // Get type_name from the joined notification_types table
    final notifType = notif['notification_types'] as Map<String, dynamic>?;
    final type = (notifType?['type_name'] as String?) ?? 'notification';
    final title = notif['title'] as String?;
    final message = notif['message'] as String?;
    final data = notif['data'] as Map<String, dynamic>?;
    final isRead = notif['is_read'] as bool;
    final createdAt = DateTime.parse(notif['created_at'] as String);

    final isInvite = type == 'auction_invite';
    final inviteId = data?['invite_id'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isRead
          ? (isDark ? ColorConstants.surfaceDark : ColorConstants.surfaceLight)
          : ColorConstants.primary.withAlpha((0.1 * 255).toInt()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getIconForType(type),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title ?? 'Notification',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? ColorConstants.textSecondaryDark
                              : ColorConstants.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: ColorConstants.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(message ?? '', style: Theme.of(context).textTheme.bodyMedium),
            if (isInvite && inviteId != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _respondToInvite(inviteId, 'rejected'),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorConstants.error,
                        side: const BorderSide(color: ColorConstants.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _respondToInvite(inviteId, 'accepted'),
                      icon: const Icon(Icons.check),
                      label: const Text('Accept'),
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorConstants.success,
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

  Icon _getIconForType(String type) {
    switch (type) {
      case 'auction_invite':
        return const Icon(Icons.mail, color: ColorConstants.primary);
      case 'auction_invite_accepted':
        return const Icon(Icons.check_circle, color: ColorConstants.success);
      case 'auction_invite_rejected':
        return const Icon(Icons.cancel, color: ColorConstants.error);
      default:
        return const Icon(Icons.notifications);
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 7) {
      return '${dt.day}/${dt.month}/${dt.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
