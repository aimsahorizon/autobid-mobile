import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:autobid_mobile/core/config/supabase_config.dart';
import '../../../browse/presentation/controllers/auction_detail_controller.dart';
import '../../../browse/presentation/pages/auction_detail_page.dart';
import '../../../transactions/presentation/controllers/transaction_realtime_controller.dart';
import '../../../transactions/presentation/pages/pre_transaction_realtime_page.dart';
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
        // If already accepted, navigate only if auction is live
        final inviteStatus = metadata['invite_status'] as String?;
        if (inviteStatus == 'accepted') {
          final listingStatus = metadata['listing_status'] as String?;
          if (listingStatus == 'live') {
            _navigateToAuction(metadata['auction_id'] as String?);
          } else {
            _showListingStatusMessage(listingStatus);
          }
        }
        // If pending (no status), tapping does nothing extra — buttons handle it
        // If rejected, no navigation
        break;
      case NotificationSubType.auctionInviteAccepted:
      case NotificationSubType.auctionInviteRejected:
        _navigateToAuction(metadata['auction_id'] as String?);
        break;

      // ---- Listing Status Update (invitee) → Auction Detail if live ----
      case NotificationSubType.listingStatusUpdate:
        final status = metadata['listing_status'] as String?;
        if (status == 'live') {
          _navigateToAuction(metadata['auction_id'] as String?);
        } else {
          _showListingStatusMessage(status);
        }
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

      // ---- Agreement Updates → Transaction Agreement Tab ----
      case NotificationSubType.agreementUpdate:
      case NotificationSubType.paymentMethodUpdate:
        _navigateToTransaction(
          entityId ?? metadata['transaction_id'] as String?,
          tab: 'agreement',
        );
        break;

      // ---- Delivery Updates → Transaction Progress Tab ----
      case NotificationSubType.deliveryUpdate:
        _navigateToTransaction(
          entityId ?? metadata['transaction_id'] as String?,
          tab: 'progress',
        );
        break;

      // ---- Installment Updates → Transaction Gives Tab ----
      case NotificationSubType.installmentUpdate:
        _navigateToTransaction(
          entityId ?? metadata['transaction_id'] as String?,
          tab: 'gives',
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

  void navigateToAuction(String? auctionId, {String? tab}) {
    if (auctionId == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuctionDetailPage(
          auctionId: auctionId,
          controller: GetIt.instance<AuctionDetailController>(),
        ),
      ),
    );
  }

  void _navigateToAuction(String? auctionId, {String? tab}) {
    navigateToAuction(auctionId, tab: tab);
  }

  void _navigateToTransaction(String? transactionId, {String? tab}) {
    if (transactionId == null) return;
    final userId = SupabaseConfig.client.auth.currentUser?.id ?? '';
    final userName =
        SupabaseConfig.client.auth.currentUser?.userMetadata?['full_name']
            as String? ??
        SupabaseConfig.client.auth.currentUser?.userMetadata?['display_name']
            as String? ??
        'User';
    final controller = GetIt.instance<TransactionRealtimeController>();
    int tabIndex = 0;
    if (tab == 'agreement') tabIndex = 1;
    if (tab == 'progress') tabIndex = 2;
    if (tab == 'gives') tabIndex = 3;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreTransactionRealtimePage(
          controller: controller,
          transactionId: transactionId,
          userId: userId,
          userName: userName,
          initialTabIndex: tabIndex,
        ),
      ),
    );
  }

  void _navigateToProfile() {
    // Navigate to home and switch to profile tab (index 4)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showListingStatusMessage(String? status) {
    final displayStatus = switch (status) {
      'pending_approval' => 'Pending Approval',
      'scheduled' => 'Approved (Scheduled)',
      'ended' => 'Ended',
      'sold' => 'Sold',
      'unsold' => 'Unsold',
      'cancelled' => 'Cancelled',
      _ => 'Not Yet Live',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'This auction is not yet live. Current status: $displayStatus',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
