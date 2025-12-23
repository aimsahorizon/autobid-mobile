/// Notification types for different events in the system
enum NotificationType {
  bidUpdate,        // Outbid, bid accepted, bid rejected
  auctionUpdate,    // Auction ending soon, auction won, auction lost
  listingUpdate,    // Listing approved, listing rejected, new bid received
  transaction,      // Payment received, refund processed, token purchase
  system,           // Account verified, subscription expiring, system maintenance
  message,          // New message from buyer/seller
}

/// Notification priority levels
enum NotificationPriority {
  low,              // General information
  normal,           // Standard notifications
  high,             // Important updates requiring attention
  urgent,           // Critical actions needed immediately
}

/// Extension for NotificationType to provide display properties
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.bidUpdate:
        return 'Bid Update';
      case NotificationType.auctionUpdate:
        return 'Auction Update';
      case NotificationType.listingUpdate:
        return 'Listing Update';
      case NotificationType.transaction:
        return 'Transaction';
      case NotificationType.system:
        return 'System';
      case NotificationType.message:
        return 'Message';
    }
  }

  String get iconName {
    switch (this) {
      case NotificationType.bidUpdate:
        return 'gavel';
      case NotificationType.auctionUpdate:
        return 'timer';
      case NotificationType.listingUpdate:
        return 'inventory';
      case NotificationType.transaction:
        return 'payments';
      case NotificationType.system:
        return 'info';
      case NotificationType.message:
        return 'chat';
    }
  }
}

/// Notification entity representing a user notification
class NotificationEntity {
  final String id;
  final String userId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? relatedEntityId;  // ID of auction, listing, bid, etc.
  final String? relatedEntityType; // 'auction', 'listing', 'bid', etc.
  final Map<String, dynamic>? metadata; // Additional data for the notification

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.relatedEntityId,
    this.relatedEntityType,
    this.metadata,
  });

  /// Create a copy with modified fields
  NotificationEntity copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? message,
    bool? isRead,
    DateTime? createdAt,
    String? relatedEntityId,
    String? relatedEntityType,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      message: message ?? this.message,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      metadata: metadata ?? this.metadata,
    );
  }
}
