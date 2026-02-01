import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notification_controller.dart';

/// Notifications page showing all user notifications
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GetIt.instance<NotificationController>();
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    _controller.loadNotifications(userId);
  }

  Future<void> _handleRefresh() async {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    await _controller.loadNotifications(userId);
  }

  void _markAllAsRead() {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    _controller.markAllAsRead(userId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) {
              if (_controller.unreadCount > 0) {
                return TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark all read'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.hasError) {
            return _buildErrorState(isDark, theme);
          }

          if (_controller.notifications.isEmpty) {
            return _buildEmptyState(isDark, theme);
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _controller.notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = _controller.notifications[index];
                return _NotificationCard(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                  onDismiss: () => _handleDismiss(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ColorConstants.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 50,
                color: ColorConstants.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You\'re all caught up! Check back later for updates.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: ColorConstants.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? ColorConstants.textSecondaryDark
                    : ColorConstants.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _handleRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationEntity notification) {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    if (!notification.isRead) {
      _controller.markAsRead(notification.id, userId);
    }
    // TODO: Navigate to related entity (auction, listing, etc.)
  }

  void _handleDismiss(NotificationEntity notification) {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    _controller.deleteNotification(notification.id, userId);
  }
}

/// Notification card widget
class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: ColorConstants.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: notification.isRead
                ? (isDark ? ColorConstants.surfaceDark : Colors.white)
                : ColorConstants.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? ColorConstants.borderDark
                  : ColorConstants.borderLight,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (!notification.isRead)
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
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notification.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? ColorConstants.textSecondaryDark
                            : ColorConstants.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.type) {
      case NotificationType.bidUpdate:
        icon = Icons.gavel;
        color = ColorConstants.warning;
        break;
      case NotificationType.auctionUpdate:
        icon = Icons.timer;
        color = ColorConstants.info;
        break;
      case NotificationType.listingUpdate:
        icon = Icons.inventory_2_outlined;
        color = ColorConstants.success;
        break;
      case NotificationType.transaction:
        icon = Icons.payments_outlined;
        color = ColorConstants.primary;
        break;
      case NotificationType.system:
        icon = Icons.info_outline;
        color = ColorConstants.info;
        break;
      case NotificationType.message:
        icon = Icons.chat_bubble_outline;
        color = ColorConstants.primary;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
