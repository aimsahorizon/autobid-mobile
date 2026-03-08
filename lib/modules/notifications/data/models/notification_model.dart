import '../../domain/entities/notification_entity.dart';

/// Model for serializing/deserializing notification data from Supabase
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    super.subType = NotificationSubType.unknown,
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
    final typeString = json['type'] as String? ?? 'system';
    final subType = _notificationSubTypeFromString(typeString);
    final broadType = _broadTypeFromSubType(subType, typeString);

    // Extract related entity info from data/metadata JSONB or direct columns
    final data = (json['data'] ?? json['metadata']) as Map<String, dynamic>?;
    final relatedEntityType =
        json['related_entity_type'] as String? ??
        data?['related_entity_type'] as String?;
    final relatedEntityId =
        json['related_entity_id'] as String? ??
        data?['related_entity_id'] as String?;
    final priority =
        json['priority'] as String? ?? data?['priority'] as String? ?? 'normal';

    return NotificationModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      type: broadType,
      subType: subType,
      priority: _notificationPriorityFromString(priority),
      title: json['title'] as String? ?? 'Notification',
      message: json['message'] as String? ?? '',
      isRead: json['is_read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      relatedEntityId: relatedEntityId,
      relatedEntityType: relatedEntityType,
      metadata: data,
    );
  }

  /// Convert model to JSON (for Supabase insert/update)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': _notificationSubTypeToString(subType),
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

  // =========================================================================
  // Sub-type mapping (DB type_name ↔ NotificationSubType)
  // =========================================================================

  /// Convert database type_name string to NotificationSubType enum
  static NotificationSubType _notificationSubTypeFromString(String type) {
    switch (type) {
      // Bid
      case 'bid_placed':
        return NotificationSubType.bidPlaced;
      case 'outbid':
        return NotificationSubType.outbid;
      // Auction
      case 'auction_won':
        return NotificationSubType.auctionWon;
      case 'auction_lost':
        return NotificationSubType.auctionLost;
      case 'auction_ending':
        return NotificationSubType.auctionEnding;
      case 'auction_approved':
        return NotificationSubType.auctionApproved;
      case 'auction_cancelled':
        return NotificationSubType.auctionCancelled;
      case 'auction_live':
        return NotificationSubType.auctionLive;
      case 'auction_ended':
        return NotificationSubType.auctionEnded;
      // Invite
      case 'auction_invite':
        return NotificationSubType.auctionInvite;
      case 'auction_invite_accepted':
        return NotificationSubType.auctionInviteAccepted;
      case 'auction_invite_rejected':
        return NotificationSubType.auctionInviteRejected;
      // Q&A
      case 'new_question':
        return NotificationSubType.newQuestion;
      case 'qa_reply':
        return NotificationSubType.qaReply;
      // Transaction
      case 'transaction_started':
        return NotificationSubType.transactionStarted;
      case 'forms_confirmed':
        return NotificationSubType.formsConfirmed;
      case 'chat_message':
        return NotificationSubType.chatMessage;
      case 'review_received':
        return NotificationSubType.reviewReceived;
      case 'activity_log':
        return NotificationSubType.activityLog;
      case 'agreement_update':
        return NotificationSubType.agreementUpdate;
      case 'installment_update':
        return NotificationSubType.installmentUpdate;
      case 'delivery_update':
        return NotificationSubType.deliveryUpdate;
      case 'payment_method_update':
        return NotificationSubType.paymentMethodUpdate;
      // System
      case 'payment_received':
        return NotificationSubType.paymentReceived;
      case 'kyc_approved':
        return NotificationSubType.kycApproved;
      case 'kyc_rejected':
        return NotificationSubType.kycRejected;
      case 'message_received':
        return NotificationSubType.messageReceived;
      // Legacy broad types (backward compatibility)
      case 'bid_update':
        return NotificationSubType.bidPlaced;
      case 'auction_update':
        return NotificationSubType.auctionEnding;
      case 'listing_update':
        return NotificationSubType.auctionApproved;
      case 'transaction':
        return NotificationSubType.transactionStarted;
      case 'system':
        return NotificationSubType.unknown;
      case 'message':
        return NotificationSubType.messageReceived;
      default:
        return NotificationSubType.unknown;
    }
  }

  /// Convert NotificationSubType enum to database type_name string
  static String _notificationSubTypeToString(NotificationSubType subType) {
    switch (subType) {
      case NotificationSubType.bidPlaced:
        return 'bid_placed';
      case NotificationSubType.outbid:
        return 'outbid';
      case NotificationSubType.auctionWon:
        return 'auction_won';
      case NotificationSubType.auctionLost:
        return 'auction_lost';
      case NotificationSubType.auctionEnding:
        return 'auction_ending';
      case NotificationSubType.auctionApproved:
        return 'auction_approved';
      case NotificationSubType.auctionCancelled:
        return 'auction_cancelled';
      case NotificationSubType.auctionLive:
        return 'auction_live';
      case NotificationSubType.auctionEnded:
        return 'auction_ended';
      case NotificationSubType.auctionInvite:
        return 'auction_invite';
      case NotificationSubType.auctionInviteAccepted:
        return 'auction_invite_accepted';
      case NotificationSubType.auctionInviteRejected:
        return 'auction_invite_rejected';
      case NotificationSubType.newQuestion:
        return 'new_question';
      case NotificationSubType.qaReply:
        return 'qa_reply';
      case NotificationSubType.transactionStarted:
        return 'transaction_started';
      case NotificationSubType.formsConfirmed:
        return 'forms_confirmed';
      case NotificationSubType.chatMessage:
        return 'chat_message';
      case NotificationSubType.reviewReceived:
        return 'review_received';
      case NotificationSubType.activityLog:
        return 'activity_log';
      case NotificationSubType.agreementUpdate:
        return 'agreement_update';
      case NotificationSubType.installmentUpdate:
        return 'installment_update';
      case NotificationSubType.deliveryUpdate:
        return 'delivery_update';
      case NotificationSubType.paymentMethodUpdate:
        return 'payment_method_update';
      case NotificationSubType.paymentReceived:
        return 'payment_received';
      case NotificationSubType.kycApproved:
        return 'kyc_approved';
      case NotificationSubType.kycRejected:
        return 'kyc_rejected';
      case NotificationSubType.messageReceived:
        return 'message_received';
      case NotificationSubType.unknown:
        return 'system';
    }
  }

  // =========================================================================
  // Broad type resolution (SubType → NotificationType category)
  // =========================================================================

  /// Map a granular sub-type to its broad NotificationType category
  static NotificationType _broadTypeFromSubType(
    NotificationSubType subType,
    String rawType,
  ) {
    switch (subType) {
      // Bid category
      case NotificationSubType.bidPlaced:
      case NotificationSubType.outbid:
        return NotificationType.bidUpdate;
      // Auction category
      case NotificationSubType.auctionWon:
      case NotificationSubType.auctionLost:
      case NotificationSubType.auctionEnding:
      case NotificationSubType.auctionLive:
      case NotificationSubType.auctionEnded:
      case NotificationSubType.auctionCancelled:
        return NotificationType.auctionUpdate;
      // Listing category
      case NotificationSubType.auctionApproved:
        return NotificationType.listingUpdate;
      // Invite category
      case NotificationSubType.auctionInvite:
      case NotificationSubType.auctionInviteAccepted:
      case NotificationSubType.auctionInviteRejected:
        return NotificationType.auctionInvite;
      // Message category
      case NotificationSubType.newQuestion:
      case NotificationSubType.qaReply:
      case NotificationSubType.chatMessage:
      case NotificationSubType.messageReceived:
        return NotificationType.message;
      // Transaction category
      case NotificationSubType.transactionStarted:
      case NotificationSubType.formsConfirmed:
      case NotificationSubType.activityLog:
      case NotificationSubType.agreementUpdate:
      case NotificationSubType.installmentUpdate:
      case NotificationSubType.deliveryUpdate:
      case NotificationSubType.paymentMethodUpdate:
        return NotificationType.transaction;
      // Review
      case NotificationSubType.reviewReceived:
        return NotificationType.review;
      // System
      case NotificationSubType.paymentReceived:
      case NotificationSubType.kycApproved:
      case NotificationSubType.kycRejected:
      case NotificationSubType.unknown:
        return NotificationType.system;
    }
  }

  // =========================================================================
  // Priority mapping
  // =========================================================================

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
