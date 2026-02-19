import 'dart:async';
import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/respond_to_invite_usecase.dart';
import '../../data/datasources/notification_datasource.dart';

/// Controller for managing notification state
/// Refactored to use Clean Architecture with UseCases
/// Supports realtime notification updates via Supabase stream
class NotificationController extends ChangeNotifier {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final MarkAllAsReadUseCase _markAllAsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final RespondToInviteUseCase _respondToInviteUseCase;
  final INotificationDataSource? _dataSource;

  NotificationController({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required MarkAllAsReadUseCase markAllAsReadUseCase,
    required DeleteNotificationUseCase deleteNotificationUseCase,
    required RespondToInviteUseCase respondToInviteUseCase,
    INotificationDataSource? dataSource,
  }) : _getNotificationsUseCase = getNotificationsUseCase,
       _getUnreadCountUseCase = getUnreadCountUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _markAllAsReadUseCase = markAllAsReadUseCase,
       _deleteNotificationUseCase = deleteNotificationUseCase,
       _respondToInviteUseCase = respondToInviteUseCase,
       _dataSource = dataSource;

  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription? _notificationSubscription;
  String? _subscribedUserId;

  // Getters
  List<NotificationEntity> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasError => _errorMessage != null;

  /// Load all notifications for a user
  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Use UseCases to get notifications
      final notificationsResult = await _getNotificationsUseCase(
        userId: userId,
      );
      final unreadCountResult = await _getUnreadCountUseCase(userId: userId);

      notificationsResult.fold(
        (failure) => _errorMessage = failure.message,
        (notifications) => _notifications = notifications,
      );

      unreadCountResult.fold(
        (failure) {}, // Silent fail for unread count
        (count) => _unreadCount = count,
      );

      // Start realtime subscription if not already subscribed
      _subscribeToRealtimeUpdates(userId);
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Subscribe to realtime notification updates
  void _subscribeToRealtimeUpdates(String userId) {
    if (_subscribedUserId == userId || _dataSource == null) return;

    _notificationSubscription?.cancel();
    _subscribedUserId = userId;

    _notificationSubscription = _dataSource
        ?.streamNotifications(userId: userId)
        .skip(1) // Skip initial data (we already loaded it)
        .listen(
          (_) {
            // Reload notifications when we get a realtime update
            debugPrint('DEBUG: Realtime notification update received');
            _refreshNotifications(userId);
          },
          onError: (e) {
            debugPrint('ERROR: Realtime notification subscription error: $e');
          },
        );
  }

  /// Refresh notifications without showing loading state
  Future<void> _refreshNotifications(String userId) async {
    try {
      final notificationsResult = await _getNotificationsUseCase(
        userId: userId,
      );
      final unreadCountResult = await _getUnreadCountUseCase(userId: userId);

      notificationsResult.fold(
        (failure) {},
        (notifications) => _notifications = notifications,
      );

      unreadCountResult.fold((failure) {}, (count) => _unreadCount = count);

      notifyListeners();
    } catch (e) {
      debugPrint('ERROR: Failed to refresh notifications: $e');
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      final result = await _markAsReadUseCase(notificationId: notificationId);

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          notifyListeners();
        },
        (_) {
          // Update local state
          final index = _notifications.indexWhere(
            (n) => n.id == notificationId,
          );
          if (index != -1 && !_notifications[index].isRead) {
            _notifications[index] = _notifications[index].copyWith(
              isRead: true,
            );
            _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
            notifyListeners();
          }
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to mark as read: $e';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      final result = await _markAllAsReadUseCase();

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          notifyListeners();
        },
        (_) {
          // Update local state
          _notifications = _notifications
              .map((n) => n.copyWith(isRead: true))
              .toList();
          _unreadCount = 0;
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to mark all as read: $e';
      notifyListeners();
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId, String userId) async {
    try {
      final result = await _deleteNotificationUseCase(
        notificationId: notificationId,
      );

      result.fold(
        (failure) {
          _errorMessage = failure.message;
          notifyListeners();
        },
        (_) {
          // Update local state
          final notification = _notifications.firstWhere(
            (n) => n.id == notificationId,
          );
          _notifications.removeWhere((n) => n.id == notificationId);
          if (!notification.isRead) {
            _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
          }
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to delete notification: $e';
      notifyListeners();
    }
  }

  /// Respond to an invite
  Future<void> respondToInvite(
    String inviteId,
    String decision,
    String userId,
  ) async {
    try {
      final result = await _respondToInviteUseCase(
        inviteId: inviteId,
        decision: decision,
      );

      await result.fold(
        (failure) {
          _errorMessage = failure.message;
          notifyListeners();
        },
        (_) async {
          // Refresh notifications to show updated status or new notification
          await loadNotifications(userId);
        },
      );
    } catch (e) {
      _errorMessage = 'Failed to respond to invite: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    _subscribedUserId = null;
    super.dispose();
  }
}
