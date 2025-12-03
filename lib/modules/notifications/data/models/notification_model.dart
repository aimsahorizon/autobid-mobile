import '../../domain/entities/notification_entity.dart';

/// Model for serializing/deserializing notification data from Supabase
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.priority,
    required super.title,
    required super.message,
    required super.isRead,
    required super.createdAt,
    super.relatedEntityId,
    super.relatedEntityType,
    super.metadata,
  });

  /// Create model from JSON (Supabase response)
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: _notificationTypeFromString(json['type'] as String),
      priority: _notificationPriorityFromString(json['priority'] as String),
      title: json['title'] as String,
      message: json['message'] as String,
      isRead: json['is_read'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      relatedEntityId: json['related_entity_id'] as String?,
      relatedEntityType: json['related_entity_type'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert model to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': _notificationTypeToString(type),
      'priority': _notificationPriorityToString(priority),
      'title': title,
      'message': message,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'related_entity_id': relatedEntityId,
      'related_entity_type': relatedEntityType,
      'metadata': metadata,
    };
  }

  /// Convert NotificationType enum to database string
  static String _notificationTypeToString(NotificationType type) {
    switch (type) {
      case NotificationType.bidUpdate:
        return 'bid_update';
      case NotificationType.auctionUpdate:
        return 'auction_update';
      case NotificationType.listingUpdate:
        return 'listing_update';
      case NotificationType.transaction:
        return 'transaction';
      case NotificationType.system:
        return 'system';
      case NotificationType.message:
        return 'message';
    }
  }

  /// Convert database string to NotificationType enum
  static NotificationType _notificationTypeFromString(String type) {
    switch (type) {
      case 'bid_update':
        return NotificationType.bidUpdate;
      case 'auction_update':
        return NotificationType.auctionUpdate;
      case 'listing_update':
        return NotificationType.listingUpdate;
      case 'transaction':
        return NotificationType.transaction;
      case 'system':
        return NotificationType.system;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.system;
    }
  }

  /// Convert NotificationPriority enum to database string
  static String _notificationPriorityToString(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'low';
      case NotificationPriority.normal:
        return 'normal';
      case NotificationPriority.high:
        return 'high';
      case NotificationPriority.urgent:
        return 'urgent';
    }
  }

  /// Convert database string to NotificationPriority enum
  static NotificationPriority _notificationPriorityFromString(String priority) {
    switch (priority) {
      case 'low':
        return NotificationPriority.low;
      case 'normal':
        return NotificationPriority.normal;
      case 'high':
        return NotificationPriority.high;
      case 'urgent':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}
