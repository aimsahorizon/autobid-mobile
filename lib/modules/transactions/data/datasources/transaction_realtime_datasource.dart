import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/transaction_review_entity.dart';
import '../../domain/entities/agreement_field_entity.dart';

/// Supabase datasource for real-time transaction data
// ... (omitting lines for brevity in explanation, but including them in actual call)

/// Handles chat, forms, timeline with real-time subscriptions
class TransactionRealtimeDataSource {
  final SupabaseClient _supabase;

  // Real-time subscriptions
  RealtimeChannel? _chatChannel;
  RealtimeChannel? _transactionChannel;
  RealtimeChannel? _formsChannel;
  RealtimeChannel? _timelineChannel;
  RealtimeChannel? _agreementFieldsChannel;
  RealtimeChannel? _sellerTxnChannel;
  RealtimeChannel? _buyerTxnChannel;

  // Stream controllers for real-time updates
  final _chatStreamController = StreamController<ChatMessageEntity>.broadcast();
  final _transactionUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _userTransactionsUpdateController = StreamController<void>.broadcast();

  TransactionRealtimeDataSource(this._supabase);

  /// Stream of new chat messages
  Stream<ChatMessageEntity> get chatStream => _chatStreamController.stream;

  /// Stream of transaction updates (single transaction)
  Stream<Map<String, dynamic>> get transactionUpdateStream =>
      _transactionUpdateController.stream;

  /// Stream of user transactions list updates
  Stream<void> get userTransactionsUpdateStream =>
      _userTransactionsUpdateController.stream;

  // ... (rest of the class) ...

  // ============================================================================
  // SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to all transactions for a user (buyer or seller)
  /// Used for refreshing the transactions list in real-time
  void subscribeToUserTransactions(String userId) {
    // Unsubscribe from previous channels to avoid duplicates
    _sellerTxnChannel?.unsubscribe();
    _buyerTxnChannel?.unsubscribe();

    // Listen for changes where user is seller
    _sellerTxnChannel = _supabase
        .channel('seller_txns_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'auction_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'seller_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
              '[TransactionRealtimeDataSource] Seller transaction update received',
            );
            _userTransactionsUpdateController.add(null);
          },
        )
        .subscribe();

    // Listen for changes where user is buyer
    _buyerTxnChannel = _supabase
        .channel('buyer_txns_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'auction_transactions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'buyer_id',
            value: userId,
          ),
          callback: (payload) {
            debugPrint(
              '[TransactionRealtimeDataSource] Buyer transaction update received',
            );
            _userTransactionsUpdateController.add(null);
          },
        )
        .subscribe();
  }

  /// Subscribe to real-time chat messages

  /// Get transaction by auction ID (for buyer/seller navigation)
  Future<TransactionEntity?> getTransactionByAuctionId(String auctionId) async {
    try {
      debugPrint(
        '[TransactionRealtimeDataSource] Getting transaction for auction: $auctionId',
      );

      final response = await _supabase.rpc(
        'get_transaction_by_auction',
        params: {'p_auction_id': auctionId},
      );

      if (response == null || (response is List && response.isEmpty)) {
        debugPrint(
          '[TransactionRealtimeDataSource] No transaction found for auction',
        );
        return null;
      }

      final data = response is List ? response.first : response;
      return _mapToTransactionEntity(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeDataSource] Error getting transaction: $e',
      );
      return null;
    }
  }

  /// Get transaction by transaction ID
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    try {
      debugPrint(
        '[TransactionRealtimeDataSource] Getting transaction: $transactionId',
      );

      // First try as transaction ID (without user joins to avoid FK errors)
      var response = await _supabase
          .from('auction_transactions')
          .select('''
            *,
            auctions(title, allows_installment, auction_vehicles(brand, model))
          ''')
          .eq('id', transactionId)
          .maybeSingle();

      // If not found, try as auction ID (get the most recent transaction)
      if (response == null) {
        debugPrint(
          '[TransactionRealtimeDataSource] Not found by ID, trying auction_id...',
        );
        final multiResponse = await _supabase
            .from('auction_transactions')
            .select('''
              *,
              auctions(title, allows_installment, auction_vehicles(brand, model))
            ''')
            .eq('auction_id', transactionId)
            .order('created_at', ascending: false)
            .limit(1);

        if (multiResponse.isNotEmpty) {
          response = multiResponse.first;
          debugPrint(
            '[TransactionRealtimeDataSource] Found ${multiResponse.length} transaction(s) by auction_id, using most recent',
          );
        }
      }

      if (response == null) {
        debugPrint('[TransactionRealtimeDataSource] Transaction not found');
        return null;
      }

      debugPrint(
        '[TransactionRealtimeDataSource] ✅ Found transaction: ${response['id']}',
      );
      debugPrint(
        '[TransactionRealtimeDataSource] Status: ${response['status']}',
      );
      debugPrint(
        '[TransactionRealtimeDataSource] Raw data keys: ${response.keys.toList()}',
      );

      try {
        final entity = _mapToTransactionEntity(response);
        debugPrint(
          '[TransactionRealtimeDataSource] ✅ Mapped to entity successfully',
        );
        return entity;
      } catch (mappingError, mappingStack) {
        debugPrint(
          '[TransactionRealtimeDataSource] ❌ Error mapping transaction: $mappingError',
        );
        debugPrint(
          '[TransactionRealtimeDataSource] Mapping stack: $mappingStack',
        );
        debugPrint('[TransactionRealtimeDataSource] Response data: $response');
        rethrow;
      }
    } catch (e, stackTrace) {
      debugPrint(
        '[TransactionRealtimeDataSource] ❌ Error getting transaction: $e',
      );
      debugPrint('[TransactionRealtimeDataSource] Stack: $stackTrace');
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

      Map<String, dynamic>? vehicle;
      if (vehicles is Map<String, dynamic>) {
        // Single object
        vehicle = vehicles;
      } else if (vehicles is List && vehicles.isNotEmpty) {
        // Array of objects
        vehicle = vehicles.first as Map<String, dynamic>?;
      }

      if (vehicle != null) {
        carName = '${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'.trim();
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
      listingId: data['auction_id'] as String? ?? '',
      sellerId: data['seller_id'] as String? ?? '',
      buyerId: data['buyer_id'] as String? ?? '',
      carName: carName,
      carImageUrl: carImageUrl,
      agreedPrice: (data['agreed_price'] as num?)?.toDouble() ?? 0.0,
      status: _mapStatus(data['status'] as String? ?? 'in_transaction'),
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : DateTime.now(),
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
      bothConfirmedAt: data['both_confirmed_at'] != null
          ? DateTime.parse(data['both_confirmed_at'] as String)
          : null,
      // Delivery Status Mapping
      deliveryStatus: _mapDeliveryStatus(
        data['delivery_status'] as String? ?? 'pending',
      ),
      deliveryStartedAt: data['delivery_started_at'] != null
          ? DateTime.parse(data['delivery_started_at'] as String)
          : null,
      deliveryCompletedAt: data['delivery_completed_at'] != null
          ? DateTime.parse(data['delivery_completed_at'] as String)
          : null,
      // Buyer Acceptance Mapping
      buyerAcceptanceStatus: _mapBuyerAcceptanceStatus(
        data['buyer_acceptance_status'] as String? ?? 'pending',
      ),
      buyerAcceptedAt: data['buyer_accepted_at'] != null
          ? DateTime.parse(data['buyer_accepted_at'] as String)
          : null,
      buyerRejectionReason: data['buyer_rejection_reason'] as String?,
      sellerRejectionReason: data['seller_rejection_reason'] as String?,
      cancelledBy: _inferCancelledBy(data),
      paymentMethod: data['payment_method'] as String? ?? 'full_payment',
      allowsInstallment: _extractAllowsInstallment(data),
    );
  }

  /// Extract allows_installment from nested auctions join or direct column
  bool _extractAllowsInstallment(Map<String, dynamic> data) {
    if (data['auctions'] is Map) {
      final auctions = data['auctions'] as Map<String, dynamic>;
      return auctions['allows_installment'] as bool? ?? false;
    }
    return data['allows_installment'] as bool? ?? false;
  }

  /// Infer who cancelled based on available rejection reasons
  String? _inferCancelledBy(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status != 'deal_failed') return null;

    final sellerReason = data['seller_rejection_reason'] as String?;
    final buyerStatus = data['buyer_acceptance_status'] as String?;

    if (sellerReason != null && sellerReason.isNotEmpty) return 'seller';
    if (buyerStatus == 'rejected') return 'buyer';
    return 'buyer'; // default assumption
  }

  DeliveryStatus _mapDeliveryStatus(String status) {
    switch (status) {
      case 'preparing':
        return DeliveryStatus.preparing;
      case 'in_transit':
        return DeliveryStatus.inTransit;
      case 'delivered':
        return DeliveryStatus.delivered;
      case 'completed':
        return DeliveryStatus.completed;
      default:
        return DeliveryStatus.pending;
    }
  }

  BuyerAcceptanceStatus _mapBuyerAcceptanceStatus(String status) {
    switch (status) {
      case 'accepted':
        return BuyerAcceptanceStatus.accepted;
      case 'rejected':
        return BuyerAcceptanceStatus.rejected;
      default:
        return BuyerAcceptanceStatus.pending;
    }
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
      debugPrint('[TransactionRealtimeDataSource] Error getting chat: $e');
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
      debugPrint('[TransactionRealtimeDataSource] Error sending message: $e');
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
      debugPrint('[TransactionRealtimeDataSource] Error getting form: $e');
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
      debugPrint(
        '[TransactionRealtimeDataSource] Submitting form for role: ${form.role}',
      );
      final txnId = await _resolveTransactionId(form.transactionId);
      if (txnId == null) throw Exception('Transaction not found');

      // Fetch transaction to get agreed_price (required field in transaction_forms)
      final txnResponse = await _supabase
          .from('auction_transactions')
          .select('agreed_price')
          .eq('id', txnId)
          .maybeSingle();

      final agreedPrice =
          (txnResponse?['agreed_price'] as num?)?.toDouble() ?? 0.0;
      debugPrint(
        '[TransactionRealtimeDataSource] Resolved agreed_price: $agreedPrice',
      );

      final roleStr = form.role == FormRole.seller ? 'seller' : 'buyer';

      final data = {
        'transaction_id': txnId,
        'role': roleStr,
        'status': 'submitted',
        'agreed_price': agreedPrice,
        'payment_method': form.paymentMethod,
        'delivery_date': form.preferredDate.toIso8601String(),
        'delivery_location': form.handoverLocation,
        'pickup_or_delivery': form.pickupOrDelivery,
        'delivery_address': form.deliveryAddress,
        'contact_number': form.contactNumber,
        'handover_time_slot': form.handoverTimeSlot,
        // Seller specific
        'or_cr_verified': form.orCrOriginalAvailable,
        'deeds_of_sale_ready': form.deedOfSaleReady,
        'release_of_mortgage': form.releaseOfMortgage,
        'registration_valid': form.registrationValid,
        'no_outstanding_loans': form.noLiensEncumbrances,
        'mechanical_inspection_done': form.conditionMatchesListing,
        'new_issues_disclosure': form.newIssuesDisclosure,
        'fuel_level': form.fuelLevel,
        'accessories_included': form.accessoriesIncluded,
        // Buyer specific
        'reviewed_vehicle_condition': form.reviewedVehicleCondition,
        'understood_auction_terms': form.understoodAuctionTerms,
        'will_arrange_insurance': form.willArrangeInsurance,
        'accepts_as_is_condition': form.acceptsAsIsCondition,
        // Shared
        'additional_terms': form.additionalNotes,
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('[TransactionRealtimeDataSource] UPSERT data: $data');

      final response = await _supabase
          .from('transaction_forms')
          .upsert(data, onConflict: 'transaction_id,role')
          .select()
          .single();

      debugPrint('[TransactionRealtimeDataSource] Form UPSERT successful');

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

      debugPrint('[TransactionRealtimeDataSource] Transaction flag updated');

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
      debugPrint('[TransactionRealtimeDataSource] ❌ Error submitting form: $e');
      if (e is PostgrestException) {
        debugPrint(
          '[TransactionRealtimeDataSource] PostgreSQL Error: ${e.message} (${e.code})',
        );
        debugPrint('[TransactionRealtimeDataSource] Details: ${e.details}');
        debugPrint('[TransactionRealtimeDataSource] Hint: ${e.hint}');
      }
      rethrow;
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
      debugPrint('[TransactionRealtimeDataSource] Error confirming form: $e');
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
      debugPrint(
        '[TransactionRealtimeDataSource] Error withdrawing confirmation: $e',
      );
      return false;
    }
  }

  /// Cancel the deal ( Buyer or Seller )
  /// This sets the transaction to deal_failed and the auction to deal_failed
  /// Seller can then choose to offer to next bidder or relist
  Future<bool> cancelDeal(
    String transactionId,
    FormRole role, {
    String reason = '',
  }) async {
    debugPrint(
      '[CancelDeal] 🚀 Starting cancel for: $transactionId (Role: $role)',
    );

    try {
      // Step 1: Resolve transaction ID
      debugPrint('[CancelDeal] Step 1: Resolving transaction ID...');
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) {
        debugPrint('[CancelDeal] ❌ Failed: Could not resolve transaction ID');
        return false;
      }
      debugPrint('[CancelDeal] ✅ Resolved txnId: $txnId');

      // Step 2: Get transaction summary
      debugPrint('[CancelDeal] Step 2: Getting transaction summary...');
      final txn = await _getTransactionSummary(txnId);
      if (txn == null) {
        debugPrint('[CancelDeal] ❌ Failed: Could not get transaction summary');
        return false;
      }
      debugPrint('[CancelDeal] ✅ Transaction summary: $txn');

      final auctionId = txn['auctionId'] as String?;
      if (auctionId == null) {
        debugPrint('[CancelDeal] ❌ Failed: No auction ID in transaction');
        return false;
      }
      debugPrint('[CancelDeal] ✅ Auction ID: $auctionId');

      final now = DateTime.now().toIso8601String();

      // Step 3: Update transaction status
      debugPrint('[CancelDeal] Step 3: Updating transaction status...');
      try {
        final updateData = {'status': 'deal_failed', 'updated_at': now};

        if (role == FormRole.buyer) {
          updateData['buyer_rejection_reason'] = reason;
          updateData['buyer_acceptance_status'] = 'rejected';
          updateData['buyer_accepted_at'] = now;
        } else {
          updateData['seller_rejection_reason'] = reason;
        }

        await _supabase
            .from('auction_transactions')
            .update(updateData)
            .eq('id', txnId);
        debugPrint('[CancelDeal] ✅ Transaction status updated to deal_failed');
      } catch (e) {
        debugPrint('[CancelDeal] ❌ Failed to update transaction: $e');
        return false;
      }

      // Step 4: Update auction status to cancelled/deal_failed
      debugPrint('[CancelDeal] Step 4: Updating auction status...');
      try {
        // Get 'cancelled' status ID (for failed deals)
        final cancelledStatusResponse = await _supabase
            .from('auction_statuses')
            .select('id')
            .eq('status_name', 'cancelled')
            .maybeSingle();

        if (cancelledStatusResponse != null) {
          await _supabase
              .from('auctions')
              .update({
                'status_id': cancelledStatusResponse['id'],
                'updated_at': now,
              })
              .eq('id', auctionId);
          debugPrint('[CancelDeal] ✅ Auction status updated to cancelled');
        } else {
          debugPrint('[CancelDeal] ⚠️ Cancelled status not found');
        }
      } catch (e) {
        debugPrint('[CancelDeal] ⚠️ Warning: Failed to update auction: $e');
        // Don't return false - auction update is secondary
      }

      // Step 5: Update buyer's bid status to 'lost' (cancelled bids are marked as lost)
      final buyerId = txn['buyerId'] as String?;
      debugPrint(
        '[CancelDeal] Step 5: Updating bid status for buyer: $buyerId',
      );
      if (buyerId != null) {
        try {
          // Get the 'lost' status ID from bid_statuses
          final lostStatusResponse = await _supabase
              .from('bid_statuses')
              .select('id')
              .eq('status_name', 'lost')
              .maybeSingle();

          if (lostStatusResponse != null) {
            final lostStatusId = lostStatusResponse['id'] as String;
            await _supabase
                .from('bids')
                .update({'status_id': lostStatusId, 'updated_at': now})
                .eq('auction_id', auctionId)
                .eq('bidder_id', buyerId);
            debugPrint('[CancelDeal] ✅ Bid status updated to lost');
          }
        } catch (e) {
          debugPrint('[CancelDeal] ⚠️ Warning: Failed to update bid: $e');
          // Don't return false - bid update is secondary
        }
      }

      // Step 6: Add timeline event
      debugPrint('[CancelDeal] Step 6: Adding timeline event...');
      final userId = _supabase.auth.currentUser?.id ?? '';
      final roleLabel = role == FormRole.buyer ? 'Buyer' : 'Seller';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ??
          roleLabel;
      try {
        await _addTimelineEvent(
          txnId,
          'Deal Cancelled by $roleLabel',
          reason.isNotEmpty
              ? '$roleLabel cancelled the deal. Reason: $reason'
              : '$roleLabel cancelled the deal.',
          'cancelled',
          userId,
          userName,
        );
        debugPrint('[CancelDeal] ✅ Timeline event added');
      } catch (e) {
        debugPrint('[CancelDeal] ⚠️ Warning: Failed to add timeline: $e');
        // Don't return false - timeline is secondary
      }

      debugPrint('[CancelDeal] 🎉 SUCCESS: Deal cancelled successfully');
      return true;
    } catch (e, stackTrace) {
      debugPrint('[CancelDeal] ❌ FATAL ERROR: $e');
      debugPrint('[CancelDeal] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Reassign the transaction to the next highest bidder when the winner fails
  /// FIXES: Uses UPDATE (not INSERT) because auction_id has UNIQUE constraint.
  /// Resets the existing transaction to a fresh state with the new buyer.
  /// Clears old chat, timeline, and agreement fields for a clean start.
  /// Notifies the new buyer immediately.
  Future<bool> offerToNextHighestBidder(String transactionId) async {
    try {
      debugPrint('[OfferNextBidder] Starting for transaction: $transactionId');

      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) {
        debugPrint('[OfferNextBidder] ❌ Transaction summary not found');
        return false;
      }

      final auctionId = txn['auctionId'] as String?;
      final currentBuyerId = txn['buyerId'] as String?;
      final txnId = txn['transactionId'] as String?;
      if (auctionId == null || txnId == null) {
        debugPrint('[OfferNextBidder] ❌ Auction/Transaction ID not found');
        return false;
      }

      debugPrint(
        '[OfferNextBidder] Auction: $auctionId, Current buyer: $currentBuyerId',
      );

      // Query all bids for this auction, ordered by amount descending
      final bidsResponse = await _supabase
          .from('bids')
          .select('''
            id,
            bidder_id,
            bid_amount,
            created_at,
            bid_statuses!inner(status_name)
          ''')
          .eq('auction_id', auctionId)
          .order('bid_amount', ascending: false);

      debugPrint('[OfferNextBidder] Found ${bidsResponse.length} bids');

      if (bidsResponse.isEmpty) {
        debugPrint('[OfferNextBidder] ❌ No bids found for this auction');
        return false;
      }

      // Find the next highest bidder (excluding current buyer and lost/refunded bids)
      Map<String, dynamic>? nextBid;
      for (final bid in bidsResponse) {
        final bidderId = bid['bidder_id'] as String?;
        final statusData = bid['bid_statuses'];
        final statusName = statusData is Map
            ? statusData['status_name'] as String?
            : null;

        debugPrint(
          '[OfferNextBidder] Bid: bidder=$bidderId, amount=${bid['bid_amount']}, status=$statusName',
        );

        if (bidderId != null &&
            bidderId != currentBuyerId &&
            statusName != 'lost' &&
            statusName != 'refunded') {
          nextBid = Map<String, dynamic>.from(bid);
          debugPrint(
            '[OfferNextBidder] ✅ Found eligible next bidder: $bidderId',
          );
          break;
        }
      }

      if (nextBid == null) {
        debugPrint('[OfferNextBidder] ❌ No eligible next bidder found');
        return false;
      }

      final nextBidderId = nextBid['bidder_id'] as String?;
      final nextAmount = (nextBid['bid_amount'] as num?)?.toDouble();

      if (nextBidderId == null || nextAmount == null) {
        debugPrint('[OfferNextBidder] ❌ Invalid next bidder data');
        return false;
      }

      debugPrint(
        '[OfferNextBidder] Reassigning to: $nextBidderId with amount: $nextAmount',
      );

      final now = DateTime.now().toIso8601String();

      // 1. UPDATE existing transaction (UNIQUE constraint on auction_id prevents INSERT)
      await _supabase
          .from('auction_transactions')
          .update({
            'buyer_id': nextBidderId,
            'agreed_price': nextAmount,
            'status': 'in_transaction',
            'seller_form_submitted': false,
            'buyer_form_submitted': false,
            'seller_confirmed': false,
            'buyer_confirmed': false,
            'admin_approved': false,
            'admin_approved_at': null,
            'both_confirmed_at': null,
            'delivery_status': 'pending',
            'delivery_started_at': null,
            'delivery_completed_at': null,
            'buyer_acceptance_status': 'pending',
            'buyer_accepted_at': null,
            'buyer_rejection_reason': null,
            'seller_rejection_reason': null,
            'completed_at': null,
            'updated_at': now,
          })
          .eq('id', txnId);
      debugPrint('[OfferNextBidder] ✅ Transaction reassigned to new buyer');

      // 2. Clear old chat messages, timeline, forms, and agreement fields
      await Future.wait([
        _supabase.from('transaction_chat').delete().eq('transaction_id', txnId),
        _supabase
            .from('transaction_timeline')
            .delete()
            .eq('transaction_id', txnId),
        _supabase
            .from('transaction_forms')
            .delete()
            .eq('transaction_id', txnId),
        _supabase
            .from('transaction_agreement_fields')
            .delete()
            .eq('transaction_id', txnId),
      ]);
      debugPrint('[OfferNextBidder] ✅ Cleared old chat/timeline/forms');

      // 3. Update auction: set auction status back to in_transaction, update price
      final inTxnStatus = await _supabase
          .from('auction_statuses')
          .select('id')
          .eq('status_name', 'in_transaction')
          .maybeSingle();

      if (inTxnStatus != null) {
        await _supabase
            .from('auctions')
            .update({
              'current_price': nextAmount,
              'status_id': inTxnStatus['id'],
              'updated_at': now,
            })
            .eq('id', auctionId);
      }

      debugPrint('[OfferNextBidder] ✅ Auction price + status updated');

      // 4. Mark the previous buyer's bid as lost
      if (currentBuyerId != null) {
        try {
          final lostStatusResponse = await _supabase
              .from('bid_statuses')
              .select('id')
              .eq('status_name', 'lost')
              .maybeSingle();

          if (lostStatusResponse != null) {
            await _supabase
                .from('bids')
                .update({
                  'status_id': lostStatusResponse['id'],
                  'updated_at': now,
                })
                .eq('auction_id', auctionId)
                .eq('bidder_id', currentBuyerId);
            debugPrint('[OfferNextBidder] ✅ Previous buyer bid marked as lost');
          }
        } catch (e) {
          debugPrint(
            '[OfferNextBidder] ⚠️ Warning: Failed to update old bid: $e',
          );
        }
      }

      // 5. Add timeline event to the fresh transaction
      final actorId = _supabase.auth.currentUser?.id ?? '';
      final actorName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'Seller';

      await _addTimelineEvent(
        txnId,
        'Transaction Started',
        'Seller reassigned the winning bid to the next highest bidder.',
        'created',
        actorId,
        actorName,
      );

      // 6. Notify the new buyer
      try {
        final auctionTitle =
            (await _supabase
                    .from('auctions')
                    .select('title')
                    .eq('id', auctionId)
                    .maybeSingle())?['title']
                as String? ??
            'an auction';

        await _supabase.from('notifications').insert({
          'user_id': nextBidderId,
          'type_id': await _getNotificationTypeId('outbid'),
          'title': 'You Won! 🎉',
          'message':
              'The seller has selected you as the new winner for "$auctionTitle" at ₱${nextAmount.toStringAsFixed(0)}. Open the transaction to begin.',
          'data': {
            'auction_id': auctionId,
            'transaction_id': txnId,
            'action': 'open_transaction',
          },
          'is_read': false,
        });
        debugPrint('[OfferNextBidder] ✅ New buyer notified');
      } catch (e) {
        debugPrint(
          '[OfferNextBidder] ⚠️ Warning: Failed to notify new buyer: $e',
        );
      }

      debugPrint('[OfferNextBidder] 🎉 SUCCESS');
      return true;
    } catch (e, stack) {
      debugPrint('[OfferNextBidder] ❌ Error: $e');
      debugPrint('[OfferNextBidder] Stack: $stack');
      return false;
    }
  }

  /// Relist the auction for a fresh round of bidding
  /// Moves auction back to pending_approval for admin review
  /// Clears ALL existing bids, auto_bid_settings, and auto_bid_queue for a fresh start
  Future<bool> relistAuction(String transactionId) async {
    try {
      debugPrint('[RelistAuction] Starting for transaction: $transactionId');

      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) {
        debugPrint('[RelistAuction] ❌ Transaction summary not found');
        return false;
      }

      final auctionId = txn['auctionId'] as String?;
      final txnId = txn['transactionId'] as String?;
      if (auctionId == null) {
        debugPrint('[RelistAuction] ❌ Auction ID not found');
        return false;
      }

      debugPrint('[RelistAuction] Auction: $auctionId');

      final now = DateTime.now().toIso8601String();

      // Get the 'pending_approval' status ID
      final pendingStatusResponse = await _supabase
          .from('auction_statuses')
          .select('id')
          .eq('status_name', 'pending_approval')
          .maybeSingle();

      if (pendingStatusResponse == null) {
        debugPrint('[RelistAuction] ❌ Pending status not found');
        return false;
      }

      final pendingStatusId = pendingStatusResponse['id'] as String;

      // 1. Update auction to pending_approval status, reset price and bid count
      await _supabase
          .from('auctions')
          .update({
            'status_id': pendingStatusId,
            'current_price': 0,
            'total_bids': 0,
            'updated_at': now,
          })
          .eq('id', auctionId);

      debugPrint('[RelistAuction] ✅ Auction updated to pending_approval');

      // 2. Clear ALL bids, auto_bid_settings, and auto_bid_queue for fresh start
      await Future.wait([
        _supabase.from('bids').delete().eq('auction_id', auctionId),
        _supabase
            .from('auto_bid_settings')
            .delete()
            .eq('auction_id', auctionId),
        _supabase.from('auto_bid_queue').delete().eq('auction_id', auctionId),
      ]);
      debugPrint('[RelistAuction] ✅ Cleared all bids and auto-bid data');

      // 3. Clear the old transaction's chat, forms, timeline, agreement fields
      if (txnId != null) {
        await Future.wait([
          _supabase
              .from('transaction_chat')
              .delete()
              .eq('transaction_id', txnId),
          _supabase
              .from('transaction_timeline')
              .delete()
              .eq('transaction_id', txnId),
          _supabase
              .from('transaction_forms')
              .delete()
              .eq('transaction_id', txnId),
          _supabase
              .from('transaction_agreement_fields')
              .delete()
              .eq('transaction_id', txnId),
        ]);
        debugPrint('[RelistAuction] ✅ Cleared old transaction data');
      }

      // 4. Delete the old transaction record so a new one can be created
      //    when the auction sells again (UNIQUE constraint on auction_id)
      if (txnId != null) {
        await _supabase.from('auction_transactions').delete().eq('id', txnId);
        debugPrint('[RelistAuction] ✅ Old transaction deleted');
      }

      // 5. Add timeline event (before deleting the transaction)
      // Note: Since we deleted the transaction, we log to debug instead
      debugPrint(
        '[RelistAuction] Auction relisted and awaiting admin approval',
      );

      debugPrint('[RelistAuction] 🎉 SUCCESS');
      return true;
    } catch (e, stack) {
      debugPrint('[RelistAuction] ❌ Error: $e');
      debugPrint('[RelistAuction] Stack: $stack');
      return false;
    }
  }

  /// Delete the auction entirely after a failed deal
  /// Marks the auction as cancelled (soft delete)
  Future<bool> deleteAuction(String transactionId) async {
    try {
      debugPrint('[DeleteAuction] Starting for transaction: $transactionId');

      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) {
        debugPrint('[DeleteAuction] ❌ Transaction summary not found');
        return false;
      }

      final auctionId = txn['auctionId'] as String?;
      final txnId = txn['transactionId'] as String?;
      if (auctionId == null) {
        debugPrint('[DeleteAuction] ❌ Auction ID not found');
        return false;
      }

      debugPrint('[DeleteAuction] Auction: $auctionId, Transaction: $txnId');

      // Get the 'cancelled' status ID
      final cancelledStatusResponse = await _supabase
          .from('auction_statuses')
          .select('id')
          .eq('status_name', 'cancelled')
          .maybeSingle();

      if (cancelledStatusResponse == null) {
        debugPrint('[DeleteAuction] ❌ Cancelled status not found');
        return false;
      }

      final cancelledStatusId = cancelledStatusResponse['id'] as String;

      // Update auction status to cancelled (soft delete)
      await _supabase
          .from('auctions')
          .update({
            'status_id': cancelledStatusId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', auctionId);

      debugPrint('[DeleteAuction] ✅ Auction marked as cancelled');

      // Add timeline event to the failed transaction
      if (txnId != null) {
        final actorId = _supabase.auth.currentUser?.id ?? '';
        final actorName =
            _supabase.auth.currentUser?.userMetadata?['display_name'] ??
            'Seller';

        await _addTimelineEvent(
          txnId,
          'Auction Deleted',
          'Seller chose to delete the auction after the deal failed.',
          'cancelled',
          actorId,
          actorName,
        );
      }

      debugPrint('[DeleteAuction] 🎉 SUCCESS');
      return true;
    } catch (e, stack) {
      debugPrint('[DeleteAuction] ❌ Error: $e');
      debugPrint('[DeleteAuction] Stack: $stack');
      return false;
    }
  }

  // ============================================================================
  // BIDDERS
  // ============================================================================

  /// Get all bidders for an auction with their bid details
  /// Used by seller to view all participants and choose next bidder
  Future<List<Map<String, dynamic>>> getAuctionBidders(
    String transactionId,
  ) async {
    try {
      debugPrint(
        '[GetAuctionBidders] Starting for transaction: $transactionId',
      );

      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) {
        debugPrint('[GetAuctionBidders] ❌ Transaction not found');
        return [];
      }

      final auctionId = txn['auctionId'] as String?;
      final currentBuyerId = txn['buyerId'] as String?;
      if (auctionId == null) {
        debugPrint('[GetAuctionBidders] ❌ Auction ID not found');
        return [];
      }

      debugPrint(
        '[GetAuctionBidders] Auction: $auctionId, CurrentBuyer: $currentBuyerId',
      );

      // First, get all bids for this auction (simpler query)
      final bidsResponse = await _supabase
          .from('bids')
          .select('id, bidder_id, bid_amount, status_id, created_at')
          .eq('auction_id', auctionId)
          .order('bid_amount', ascending: false);

      debugPrint(
        '[GetAuctionBidders] Raw bids query returned: ${bidsResponse.length} bids',
      );

      if (bidsResponse.isEmpty) {
        debugPrint(
          '[GetAuctionBidders] ⚠️ No bids found for auction $auctionId',
        );
        return [];
      }

      final List<Map<String, dynamic>> bidders = [];

      // Process each bid
      for (final bid in bidsResponse) {
        final bidderId = bid['bidder_id'] as String?;
        final bidAmount = (bid['bid_amount'] as num?)?.toDouble() ?? 0;
        final statusId = bid['status_id'] as String?;

        debugPrint(
          '[GetAuctionBidders] Processing bid: bidder=$bidderId, amount=$bidAmount',
        );

        // Get bidder info
        String userName = 'Unknown';
        String? avatarUrl;
        if (bidderId != null) {
          try {
            final userResponse = await _supabase
                .from('users')
                .select('full_name, profile_image_url')
                .eq('id', bidderId)
                .maybeSingle();

            if (userResponse != null) {
              userName = userResponse['full_name'] as String? ?? 'Unknown';
              avatarUrl = userResponse['profile_image_url'] as String?;
            }
          } catch (e) {
            debugPrint('[GetAuctionBidders] ⚠️ Failed to get user info: $e');
          }
        }

        // Get bid status
        String? statusName;
        String? statusDisplay;
        if (statusId != null) {
          try {
            final statusResponse = await _supabase
                .from('bid_statuses')
                .select('status_name, display_name')
                .eq('id', statusId)
                .maybeSingle();

            if (statusResponse != null) {
              statusName = statusResponse['status_name'] as String?;
              statusDisplay = statusResponse['display_name'] as String?;
            }
          } catch (e) {
            debugPrint('[GetAuctionBidders] ⚠️ Failed to get status info: $e');
          }
        }

        final isCurrentBuyer = bidderId == currentBuyerId;
        final isEligible =
            !isCurrentBuyer && statusName != 'lost' && statusName != 'refunded';

        bidders.add({
          'id': bid['id'],
          'bidder_id': bidderId,
          'bidder_name': userName,
          'avatar_url': avatarUrl,
          'bid_amount': bidAmount,
          'status': statusName,
          'status_display': statusDisplay,
          'created_at': bid['created_at'],
          'is_current_buyer': isCurrentBuyer,
          'is_eligible': isEligible,
        });
      }

      debugPrint('[GetAuctionBidders] Processed ${bidders.length} bidders');
      return bidders;
    } catch (e, stack) {
      debugPrint('[GetAuctionBidders] ❌ Error: $e');
      debugPrint('[GetAuctionBidders] Stack: $stack');
      return [];
    }
  }

  /// Offer to a specific bidder (not just the next highest)
  /// FIXES: Uses UPDATE (not INSERT) because auction_id has UNIQUE constraint.
  Future<bool> offerToSpecificBidder(
    String transactionId,
    String newBidderId,
    double bidAmount,
  ) async {
    try {
      debugPrint(
        '[OfferToSpecificBidder] Starting: txn=$transactionId, bidder=$newBidderId',
      );

      final txn = await _getTransactionSummary(transactionId);
      if (txn == null) {
        debugPrint('[OfferToSpecificBidder] ❌ Transaction not found');
        return false;
      }

      final auctionId = txn['auctionId'] as String?;
      final currentBuyerId = txn['buyerId'] as String?;
      final txnId = txn['transactionId'] as String?;

      if (auctionId == null || txnId == null) {
        debugPrint(
          '[OfferToSpecificBidder] ❌ Auction/Transaction ID not found',
        );
        return false;
      }

      final now = DateTime.now().toIso8601String();

      // 1. UPDATE existing transaction (UNIQUE constraint on auction_id prevents INSERT)
      await _supabase
          .from('auction_transactions')
          .update({
            'buyer_id': newBidderId,
            'agreed_price': bidAmount,
            'status': 'in_transaction',
            'seller_form_submitted': false,
            'buyer_form_submitted': false,
            'seller_confirmed': false,
            'buyer_confirmed': false,
            'admin_approved': false,
            'admin_approved_at': null,
            'both_confirmed_at': null,
            'delivery_status': 'pending',
            'delivery_started_at': null,
            'delivery_completed_at': null,
            'buyer_acceptance_status': 'pending',
            'buyer_accepted_at': null,
            'buyer_rejection_reason': null,
            'seller_rejection_reason': null,
            'completed_at': null,
            'updated_at': now,
          })
          .eq('id', txnId);
      debugPrint(
        '[OfferToSpecificBidder] ✅ Transaction reassigned to new buyer',
      );

      // 2. Clear old chat messages, timeline, forms, and agreement fields
      await Future.wait([
        _supabase.from('transaction_chat').delete().eq('transaction_id', txnId),
        _supabase
            .from('transaction_timeline')
            .delete()
            .eq('transaction_id', txnId),
        _supabase
            .from('transaction_forms')
            .delete()
            .eq('transaction_id', txnId),
        _supabase
            .from('transaction_agreement_fields')
            .delete()
            .eq('transaction_id', txnId),
      ]);
      debugPrint('[OfferToSpecificBidder] ✅ Cleared old chat/timeline/forms');

      // 3. Update auction: set status back to in_transaction, update price
      final inTxnStatus = await _supabase
          .from('auction_statuses')
          .select('id')
          .eq('status_name', 'in_transaction')
          .maybeSingle();

      if (inTxnStatus != null) {
        await _supabase
            .from('auctions')
            .update({
              'current_price': bidAmount,
              'status_id': inTxnStatus['id'],
              'updated_at': now,
            })
            .eq('id', auctionId);
      }

      debugPrint('[OfferToSpecificBidder] ✅ Auction price + status updated');

      // 4. Mark the previous buyer's bid as lost
      if (currentBuyerId != null) {
        try {
          final lostStatusResponse = await _supabase
              .from('bid_statuses')
              .select('id')
              .eq('status_name', 'lost')
              .maybeSingle();

          if (lostStatusResponse != null) {
            await _supabase
                .from('bids')
                .update({
                  'status_id': lostStatusResponse['id'],
                  'updated_at': now,
                })
                .eq('auction_id', auctionId)
                .eq('bidder_id', currentBuyerId);
            debugPrint(
              '[OfferToSpecificBidder] ✅ Previous buyer bid marked as lost',
            );
          }
        } catch (e) {
          debugPrint(
            '[OfferToSpecificBidder] ⚠️ Warning: Failed to update old bid: $e',
          );
        }
      }

      // 5. Add timeline event to the fresh transaction
      final actorId = _supabase.auth.currentUser?.id ?? '';
      final actorName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ?? 'Seller';

      await _addTimelineEvent(
        txnId,
        'Transaction Started',
        'Seller selected a new buyer for this transaction.',
        'created',
        actorId,
        actorName,
      );

      // 6. Notify the new buyer
      try {
        final auctionTitle =
            (await _supabase
                    .from('auctions')
                    .select('title')
                    .eq('id', auctionId)
                    .maybeSingle())?['title']
                as String? ??
            'an auction';

        await _supabase.from('notifications').insert({
          'user_id': newBidderId,
          'type_id': await _getNotificationTypeId('outbid'),
          'title': 'You Won! 🎉',
          'message':
              'The seller has selected you as the new winner for "$auctionTitle" at ₱${bidAmount.toStringAsFixed(0)}. Open the transaction to begin.',
          'data': {
            'auction_id': auctionId,
            'transaction_id': txnId,
            'action': 'open_transaction',
          },
          'is_read': false,
        });
        debugPrint('[OfferToSpecificBidder] ✅ New buyer notified');
      } catch (e) {
        debugPrint(
          '[OfferToSpecificBidder] ⚠️ Warning: Failed to notify new buyer: $e',
        );
      }

      debugPrint('[OfferToSpecificBidder] 🎉 SUCCESS');
      return true;
    } catch (e, stack) {
      debugPrint('[OfferToSpecificBidder] ❌ Error: $e');
      debugPrint('[OfferToSpecificBidder] Stack: $stack');
      return false;
    }
  }

  // ============================================================================
  // DELIVERY & COMPLETION
  // ============================================================================

  /// Update delivery status (Seller only)
  Future<bool> updateDeliveryStatus(
    String transactionId,
    String sellerId,
    DeliveryStatus status,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      String statusStr;
      switch (status) {
        case DeliveryStatus.preparing:
          statusStr = 'preparing';
          break;
        case DeliveryStatus.inTransit:
          statusStr = 'in_transit';
          break;
        case DeliveryStatus.delivered:
          statusStr = 'delivered';
          break;
        default:
          return false;
      }

      final response = await _supabase.rpc(
        'update_delivery_status',
        params: {
          'p_transaction_id': txnId,
          'p_seller_id': sellerId,
          'p_delivery_status': statusStr,
        },
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint('[TransactionRealtimeDataSource] Error updating delivery: $e');
      return false;
    }
  }

  /// Respond to delivery (Buyer only) - Accept or Reject
  Future<bool> respondToDelivery({
    required String transactionId,
    required String buyerId,
    required bool accepted,
    String? rejectionReason,
    List<File>? rejectionPhotos,
  }) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      // 1. Upload photos if rejected and photos provided
      List<String>? photoUrls;
      if (!accepted && rejectionPhotos != null && rejectionPhotos.isNotEmpty) {
        photoUrls = await _uploadRejectionPhotos(txnId, rejectionPhotos);

        // Update the photos column manually first since RPC doesn't accept arrays well in all versions
        // or to keep RPC signature simple.
        await _supabase
            .from('auction_transactions')
            .update({'buyer_rejection_photos': photoUrls})
            .eq('id', txnId);
      }

      // 2. Call RPC to handle status updates and notifications
      final response = await _supabase.rpc(
        'handle_buyer_acceptance',
        params: {
          'p_transaction_id': txnId,
          'p_buyer_id': buyerId,
          'p_accepted': accepted,
          'p_rejection_reason': rejectionReason,
        },
      );

      return response['success'] == true;
    } catch (e) {
      debugPrint(
        '[TransactionRealtimeDataSource] Error responding to delivery: $e',
      );
      return false;
    }
  }

  /// Helper: Upload rejection photos
  Future<List<String>> _uploadRejectionPhotos(
    String transactionId,
    List<File> photos,
  ) async {
    final List<String> urls = [];
    try {
      for (var i = 0; i < photos.length; i++) {
        final file = photos[i];
        final ext = file.path.split('.').last;
        final path = 'rejections/$transactionId/proof_$i.$ext';

        await _supabase.storage
            .from('auction-images')
            .upload(path, file, fileOptions: const FileOptions(upsert: true));

        final url = _supabase.storage.from('auction-images').getPublicUrl(path);
        urls.add(url);
      }
    } catch (e) {
      debugPrint('[TransactionRealtimeDataSource] Error uploading photos: $e');
    }
    return urls;
  }

  // ============================================================================
  // REVIEWS
  // ============================================================================

  /// Submit a transaction review
  Future<TransactionReviewEntity?> submitReview({
    required String transactionId,
    required String reviewerId,
    required String revieweeId,
    required int rating,
    int? ratingCommunication,
    int? ratingReliability,
    String? comment,
  }) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return null;

      final data = {
        'transaction_id': txnId,
        'reviewer_id': reviewerId,
        'reviewee_id': revieweeId,
        'rating': rating,
        'rating_communication': ratingCommunication,
        'rating_reliability': ratingReliability,
        'comment': comment,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('transaction_reviews')
          .upsert(data, onConflict: 'transaction_id,reviewer_id')
          .select()
          .single();

      return _mapToReviewEntity(response);
    } catch (e) {
      debugPrint('[TransactionRealtimeDataSource] Error submitting review: $e');
      return null;
    }
  }

  /// Get review for a transaction by a specific user
  Future<TransactionReviewEntity?> getReview(
    String transactionId,
    String reviewerId,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return null;

      final response = await _supabase
          .from('transaction_reviews')
          .select()
          .eq('transaction_id', txnId)
          .eq('reviewer_id', reviewerId)
          .maybeSingle();

      if (response == null) return null;
      return _mapToReviewEntity(response);
    } catch (e) {
      debugPrint('[TransactionRealtimeDataSource] Error getting review: $e');
      return null;
    }
  }

  TransactionReviewEntity _mapToReviewEntity(Map<String, dynamic> data) {
    return TransactionReviewEntity(
      id: data['id'] as String,
      transactionId: data['transaction_id'] as String,
      reviewerId: data['reviewer_id'] as String,
      revieweeId: data['reviewee_id'] as String,
      rating: data['rating'] as int,
      ratingCommunication: data['rating_communication'] as int?,
      ratingReliability: data['rating_reliability'] as int?,
      comment: data['comment'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
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
      debugPrint('[TransactionRealtimeDataSource] Error getting timeline: $e');
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
      debugPrint('[TransactionRealtimeDataSource] Error adding timeline: $e');
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  /// Look up a notification_type ID by its type_name string.
  /// Falls back to 'message_received' if the requested type doesn't exist.
  Future<String?> _getNotificationTypeId(String typeName) async {
    try {
      final row = await _supabase
          .from('notification_types')
          .select('id')
          .eq('type_name', typeName)
          .maybeSingle();
      if (row != null) return row['id'] as String?;

      // Fallback
      final fallback = await _supabase
          .from('notification_types')
          .select('id')
          .eq('type_name', 'message_received')
          .maybeSingle();
      return fallback?['id'] as String?;
    } catch (e) {
      debugPrint('[_getNotificationTypeId] ❌ Error: $e');
      return null;
    }
  }

  /// Resolve transaction ID from either transaction ID or auction ID
  Future<String?> _resolveTransactionId(String idOrAuctionId) async {
    debugPrint('[_resolveTransactionId] Input: $idOrAuctionId');
    try {
      // First try as transaction ID
      final txnById = await _supabase
          .from('auction_transactions')
          .select('id')
          .eq('id', idOrAuctionId)
          .maybeSingle();

      if (txnById != null) {
        debugPrint(
          '[_resolveTransactionId] Found by transaction ID: ${txnById['id']}',
        );
        return txnById['id'] as String;
      }

      // Try as auction ID (get most recent to handle multiple transactions)
      debugPrint(
        '[_resolveTransactionId] Not found by ID, trying as auction ID...',
      );
      final txnByAuctionList = await _supabase
          .from('auction_transactions')
          .select('id')
          .eq('auction_id', idOrAuctionId)
          .order('created_at', ascending: false)
          .limit(1);

      if (txnByAuctionList.isNotEmpty) {
        debugPrint(
          '[_resolveTransactionId] Found by auction ID: ${txnByAuctionList.first['id']}',
        );
        return txnByAuctionList.first['id'] as String;
      }

      debugPrint('[_resolveTransactionId] ❌ Not found by either method');
      return null;
    } catch (e) {
      debugPrint('[_resolveTransactionId] ❌ Error: $e');
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

  /// Subscribe to transaction form changes (INSERT + UPDATE)
  /// Fires when the other party submits or updates their form
  void subscribeToForms(String transactionId) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return;

    _formsChannel?.unsubscribe();
    _formsChannel = _supabase
        .channel('forms_$txnId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transaction_forms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'transaction_id',
            value: txnId,
          ),
          callback: (payload) {
            debugPrint(
              '[TransactionRealtimeDataSource] 📝 Form change detected: ${payload.eventType}',
            );
            // Re-use the transaction update stream to trigger a full reload
            _transactionUpdateController.add(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Subscribe to transaction timeline changes (INSERT)
  /// Fires when any timeline event is added (covers most activities)
  void subscribeToTimeline(String transactionId) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return;

    _timelineChannel?.unsubscribe();
    _timelineChannel = _supabase
        .channel('timeline_$txnId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'transaction_timeline',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'transaction_id',
            value: txnId,
          ),
          callback: (payload) {
            debugPrint(
              '[TransactionRealtimeDataSource] ⏱️ Timeline event detected',
            );
            // Re-use the transaction update stream to trigger a full reload
            _transactionUpdateController.add(payload.newRecord);
          },
        )
        .subscribe();
  }

  // ============================================================================
  // AGREEMENT FIELDS (Collaborative Form)
  // ============================================================================

  /// Load all agreement fields for a transaction
  Future<List<AgreementFieldEntity>> getAgreementFields(
    String transactionId,
  ) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return [];

    final response = await _supabase
        .from('transaction_agreement_fields')
        .select()
        .eq('transaction_id', txnId)
        .order('category')
        .order('display_order');

    return (response as List)
        .map(
          (e) => AgreementFieldEntity(
            id: e['id'] as String,
            transactionId: e['transaction_id'] as String,
            label: e['label'] as String? ?? '',
            value: e['value'] as String? ?? '',
            fieldType: e['field_type'] as String? ?? 'text',
            category: e['category'] as String? ?? 'general',
            options: e['options'] as String?,
            addedBy: e['added_by'] as String?,
            displayOrder: e['display_order'] as int? ?? 0,
          ),
        )
        .toList();
  }

  /// Add a new agreement field
  Future<AgreementFieldEntity?> addAgreementField({
    required String transactionId,
    required String label,
    String value = '',
    String fieldType = 'text',
    String category = 'general',
    String? options,
  }) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return null;

    final userId = _supabase.auth.currentUser?.id;

    // Get next display order
    final maxOrder = await _supabase
        .from('transaction_agreement_fields')
        .select('display_order')
        .eq('transaction_id', txnId)
        .order('display_order', ascending: false)
        .limit(1);

    final nextOrder = maxOrder.isNotEmpty
        ? ((maxOrder.first['display_order'] as int?) ?? 0) + 1
        : 0;

    final response = await _supabase
        .from('transaction_agreement_fields')
        .insert({
          'transaction_id': txnId,
          'label': label,
          'value': value,
          'field_type': fieldType,
          'category': category,
          'options': options,
          'added_by': userId,
          'display_order': nextOrder,
        })
        .select()
        .single();

    return AgreementFieldEntity(
      id: response['id'] as String,
      transactionId: txnId,
      label: response['label'] as String? ?? '',
      value: response['value'] as String? ?? '',
      fieldType: response['field_type'] as String? ?? 'text',
      category: response['category'] as String? ?? 'general',
      options: response['options'] as String?,
      addedBy: response['added_by'] as String?,
      displayOrder: response['display_order'] as int? ?? 0,
    );
  }

  /// Update a single agreement field value
  Future<bool> updateAgreementField(String fieldId, String value) async {
    try {
      await _supabase
          .from('transaction_agreement_fields')
          .update({
            'value': value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', fieldId);
      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error updating agreement field: $e');
      return false;
    }
  }

  /// Delete an agreement field
  Future<bool> deleteAgreementField(String fieldId) async {
    try {
      await _supabase
          .from('transaction_agreement_fields')
          .delete()
          .eq('id', fieldId);
      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error deleting agreement field: $e');
      return false;
    }
  }

  // ============================================================================
  // AGREEMENT LOCK / CONFIRM / FINALIZE
  // ============================================================================

  /// Lock the agreement (user signals they are done editing)
  Future<bool> lockAgreement(String transactionId, FormRole role) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      final col = role == FormRole.seller
          ? 'seller_form_submitted'
          : 'buyer_form_submitted';
      await _supabase
          .from('auction_transactions')
          .update({col: true, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', txnId);

      final roleLabel = role == FormRole.seller ? 'Seller' : 'Buyer';
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ??
          roleLabel;
      await _addTimelineEvent(
        txnId,
        '$roleLabel Locked Agreement',
        '$userName locked the agreement',
        'form_submitted',
        userId,
        userName,
      );

      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error locking agreement: $e');
      return false;
    }
  }

  /// Unlock the agreement (resets ALL confirmations)
  Future<bool> unlockAgreement(String transactionId, FormRole role) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      final col = role == FormRole.seller
          ? 'seller_form_submitted'
          : 'buyer_form_submitted';
      await _supabase
          .from('auction_transactions')
          .update({
            col: false,
            'seller_confirmed': false,
            'buyer_confirmed': false,
            'both_confirmed_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', txnId);

      final roleLabel = role == FormRole.seller ? 'Seller' : 'Buyer';
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ??
          roleLabel;
      await _addTimelineEvent(
        txnId,
        '$roleLabel Unlocked Agreement',
        '$userName unlocked the agreement for editing',
        'form_confirmation_withdrawn',
        userId,
        userName,
      );

      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error unlocking agreement: $e');
      return false;
    }
  }

  /// Confirm the agreement (sets current user's confirmed flag)
  Future<bool> confirmAgreement(String transactionId, FormRole role) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      final myConfCol = role == FormRole.seller
          ? 'seller_confirmed'
          : 'buyer_confirmed';
      final otherConfCol = role == FormRole.seller
          ? 'buyer_confirmed'
          : 'seller_confirmed';

      // Check if other party already confirmed
      final txn = await _supabase
          .from('auction_transactions')
          .select(otherConfCol)
          .eq('id', txnId)
          .single();

      final otherConfirmed = txn[otherConfCol] as bool? ?? false;

      final updateData = <String, dynamic>{
        myConfCol: true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If both now confirmed, set timestamp for grace period
      if (otherConfirmed) {
        updateData['both_confirmed_at'] = DateTime.now().toIso8601String();
      }

      await _supabase
          .from('auction_transactions')
          .update(updateData)
          .eq('id', txnId);

      final roleLabel = role == FormRole.seller ? 'Seller' : 'Buyer';
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ??
          roleLabel;
      await _addTimelineEvent(
        txnId,
        '$roleLabel Confirmed Agreement',
        '$userName confirmed the transaction agreement',
        'form_confirmed',
        userId,
        userName,
      );

      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error confirming agreement: $e');
      return false;
    }
  }

  /// Withdraw agreement confirmation
  Future<bool> withdrawAgreementConfirmation(
    String transactionId,
    FormRole role,
  ) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      final myConfCol = role == FormRole.seller
          ? 'seller_confirmed'
          : 'buyer_confirmed';

      await _supabase
          .from('auction_transactions')
          .update({
            myConfCol: false,
            'both_confirmed_at': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', txnId);

      final roleLabel = role == FormRole.seller ? 'Seller' : 'Buyer';
      final userId = _supabase.auth.currentUser?.id ?? '';
      final userName =
          _supabase.auth.currentUser?.userMetadata?['display_name'] ??
          roleLabel;
      await _addTimelineEvent(
        txnId,
        '$roleLabel Withdrew Confirmation',
        '$userName withdrew their confirmation',
        'form_confirmation_withdrawn',
        userId,
        userName,
      );

      return true;
    } catch (e) {
      debugPrint('[TransactionDS] Error withdrawing confirmation: $e');
      return false;
    }
  }

  /// Finalize transaction (called after 15s grace period)
  Future<bool> finalizeTransaction(String transactionId) async {
    try {
      final txnId = await _resolveTransactionId(transactionId);
      if (txnId == null) return false;

      final result = await _supabase.rpc(
        'finalize_transaction',
        params: {'p_transaction_id': txnId},
      );

      if (result is Map && result['success'] == true) {
        return true;
      }
      debugPrint('[TransactionDS] Finalize result: $result');
      return false;
    } catch (e) {
      debugPrint('[TransactionDS] Error finalizing: $e');
      return false;
    }
  }

  /// Subscribe to agreement fields changes (realtime)
  void subscribeToAgreementFields(String transactionId) async {
    final txnId = await _resolveTransactionId(transactionId);
    if (txnId == null) return;

    _agreementFieldsChannel?.unsubscribe();
    _agreementFieldsChannel = _supabase
        .channel('agreement_fields_$txnId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'transaction_agreement_fields',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'transaction_id',
            value: txnId,
          ),
          callback: (payload) {
            debugPrint(
              '[TransactionDS] 📋 Agreement field change: ${payload.eventType}',
            );
            _transactionUpdateController.add(payload.newRecord);
          },
        )
        .subscribe();
  }

  /// Unsubscribe from detail-level channels (chat, transaction, forms)
  /// Called by individual controllers when they are disposed.
  /// Does NOT close the shared stream controllers or user-level channels.
  void unsubscribeDetailChannels() {
    _chatChannel?.unsubscribe();
    _chatChannel = null;
    _transactionChannel?.unsubscribe();
    _transactionChannel = null;
    _formsChannel?.unsubscribe();
    _formsChannel = null;
    _timelineChannel?.unsubscribe();
    _timelineChannel = null;
    _agreementFieldsChannel?.unsubscribe();
    _agreementFieldsChannel = null;
  }

  /// Full cleanup — closes all channels AND stream controllers.
  /// Only call when the datasource itself is being permanently destroyed.
  void dispose() {
    _chatChannel?.unsubscribe();
    _transactionChannel?.unsubscribe();
    _formsChannel?.unsubscribe();
    _timelineChannel?.unsubscribe();
    _agreementFieldsChannel?.unsubscribe();
    _sellerTxnChannel?.unsubscribe();
    _buyerTxnChannel?.unsubscribe();
    _chatStreamController.close();
    _transactionUpdateController.close();
    _userTransactionsUpdateController.close();
  }

  /// Update payment_method on the transaction
  Future<void> updatePaymentMethod(String transactionId, String method) async {
    await _supabase
        .from('auction_transactions')
        .update({
          'payment_method': method,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transactionId);
  }
}
