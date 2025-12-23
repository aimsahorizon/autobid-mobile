import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';

/// Abstract datasource interface for notifications
abstract class INotificationDataSource {
  Future<List<NotificationEntity>> getNotifications({
    required String userId,
    int? limit,
    int? offset,
  });
  Future<int> getUnreadCount({required String userId});
  Future<void> markAsRead({required String notificationId});
  Future<int> markAllAsRead();
  Future<void> deleteNotification({required String notificationId});
  Future<List<NotificationEntity>> getUnreadNotifications({required String userId});
}

/// Controller for managing notification state
class NotificationController extends ChangeNotifier {
  final INotificationDataSource _dataSource;

  NotificationController(this._dataSource);

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
      _notifications = await _dataSource.getNotifications(userId: userId);
      _unreadCount = await _dataSource.getUnreadCount(userId: userId);
    } catch (e) {
      _errorMessage = 'Failed to load notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load only unread count (for badge)
  Future<void> loadUnreadCount(String userId) async {
    try {
      _unreadCount = await _dataSource.getUnreadCount(userId: userId);
      notifyListeners();
    } catch (e) {
      // Silent fail for unread count
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _dataSource.markAsRead(notificationId: notificationId);

      // Update local state
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to mark as read: $e';
      notifyListeners();
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead(String userId) async {
    try {
      await _dataSource.markAllAsRead();

      // Update local state
      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to mark all as read: $e';
      notifyListeners();
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId, String userId) async {
    try {
      await _dataSource.deleteNotification(notificationId: notificationId);

      // Update local state
      final notification = _notifications.firstWhere((n) => n.id == notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      notifyListeners();
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
