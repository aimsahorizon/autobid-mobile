import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/constants/color_constants.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../domain/entities/notification_entity.dart';
import '../controllers/notification_controller.dart';
import '../controllers/notification_action_handler.dart';

/// Filter options for the notification list
enum NotificationFilter { all, unread, bids, auctions, transactions, messages }

/// Notifications page showing all user notifications
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationController _controller;
  NotificationFilter _currentFilter = NotificationFilter.all;

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

  List<NotificationEntity> _filteredNotifications(
    List<NotificationEntity> notifications,
  ) {
    switch (_currentFilter) {
      case NotificationFilter.all:
        return notifications;
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead).toList();
      case NotificationFilter.bids:
        return notifications
            .where((n) => n.type == NotificationType.bidUpdate)
            .toList();
      case NotificationFilter.auctions:
        return notifications
            .where(
              (n) =>
                  n.type == NotificationType.auctionUpdate ||
                  n.type == NotificationType.listingUpdate,
            )
            .toList();
      case NotificationFilter.transactions:
        return notifications
            .where(
              (n) =>
                  n.type == NotificationType.transaction ||
                  n.type == NotificationType.review,
            )
            .toList();
      case NotificationFilter.messages:
        return notifications
            .where((n) => n.type == NotificationType.message)
            .toList();
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
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(theme, isDark),
          // Notification list
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading &&
                    _controller.notifications.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.hasError) {
                  return _buildErrorState(isDark, theme);
                }

                final filtered = _filteredNotifications(
                  _controller.notifications,
                );

                if (filtered.isEmpty) {
                  if (_currentFilter != NotificationFilter.all &&
                      _controller.notifications.isNotEmpty) {
                    return _buildEmptyFilterState(isDark, theme);
                  }
                  return _buildEmptyState(isDark, theme);
                }

                return RefreshIndicator(
                  onRefresh: _handleRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notification = filtered[index];
                      return _NotificationCard(
                        notification: notification,
                        onTap: () => _handleNotificationTap(notification),
                        onDismiss: () => _handleDismiss(notification),
                        onInviteResponse: (decision) =>
                            _handleInviteResponse(notification, decision),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: NotificationFilter.values.map((filter) {
          final isSelected = _currentFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(_filterLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _currentFilter = selected ? filter : NotificationFilter.all;
                });
              },
              selectedColor: ColorConstants.primary.withValues(alpha: 0.2),
              checkmarkColor: ColorConstants.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(NotificationFilter filter) {
    switch (filter) {
      case NotificationFilter.all:
        return 'All';
      case NotificationFilter.unread:
        return 'Unread';
      case NotificationFilter.bids:
        return 'Bids';
      case NotificationFilter.auctions:
        return 'Auctions';
      case NotificationFilter.transactions:
        return 'Transactions';
      case NotificationFilter.messages:
        return 'Messages';
    }
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

  Widget _buildEmptyFilterState(bool isDark, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list,
              size: 50,
              color: isDark
                  ? ColorConstants.textSecondaryDark
                  : ColorConstants.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () =>
                  setState(() => _currentFilter = NotificationFilter.all),
              child: const Text('Show all'),
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
    // Navigate to the related entity using the action handler
    NotificationActionHandler(context).handleTap(notification);
  }

  void _handleDismiss(NotificationEntity notification) {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    _controller.deleteNotification(notification.id, userId);
  }

  void _handleInviteResponse(
    NotificationEntity notification,
    String decision,
  ) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final inviteId = notification.metadata?['invite_id'] as String?;

    if (inviteId != null) {
      // Show loading indicator
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(
          content: Text('Processing response...'),
          duration: Duration(seconds: 1),
        ),
      );

      await _controller.respondToInvite(inviteId, decision, userId);

      if (mounted) {
        if (_controller.hasError) {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(_controller.errorMessage!),
              backgroundColor: ColorConstants.error,
            ),
          );
        } else {
          (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
            SnackBar(
              content: Text(
                'Invite ${decision == "accepted" ? "accepted" : "declined"} successfully',
              ),
              backgroundColor: ColorConstants.success,
            ),
          );
          // Mark as read after successful response
          if (!notification.isRead) {
            _controller.markAsRead(notification.id, userId);
          }
          // If accepted, prompt user to view the listing
          if (decision == 'accepted' && mounted) {
            final auctionId = notification.metadata?['auction_id'] as String?;
            if (auctionId != null) {
              final shouldView = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Invite Accepted'),
                  content: const Text(
                    'Would you like to view the auction listing now?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Later'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('View Listing'),
                    ),
                  ],
                ),
              );
              if (shouldView == true && mounted) {
                NotificationActionHandler(context).navigateToAuction(auctionId);
              }
            }
          }
        }
      }
    } else {
      (ScaffoldMessenger.of(context)..clearSnackBars()).showSnackBar(
        const SnackBar(content: Text('Invalid invite data')),
      );
    }
  }
}

/// Notification card widget with sub-type aware icon/color rendering
class _NotificationCard extends StatelessWidget {
  final NotificationEntity notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final Function(String)? onInviteResponse;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
    this.onInviteResponse,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isInvite = notification.isActionableInvite;
    final inviteStatus = notification.metadata?['invite_status'] as String?;

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
            border: Border.all(color: _borderColor(isDark)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              _formatTime(notification.createdAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? ColorConstants.textSecondaryDark
                                    : ColorConstants.textSecondaryLight,
                              ),
                            ),
                            if (notification.priority ==
                                NotificationPriority.urgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'URGENT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.error,
                                  ),
                                ),
                              ),
                            ],
                            if (notification.priority ==
                                NotificationPriority.high) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: ColorConstants.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'IMPORTANT',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: ColorConstants.warning,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Invite action buttons
              if (notification.type == NotificationType.auctionInvite) ...[
                const SizedBox(height: 16),
                if (inviteStatus != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (inviteStatus == 'accepted'
                                  ? ColorConstants.success
                                  : ColorConstants.error)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          inviteStatus == 'accepted'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: 16,
                          color: inviteStatus == 'accepted'
                              ? ColorConstants.success
                              : ColorConstants.error,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          inviteStatus == 'accepted' ? 'ACCEPTED' : 'DECLINED',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: inviteStatus == 'accepted'
                                ? ColorConstants.success
                                : ColorConstants.error,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (isInvite)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => onInviteResponse?.call('rejected'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstants.error,
                          side: const BorderSide(color: ColorConstants.error),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Decline'),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () => onInviteResponse?.call('accepted'),
                        style: FilledButton.styleFrom(
                          backgroundColor: ColorConstants.success,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Border color based on priority for urgent/high notifications
  Color _borderColor(bool isDark) {
    if (!notification.isRead) {
      switch (notification.priority) {
        case NotificationPriority.urgent:
          return ColorConstants.error.withValues(alpha: 0.5);
        case NotificationPriority.high:
          return ColorConstants.warning.withValues(alpha: 0.3);
        default:
          break;
      }
    }
    return isDark ? ColorConstants.borderDark : ColorConstants.borderLight;
  }

  Widget _buildIcon() {
    final (icon, color) = _iconAndColor();

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

  /// Determine icon and color based on the granular sub-type
  (IconData, Color) _iconAndColor() {
    switch (notification.subType) {
      // Bid notifications
      case NotificationSubType.outbid:
        return (Icons.trending_up, ColorConstants.error);
      case NotificationSubType.bidPlaced:
        return (Icons.gavel, ColorConstants.warning);

      // Auction status notifications
      case NotificationSubType.auctionWon:
        return (Icons.emoji_events, ColorConstants.success);
      case NotificationSubType.auctionLost:
        return (Icons.sentiment_dissatisfied, ColorConstants.error);
      case NotificationSubType.auctionEnding:
        return (Icons.timer, ColorConstants.warning);
      case NotificationSubType.auctionLive:
        return (Icons.play_circle_filled, ColorConstants.success);
      case NotificationSubType.auctionEnded:
        return (Icons.stop_circle, ColorConstants.info);
      case NotificationSubType.auctionCancelled:
        return (Icons.cancel_outlined, ColorConstants.error);
      case NotificationSubType.auctionApproved:
        return (Icons.check_circle_outline, ColorConstants.success);

      // Invite notifications
      case NotificationSubType.auctionInvite:
        return (Icons.mail_outline, ColorConstants.primary);
      case NotificationSubType.auctionInviteAccepted:
        return (Icons.check_circle, ColorConstants.success);
      case NotificationSubType.auctionInviteRejected:
        return (Icons.cancel, ColorConstants.error);

      // Q&A notifications
      case NotificationSubType.newQuestion:
        return (Icons.help_outline, ColorConstants.info);
      case NotificationSubType.qaReply:
        return (Icons.question_answer, ColorConstants.primary);

      // Transaction notifications
      case NotificationSubType.transactionStarted:
        return (Icons.handshake, ColorConstants.primary);
      case NotificationSubType.formsConfirmed:
        return (Icons.assignment_turned_in, ColorConstants.success);
      case NotificationSubType.activityLog:
        return (Icons.timeline, ColorConstants.info);

      // Transaction sub-tab updates
      case NotificationSubType.agreementUpdate:
        return (Icons.description, ColorConstants.primary);
      case NotificationSubType.installmentUpdate:
        return (Icons.calendar_month, Colors.green);
      case NotificationSubType.deliveryUpdate:
        return (Icons.local_shipping, ColorConstants.warning);
      case NotificationSubType.paymentMethodUpdate:
        return (Icons.payment, ColorConstants.info);

      // Chat
      case NotificationSubType.chatMessage:
        return (Icons.chat_bubble_outline, ColorConstants.primary);

      // Review
      case NotificationSubType.reviewReceived:
        return (Icons.star, ColorConstants.warning);

      // System
      case NotificationSubType.paymentReceived:
        return (Icons.payments_outlined, ColorConstants.success);
      case NotificationSubType.kycApproved:
        return (Icons.verified_user, ColorConstants.success);
      case NotificationSubType.kycRejected:
        return (Icons.gpp_bad, ColorConstants.error);
      case NotificationSubType.messageReceived:
        return (Icons.message, ColorConstants.primary);

      case NotificationSubType.unknown:
        return (Icons.info_outline, ColorConstants.info);
    }
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
