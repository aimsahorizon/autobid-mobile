import 'package:flutter/material.dart';
import '../../domain/entities/notification_entity.dart';

/// Handles notification tap actions by navigating to the relevant screen
/// based on the notification type and related entity.
class NotificationActionHandler {
  final BuildContext context;

  NotificationActionHandler(this.context);

  /// Navigate to the relevant screen based on notification data
  void handleTap(NotificationEntity notification) {
    final entityType = notification.relatedEntityType;
    final entityId = notification.relatedEntityId;
    final metadata = notification.metadata ?? {};

    switch (notification.subType) {
      // ---- Bid Notifications → Auction Detail ----
      case NotificationSubType.outbid:
      case NotificationSubType.bidPlaced:
        _navigateToAuction(entityId ?? metadata['auction_id'] as String?);
        break;

      // ---- Auction Status Notifications → Auction Detail ----
      case NotificationSubType.auctionWon:
      case NotificationSubType.auctionLost:
      case NotificationSubType.auctionEnding:
      case NotificationSubType.auctionLive:
      case NotificationSubType.auctionEnded:
      case NotificationSubType.auctionCancelled:
        _navigateToAuction(entityId ?? metadata['auction_id'] as String?);
        break;

      // ---- Listing Notifications → Auction Detail (seller view) ----
      case NotificationSubType.auctionApproved:
        _navigateToAuction(entityId ?? metadata['auction_id'] as String?);
        break;

      // ---- Invite Notifications → Auction Detail ----
      case NotificationSubType.auctionInvite:
      case NotificationSubType.auctionInviteAccepted:
      case NotificationSubType.auctionInviteRejected:
        _navigateToAuction(metadata['auction_id'] as String?);
        break;

      // ---- Q&A Notifications → Auction Detail (Q&A section) ----
      case NotificationSubType.newQuestion:
      case NotificationSubType.qaReply:
        _navigateToAuction(
          entityId ?? metadata['auction_id'] as String?,
          tab: 'qa',
        );
        break;

      // ---- Transaction Notifications → Transaction Detail ----
      case NotificationSubType.transactionStarted:
      case NotificationSubType.formsConfirmed:
      case NotificationSubType.activityLog:
        _navigateToTransaction(
          entityId ?? metadata['transaction_id'] as String?,
        );
        break;

      // ---- Chat Message → Transaction Chat ----
      case NotificationSubType.chatMessage:
        _navigateToTransaction(
          entityId ?? metadata['transaction_id'] as String?,
          tab: 'chat',
        );
        break;

      // ---- Review Received → Transaction Detail ----
      case NotificationSubType.reviewReceived:
        _navigateToTransaction(
          entityId ?? metadata['transaction_id'] as String?,
        );
        break;

      // ---- System / KYC Notifications ----
      case NotificationSubType.kycApproved:
      case NotificationSubType.kycRejected:
        _navigateToProfile();
        break;

      // ---- Payment / Message / Unknown ----
      case NotificationSubType.paymentReceived:
      case NotificationSubType.messageReceived:
      case NotificationSubType.unknown:
        // If there's a related entity, try to navigate
        if (entityType == 'auction') {
          _navigateToAuction(entityId);
        } else if (entityType == 'transaction') {
          _navigateToTransaction(entityId);
        }
        break;
    }
  }

  void _navigateToAuction(String? auctionId, {String? tab}) {
    if (auctionId == null) return;
    // Navigate to auction detail page
    // The route name should match the app's routing configuration
    Navigator.of(context).pushNamed(
      '/auction/detail',
      arguments: {'auctionId': auctionId, if (tab != null) 'initialTab': tab},
    );
  }

  void _navigateToTransaction(String? transactionId, {String? tab}) {
    if (transactionId == null) return;
    Navigator.of(context).pushNamed(
      '/transaction/detail',
      arguments: {
        'transactionId': transactionId,
        if (tab != null) 'initialTab': tab,
      },
    );
  }

  void _navigateToProfile() {
    Navigator.of(context).pushNamed('/profile');
  }
}
