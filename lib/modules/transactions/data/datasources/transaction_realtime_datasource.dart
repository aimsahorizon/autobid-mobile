import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';

/// Supabase datasource for real-time transaction data
/// Handles chat, forms, timeline with real-time subscriptions
class TransactionRealtimeDataSource {
  final SupabaseClient _supabase;

  // Real-time subscriptions
  RealtimeChannel? _chatChannel;
  RealtimeChannel? _transactionChannel;

  // Stream controllers for real-time updates
  final _chatStreamController = StreamController<ChatMessageEntity>.broadcast();
  final _transactionUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();

  TransactionRealtimeDataSource(this._supabase);

  /// Stream of new chat messages
  Stream<ChatMessageEntity> get chatStream => _chatStreamController.stream;

  /// Stream of transaction updates
  Stream<Map<String, dynamic>> get transactionUpdateStream =>
      _transactionUpdateController.stream;

  // ============================================================================
  // TRANSACTION CRUD
  // ============================================================================

  /// Get transaction by auction ID (for buyer/seller navigation)
  Future<TransactionEntity?> getTransactionByAuctionId(String auctionId) async {
    try {
      print(
        '[TransactionRealtimeDataSource] Getting transaction for auction: $auctionId',
      );

      final response = await _supabase.rpc(
        'get_transaction_by_auction',
        params: {'p_auction_id': auctionId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        print(
          '[TransactionRealtimeDataSource] No transaction found for auction',
        );
        return null;
      }

      final data = response is List ? response.first : response;
      return _mapToTransactionEntity(data as Map<String, dynamic>);
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error getting transaction: $e');
      return null;
    }
  }

  /// Get transaction by transaction ID
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    try {
      print(
        '[TransactionRealtimeDataSource] Getting transaction: $transactionId',
      );

      // First try as transaction ID
      var response = await _supabase
          .from('auction_transactions')
          .select('''
            *,
            auctions!inner(title, auction_vehicles(brand, model)),
            seller:users!auction_transactions_seller_id_fkey(display_name),
            buyer:users!auction_transactions_buyer_id_fkey(display_name)
          ''')
          .eq('id', transactionId)
          .maybeSingle();

      // If not found, try as auction ID
      if (response == null) {
        response = await _supabase
            .from('auction_transactions')
            .select('''
              *,
              auctions!inner(title, auction_vehicles(brand, model)),
              seller:users!auction_transactions_seller_id_fkey(display_name),
              buyer:users!auction_transactions_buyer_id_fkey(display_name)
            ''')
            .eq('auction_id', transactionId)
            .maybeSingle();
      }

      if (response == null) {
        print('[TransactionRealtimeDataSource] Transaction not found');
        return null;
      }

      return _mapToTransactionEntity(response);
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error getting transaction: $e');
      return null;
    }
  }

  TransactionEntity _mapToTransactionEntity(Map<String, dynamic> data) {
    // Get car name from vehicle (nested in auctions) or auction title
    String carName = 'Vehicle';

    // Check for auction_vehicles nested inside auctions
    if (data['auctions'] is Map) {
      final auctions = data['auctions'] as Map<String, dynamic>;
      final vehicles = auctions['auction_vehicles'];
      if (vehicles is List && vehicles.isNotEmpty) {
        final v = vehicles.first;
        carName = '${v['brand'] ?? ''} ${v['model'] ?? ''}'.trim();
      } else if (auctions['title'] != null) {
        carName = auctions['title'] as String;
      }
    } else if (data['car_name'] != null) {
      carName = data['car_name'] as String;
    }

    // Get cover photo
    String carImageUrl = data['car_image_url'] as String? ?? '';

    return TransactionEntity(
      id: data['id'] as String,
      listingId: data['auction_id'] as String,
      sellerId: data['seller_id'] as String,
      buyerId: data['buyer_id'] as String,
      carName: carName,
      carImageUrl: carImageUrl,
      agreedPrice: (data['agreed_price'] as num).toDouble(),
      status: _mapStatus(data['status'] as String? ?? 'in_transaction'),
      createdAt: DateTime.parse(data['created_at'] as String),
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'] as String)
          : null,
      sellerFormSubmitted: data['seller_form_submitted'] as bool? ?? false,
      buyerFormSubmitted: data['buyer_form_submitted'] as bool? ?? false,
      sellerConfirmed: data['seller_confirmed'] as bool? ?? false,
      buyerConfirmed: data['buyer_confirmed'] as bool? ?? false,
      adminApproved: data['admin_approved'] as bool? ?? false,
      adminApprovedAt: data['admin_approved_at'] != null
          ? DateTime.parse(data['admin_approved_at'] as String)
          : null,
    );
  }

  TransactionStatus _mapStatus(String status) {
    switch (status) {
      case 'in_transaction':
        return TransactionStatus.discussion;
      case 'sold':
        return TransactionStatus.completed;
      case 'deal_failed':
        return TransactionStatus.cancelled;
      default:
        return TransactionStatus.discussion;
    }
  }

  // ============================================================================
  // CHAT MESSAGES
  // ============================================================================

  /// Get all chat messages for a transaction
  Future<List<ChatMessageEntity>> getChatMessages(String transactionId) async {
    try {
      // Get transaction ID if auction ID was passed
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return [];

      final response = await _supabase
          .from('transaction_chat_messages')
          .select()
          .eq('transaction_id', txnId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (msg) => ChatMessageEntity(
              id: msg['id'] as String,
              transactionId: msg['transaction_id'] as String,
              senderId: msg['sender_id'] as String,
              senderName: msg['sender_name'] as String,
              message: msg['message'] as String,
              timestamp: DateTime.parse(msg['created_at'] as String),
              isRead: msg['is_read'] as bool? ?? false,
              type: _mapMessageType(msg['message_type'] as String? ?? 'text'),
            ),
          )
          .toList();
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error getting chat: $e');
      return [];
    }
  }

  MessageType _mapMessageType(String type) {
    switch (type) {
      case 'system':
        return MessageType.system;
      case 'attachment':
        return MessageType.attachment;
      default:
        return MessageType.text;
    }
  }

  /// Send a chat message
  Future<ChatMessageEntity?> sendMessage(
    String transactionId,
    String senderId,
    String senderName,
    String message,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) throw Exception('Transaction not found');

      final response = await _supabase
          .from('transaction_chat_messages')
          .insert({
            'transaction_id': txnId,
            'sender_id': senderId,
            'sender_name': senderName,
            'message': message,
            'message_type': 'text',
          })
          .select()
          .single();

      // Also add to timeline
      await _addTimelineEvent(
        txnId,
        'Message sent',
        '$senderName sent a message',
        'message_sent',
        senderId,
        senderName,
      );

      return ChatMessageEntity(
        id: response['id'] as String,
        transactionId: response['transaction_id'] as String,
        senderId: response['sender_id'] as String,
        senderName: response['sender_name'] as String,
        message: response['message'] as String,
        timestamp: DateTime.parse(response['created_at'] as String),
        isRead: false,
        type: MessageType.text,
      );
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error sending message: $e');
      return null;
    }
  }

  /// Subscribe to real-time chat messages
  void subscribeToChat(String transactionId) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return;

    _chatChannel?.unsubscribe();
    _chatChannel = _supabase
        .channel('chat_$txnId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transaction_chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'transaction_id',
            value: txnId,
          ),
          callback: (payload) {
            final msg = payload.newRecord;
            _chatStreamController.add(
              ChatMessageEntity(
                id: msg['id'] as String,
                transactionId: msg['transaction_id'] as String,
                senderId: msg['sender_id'] as String,
                senderName: msg['sender_name'] as String,
                message: msg['message'] as String,
                timestamp: DateTime.parse(msg['created_at'] as String),
                isRead: msg['is_read'] as bool? ?? false,
                type: _mapMessageType(msg['message_type'] as String? ?? 'text'),
              ),
            );
          },
        )
        .subscribe();
  }

  // ============================================================================
  // FORMS
  // ============================================================================

  /// Get form for a specific role
  Future<TransactionFormEntity?> getTransactionForm(
    String transactionId,
    FormRole role,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return null;

      final response = await _supabase
          .from('transaction_forms')
          .select()
          .eq('transaction_id', txnId)
          .eq('role', role == FormRole.seller ? 'seller' : 'buyer')
          .maybeSingle();

      if (response == null) return null;

      return _mapToFormEntity(response);
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error getting form: $e');
      return null;
    }
  }

  TransactionFormEntity _mapToFormEntity(Map<String, dynamic> data) {
    return TransactionFormEntity(
      id: data['id'] as String,
      transactionId: data['transaction_id'] as String,
      role: data['role'] == 'seller' ? FormRole.seller : FormRole.buyer,
      status: _mapFormStatus(data['status'] as String? ?? 'draft'),
      preferredDate: data['delivery_date'] != null
          ? DateTime.parse(data['delivery_date'] as String)
          : DateTime.now().add(const Duration(days: 7)),
      contactNumber: data['contact_number'] as String? ?? '',
      additionalNotes: data['additional_terms'] as String? ?? '',
      paymentMethod: data['payment_method'] as String? ?? '',
      handoverLocation: data['delivery_location'] as String? ?? '',
      handoverTimeSlot: data['handover_time_slot'] as String? ?? 'Afternoon',
      pickupOrDelivery: data['pickup_or_delivery'] as String? ?? 'Pickup',
      deliveryAddress: data['delivery_address'] as String?,
      orCrOriginalAvailable: data['or_cr_verified'] as bool? ?? false,
      deedOfSaleReady: data['deeds_of_sale_ready'] as bool? ?? false,
      releaseOfMortgage: data['release_of_mortgage'] as bool? ?? false,
      registrationValid: data['registration_valid'] as bool? ?? false,
      noLiensEncumbrances: data['no_outstanding_loans'] as bool? ?? false,
      conditionMatchesListing:
          data['mechanical_inspection_done'] as bool? ?? false,
      newIssuesDisclosure: data['new_issues_disclosure'] as String?,
      fuelLevel: data['fuel_level'] as String? ?? 'Half',
      accessoriesIncluded: data['accessories_included'] as String?,
      reviewedVehicleCondition:
          data['reviewed_vehicle_condition'] as bool? ?? false,
      understoodAuctionTerms:
          data['understood_auction_terms'] as bool? ?? false,
      willArrangeInsurance: data['will_arrange_insurance'] as bool? ?? false,
      acceptsAsIsCondition: data['accepts_as_is_condition'] as bool? ?? false,
      submittedAt: data['submitted_at'] != null
          ? DateTime.parse(data['submitted_at'] as String)
          : DateTime.now(),
      reviewNotes: data['review_notes'] as String?,
    );
  }

  FormStatus _mapFormStatus(String status) {
    switch (status) {
      case 'submitted':
        return FormStatus.submitted;
      case 'reviewed':
        return FormStatus.reviewed;
      case 'changes_requested':
        return FormStatus.changesRequested;
      case 'confirmed':
        return FormStatus.confirmed;
      default:
        return FormStatus.draft;
    }
  }

  /// Submit or update a form
  Future<TransactionFormEntity?> submitForm(TransactionFormEntity form) async {
    try {
      final txnId = await _resolveTransactionId(form.transactionId);
      if (txnId == null) throw Exception('Transaction not found');

      final roleStr = form.role == FormRole.seller ? 'seller' : 'buyer';

      final data = {
        'transaction_id': txnId,
        'role': roleStr,
        'status': 'submitted',
        'agreed_price': form.agreedPrice,
        'payment_method': form.paymentMethod,
        'delivery_date': form.preferredDate.toIso8601String(),
        'delivery_location': form.handoverLocation,
        'pickup_or_delivery': form.pickupOrDelivery,
        'delivery_address': form.deliveryAddress,
        'contact_number': form.contactNumber,
        'handover_time_slot': form.handoverTimeSlot,
        'or_cr_verified': form.orCrOriginalAvailable,
        'deeds_of_sale_ready': form.deedOfSaleReady,
        'release_of_mortgage': form.releaseOfMortgage,
        'registration_valid': form.registrationValid,
        'no_outstanding_loans': form.noLiensEncumbrances,
        'mechanical_inspection_done': form.conditionMatchesListing,
        'reviewed_vehicle_condition': form.reviewedVehicleCondition,
        'understood_auction_terms': form.understoodAuctionTerms,
        'will_arrange_insurance': form.willArrangeInsurance,
        'accepts_as_is_condition': form.acceptsAsIsCondition,
        'new_issues_disclosure': form.newIssuesDisclosure,
        'fuel_level': form.fuelLevel,
        'accessories_included': form.accessoriesIncluded,
        'additional_terms': form.additionalNotes,
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('transaction_forms')
          .upsert(data, onConflict: 'transaction_id,role')
          .select()
          .single();

      // Update transaction flags
      final flagColumn = form.role == FormRole.seller
          ? 'seller_form_submitted'
          : 'buyer_form_submitted';

      await _supabase
          .from('auction_transactions')
          .update({
            flagColumn: true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', txnId);

      // Add timeline event
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? roleStr;
      await _addTimelineEvent(
        txnId,
        '${roleStr.substring(0, 1).toUpperCase()}${roleStr.substring(1)} Form Submitted',
        '$userName submitted their transaction form',
        'form_submitted',
        userId,
        userName,
      );

      return _mapToFormEntity(response);
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error submitting form: $e');
      return null;
    }
  }

  /// Confirm other party's form
  Future<bool> confirmForm(String transactionId, FormRole roleToConfirm) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      // Update form status to confirmed
      final roleStr = roleToConfirm == FormRole.seller ? 'seller' : 'buyer';
      await _supabase
          .from('transaction_forms')
          .update({
            'status': 'confirmed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('transaction_id', txnId)
          .eq('role', roleStr);

      // Update transaction confirmed flag
      final flagColumn = roleToConfirm == FormRole.seller
          ? 'seller_confirmed'
          : 'buyer_confirmed';

      await _supabase
          .from('auction_transactions')
          .update({
            flagColumn: true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', txnId);

      // Add timeline event
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'User';
      await _addTimelineEvent(
        txnId,
        '${roleStr.substring(0, 1).toUpperCase()}${roleStr.substring(1)} Form Confirmed',
        '$userName confirmed the $roleStr form',
        'form_confirmed',
        userId,
        userName,
      );

      return true;
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error confirming form: $e');
      return false;
    }
  }

  /// Withdraw confirmation of the other party's form
  /// This allows the user to edit their decision if they confirmed by mistake
  /// or if they need to request changes from the other party
  Future<bool> withdrawConfirmation(
    String transactionId,
    FormRole roleToWithdraw,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      // Revert form status to submitted (so it can be reviewed again)
      final roleStr = roleToWithdraw == FormRole.seller ? 'seller' : 'buyer';
      await _supabase
          .from('transaction_forms')
          .update({
            'status': 'submitted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('transaction_id', txnId)
          .eq('role', roleStr);

      // Revert transaction confirmed flag
      final flagColumn = roleToWithdraw == FormRole.seller
          ? 'seller_confirmed'
          : 'buyer_confirmed';

      await _supabase
          .from('auction_transactions')
          .update({
            flagColumn: false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', txnId);

      // Add timeline event
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'User';
      await _addTimelineEvent(
        txnId,
        '${roleStr.substring(0, 1).toUpperCase()}${roleStr.substring(1)} Form Confirmation Withdrawn',
        '$userName withdrew their confirmation of the $roleStr form',
        'form_confirmation_withdrawn',
        userId,
        userName,
      );

      return true;
    } catch (e) {
      print(
        '[TransactionRealtimeDataSource] Error withdrawing confirmation: $e',
      );
      return false;
    }
  }

  /// Buyer cancels the deal
  /// This sets the transaction to deal_failed and the auction to deal_failed
  /// Seller can then choose to offer to next bidder or relist
  Future<bool> buyerCancelDeal(
    String transactionId, {
    String reason = '',
  }) async {
    print('[BuyerCancelDeal] 🚀 Starting cancel for: $transactionId');

    try {
      // Step 1: Resolve transaction ID
      print('[BuyerCancelDeal] Step 1: Resolving transaction ID...');
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) {
        print('[BuyerCancelDeal] ❌ Failed: Could not resolve transaction ID');
        return false;
      }
      print('[BuyerCancelDeal] ✅ Resolved txnId: $txnId');

      // Step 2: Get transaction summary
      print('[BuyerCancelDeal] Step 2: Getting transaction summary...');
      final txn = await _getTransactionSummary(txnId);
      if (txn == null) {
        print('[BuyerCancelDeal] ❌ Failed: Could not get transaction summary');
        return false;
      }
      print('[BuyerCancelDeal] ✅ Transaction summary: $txn');

      final auctionId = txn['auctionId'] as String?;
      if (auctionId == null) {
        print('[BuyerCancelDeal] ❌ Failed: No auction ID in transaction');
        return false;
      }
      print('[BuyerCancelDeal] ✅ Auction ID: $auctionId');

      final now = DateTime.now().toIso8601String();

      // Step 3: Update transaction status
      print('[BuyerCancelDeal] Step 3: Updating transaction status...');
      try {
        await _supabase
            .from('auction_transactions')
            .update({'status': 'deal_failed', 'updated_at': now})
            .eq('id', txnId);
        print('[BuyerCancelDeal] ✅ Transaction status updated to deal_failed');
      } catch (e) {
        print('[BuyerCancelDeal] ❌ Failed to update transaction: $e');
        return false;
      }

      // Step 4: Update auction status
      print('[BuyerCancelDeal] Step 4: Updating auction status...');
      try {
        await _supabase
            .from('auctions')
            .update({'status': 'deal_failed', 'updated_at': now})
            .eq('id', auctionId);
        print('[BuyerCancelDeal] ✅ Auction status updated to deal_failed');
      } catch (e) {
        print('[BuyerCancelDeal] ⚠️ Warning: Failed to update auction: $e');
        // Don't return false - auction update is secondary
      }

      // Step 5: Update buyer's bid status
      final buyerId = txn['buyerId'] as String?;
      print(
        '[BuyerCancelDeal] Step 5: Updating bid status for buyer: $buyerId',
      );
      if (buyerId != null) {
        try {
          await _supabase
              .from('bids')
              .update({'status': 'cancelled', 'updated_at': now})
              .eq('auction_id', auctionId)
              .eq('bidder_id', buyerId);
          print('[BuyerCancelDeal] ✅ Bid status updated to cancelled');
        } catch (e) {
          print('[BuyerCancelDeal] ⚠️ Warning: Failed to update bid: $e');
          // Don't return false - bid update is secondary
        }
      }

      // Step 6: Add timeline event
      print('[BuyerCancelDeal] Step 6: Adding timeline event...');
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'Buyer';
      try {
        await _addTimelineEvent(
          txnId,
          'Deal Cancelled by Buyer',
          reason.isNotEmpty
              ? 'Buyer cancelled the deal. Reason: $reason'
              : 'Buyer cancelled the deal.',
          'cancelled',
          userId,
          userName,
        );
        print('[BuyerCancelDeal] ✅ Timeline event added');
      } catch (e) {
        print('[BuyerCancelDeal] ⚠️ Warning: Failed to add timeline: $e');
        // Don't return false - timeline is secondary
      }

      print('[BuyerCancelDeal] 🎉 SUCCESS: Deal cancelled successfully');
      return true;
    } catch (e, stackTrace) {
      print('[BuyerCancelDeal] ❌ FATAL ERROR: $e');
      print('[BuyerCancelDeal] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Reassign the transaction to the next highest bidder when the winner fails
  /// Falls back gracefully if no secondary bidder exists
  Future<bool> offerToNextHighestBidder(String transactionId) async {
    try {
      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) return false;

      final auctionId = txn['auctionId'] as String?;
      final currentBuyerId = txn['buyerId'] as String?;
      if (auctionId == null) return false;

      final bidsResponse = await _supabase
          .from('bids')
          .select('bidder_id, bid_amount')
          .eq('auction_id', auctionId)
          .order('bid_amount', ascending: false)
          .limit(10);

      if (bidsResponse is! List) return false;

      Map<String, dynamic>? nextBid;
      for (final bid in bidsResponse) {
        final bidderId = bid['bidder_id'] as String?;
        if (bidderId != null && bidderId != currentBuyerId) {
          nextBid = Map<String, dynamic>.from(bid as Map);
          break;
        }
      }

      if (nextBid == null) return false;

      final nextBidderId = nextBid['bidder_id'] as String?;
      final amountRaw = nextBid['bid_amount'] ?? nextBid['amount'];
      final nextAmount = (amountRaw as num?)?.toDouble();

      if (nextBidderId == null || nextAmount == null) return false;

      final now = DateTime.now().toIso8601String();

      await _supabase
          .from('auction_transactions')
          .update({
            'buyer_id': nextBidderId,
            'agreed_price': nextAmount,
            'status': 'discussion',
            'seller_form_submitted': false,
            'buyer_form_submitted': false,
            'seller_confirmed': false,
            'buyer_confirmed': false,
            'admin_approved': false,
            'admin_approved_at': null,
            'delivery_status': 'pending',
            'delivery_started_at': null,
            'delivery_completed_at': null,
            'completed_at': null,
            'updated_at': now,
          })
          .eq('id', txn['transactionId'] as String);

      await _supabase
          .from('auctions')
          .update({
            'winner_id': nextBidderId,
            'winning_bid': nextAmount,
            'status': 'in_transaction',
            'offer_to_next_bidder': true,
            'allow_rebid': false,
            'updated_at': now,
          })
          .eq('id', auctionId);

      final actorId = _supabase.auth.currentUser?.id ?? '';
      final actorName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'Seller';

      await _addTimelineEvent(
        txn['transactionId'] as String,
        'Offered to next highest bidder',
        'Seller reassigned the transaction to the next eligible bidder.',
        'message_sent',
        actorId,
        actorName,
      );

      return true;
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error offering next bidder: $e');
      return false;
    }
  }

  /// Relist the auction for a fresh round of bidding
  /// Resets auction timing and clears winner fields
  Future<bool> relistAuction(String transactionId) async {
    try {
      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) return false;

      final auctionId = txn['auctionId'] as String?;
      if (auctionId == null) return false;

      final now = DateTime.now();
      final newEnd = now.add(const Duration(days: 7));

      await _supabase
          .from('auctions')
          .update({
            'status': 'active',
            'winner_id': null,
            'winning_bid': null,
            'current_bid': 0,
            'allow_rebid': true,
            'offer_to_next_bidder': false,
            'start_time': now.toIso8601String(),
            'end_time': newEnd.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', auctionId);

      final actorId = _supabase.auth.currentUser?.id ?? '';
      final actorName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'Seller';

      await _addTimelineEvent(
        txn['transactionId'] as String,
        'Listing relisted for rebid',
        'Seller reopened the auction for a new bidding round.',
        'message_sent',
        actorId,
        actorName,
      );

      return true;
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error relisting auction: $e');
      return false;
    }
  }

  // ============================================================================
  // TIMELINE
  // ============================================================================

  /// Get timeline events
  Future<List<TransactionTimelineEntity>> getTimeline(
    String transactionId,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return [];

      final response = await _supabase
          .from('transaction_timeline')
          .select()
          .eq('transaction_id', txnId)
          .order('created_at', ascending: true);

      return (response as List)
          .map(
            (event) => TransactionTimelineEntity(
              id: event['id'] as String,
              transactionId: event['transaction_id'] as String,
              title: event['title'] as String,
              description: event['description'] as String? ?? '',
              timestamp: DateTime.parse(event['created_at'] as String),
              type: _mapTimelineType(event['event_type'] as String),
              actorName: event['actor_name'] as String? ?? 'System',
            ),
          )
          .toList();
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error getting timeline: $e');
      return [];
    }
  }

  TimelineEventType _mapTimelineType(String type) {
    switch (type) {
      case 'created':
        return TimelineEventType.created;
      case 'message_sent':
        return TimelineEventType.messageSent;
      case 'form_submitted':
        return TimelineEventType.formSubmitted;
      case 'form_reviewed':
        return TimelineEventType.formReviewed;
      case 'form_confirmed':
        return TimelineEventType.formConfirmed;
      case 'admin_submitted':
        return TimelineEventType.adminSubmitted;
      case 'admin_approved':
        return TimelineEventType.adminApproved;
      case 'delivery_started':
        return TimelineEventType.deliveryStarted;
      case 'delivery_completed':
        return TimelineEventType.deliveryCompleted;
      case 'completed':
        return TimelineEventType.completed;
      case 'cancelled':
        return TimelineEventType.cancelled;
      default:
        return TimelineEventType.created;
    }
  }

  Future<void> _addTimelineEvent(
    String transactionId,
    String title,
    String description,
    String eventType,
    String actorId,
    String actorName,
  ) async {
    try {
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': title,
        'description': description,
        'event_type': eventType,
        'actor_id': actorId,
        'actor_name': actorName,
      });
    } catch (e) {
      print('[TransactionRealtimeDataSource] Error adding timeline: $e');
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Resolve transaction ID from either transaction ID or auction ID
  Future<String?> _resolveTransactionId(String idOrAuctionId) async {
    print('[_resolveTransactionId] Input: $idOrAuctionId');
    try {
      // First try as transaction ID
      final txnById = await _supabase
          .from('auction_transactions')
          .select('id')
          .eq('id', idOrAuctionId)
          .maybeSingle();

      if (txnById != null) {
        print(
          '[_resolveTransactionId] Found by transaction ID: ${txnById['id']}',
        );
        return txnById['id'] as String;
      }

      // Try as auction ID
      print('[_resolveTransactionId] Not found by ID, trying as auction ID...');
      final txnByAuction = await _supabase
          .from('auction_transactions')
          .select('id')
          .eq('auction_id', idOrAuctionId)
          .maybeSingle();

      if (txnByAuction != null) {
        print(
          '[_resolveTransactionId] Found by auction ID: ${txnByAuction['id']}',
        );
        return txnByAuction['id'] as String;
      }

      print('[_resolveTransactionId] ❌ Not found by either method');
      return null;
    } catch (e) {
      print('[_resolveTransactionId] ❌ Error: $e');
      return null;
    }
  }

  /// Fetch minimal transaction info used by fallback actions
  Future<Map<String, dynamic>?> _getTransactionSummary(
    String transactionId,
  ) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return null;

    final txn = await _supabase
        .from('auction_transactions')
        .select('id, auction_id, buyer_id, seller_id, agreed_price, status')
        .eq('id', txnId)
        .maybeSingle();

    if (txn == null) return null;

    return {
      'transactionId': txnId,
      'auctionId': txn['auction_id'] as String?,
      'buyerId': txn['buyer_id'] as String?,
      'sellerId': txn['seller_id'] as String?,
      'agreedPrice': (txn['agreed_price'] as num?)?.toDouble(),
      'status': txn['status'] as String?,
    };
  }

  /// Subscribe to transaction updates
  void subscribeToTransaction(String transactionId) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return;

    _transactionChannel?.unsubscribe();
    _transactionChannel = _supabase
        .channel('txn_$txnId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'auction_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: txnId,
          ),
          callback: (payload) {
            _transactionUpdateController.add(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Clean up subscriptions
  void dispose() {
    _chatChannel?.unsubscribe();
    _transactionChannel?.unsubscribe();
    _chatStreamController.close();
    _transactionUpdateController.close();
  }
}
