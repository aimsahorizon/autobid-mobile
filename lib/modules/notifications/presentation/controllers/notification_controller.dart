import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/usecases/get_notifications_usecase.dart';
import '../../domain/usecases/get_unread_count_usecase.dart';
import '../../domain/usecases/mark_as_read_usecase.dart';
import '../../domain/usecases/mark_all_as_read_usecase.dart';
import '../../domain/usecases/delete_notification_usecase.dart';
import '../../domain/usecases/get_unread_notifications_usecase.dart';

/// Controller for managing notification state
/// Refactored to use Clean Architecture with UseCases
class NotificationController extends ChangeNotifier {
  final GetNotificationsUseCase _getNotificationsUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final MarkAsReadUseCase _markAsReadUseCase;
  final MarkAllAsReadUseCase _markAllAsReadUseCase;
  final DeleteNotificationUseCase _deleteNotificationUseCase;
  final GetUnreadNotificationsUseCase _getUnreadNotificationsUseCase;

  NotificationController({
    required GetNotificationsUseCase getNotificationsUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required MarkAsReadUseCase markAsReadUseCase,
    required MarkAllAsReadUseCase markAllAsReadUseCase,
    required DeleteNotificationUseCase deleteNotificationUseCase,
    required GetUnreadNotificationsUseCase getUnreadNotificationsUseCase,
  }) : _getNotificationsUseCase = getNotificationsUseCase,
       _getUnreadCountUseCase = getUnreadCountUseCase,
       _markAsReadUseCase = markAsReadUseCase,
       _markAllAsReadUseCase = markAllAsReadUseCase,
       _deleteNotificationUseCase = deleteNotificationUseCase,
       _getUnreadNotificationsUseCase = getUnreadNotificationsUseCase;

  List<NotificationEntity> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;

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
        (failure) =>
            _errorMessage = failure?.message ?? 'Failed to load notifications',
        (notifications) => _notifications = notifications,
      );

      unreadCountResult.fold(
        (failure) {}, // Silent fail for unread count
        (count) => _unreadCount = count,
      );
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      final result = await _markAsReadUseCase(notificationId: notificationId);

      result.fold(
        (failure) {
          _errorMessage = failure?.message ?? 'Failed to mark as read';
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
          _errorMessage = failure?.message ?? 'Failed to mark all as read';
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
          _errorMessage = failure?.message ?? 'Failed to delete notification';
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

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
