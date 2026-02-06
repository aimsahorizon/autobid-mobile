import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/buyer_transaction_entity.dart';

/// Supabase datasource for buyer transaction operations
/// Handles buyer-side transaction management for won auctions
class BuyerTransactionSupabaseDataSource {
  final SupabaseClient _supabase;

  BuyerTransactionSupabaseDataSource(this._supabase);

  /// Get all transactions for buyer
  /// Joins with auctions and seller users
  Future<List<Map<String, dynamic>>> getBuyerTransactions(
    String buyerId,
  ) async {
    try {
      final response = await _supabase
          .from('auction_transactions')
          .select('''
            id, auction_id, seller_id, buyer_id, agreed_price, status, 
            created_at, completed_at, seller_form_submitted, buyer_form_submitted, 
            seller_confirmed, buyer_confirmed, admin_approved, admin_approved_at, 
            delivery_status, delivery_started_at, delivery_completed_at,
            buyer_acceptance_status, buyer_accepted_at, buyer_rejection_reason,
            auctions!auction_id(id, title, auction_vehicles(brand, model, year)),
            users!seller_id(id, full_name, profile_image_url)
          ''')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get buyer transactions: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get buyer transactions: $e');
    }
  }

  /// Get single transaction detail
  /// Includes all related data including delivery and acceptance status
  /// Supports lookup by transaction ID or auction ID
  Future<Map<String, dynamic>> getTransactionDetail(
    String idOrAuctionId,
  ) async {
    try {
      // 1. Try by transaction ID
      var response = await _supabase
          .from('auction_transactions')
          .select('''
            *,
            auctions!auction_id(id, title, auction_vehicles(brand, model, year)),
            users!seller_id(id, full_name, email, profile_image_url)
          ''')
          .eq('id', idOrAuctionId)
          .maybeSingle();

      // 2. If not found, try by auction ID
      if (response == null) {
        response = await _supabase
            .from('auction_transactions')
            .select('''
              *,
              auctions!auction_id(id, title, auction_vehicles(brand, model, year)),
              users!seller_id(id, full_name, email, profile_image_url)
            ''')
            .eq('auction_id', idOrAuctionId)
            .maybeSingle();
      }

      if (response == null) {
        throw Exception('Transaction not found');
      }

      return response;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get transaction detail: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get transaction detail: $e');
    }
  }

  /// Get transaction as BuyerTransactionEntity
  Future<BuyerTransactionEntity?> getTransaction(String idOrAuctionId) async {
    try {
      final data = await getTransactionDetail(idOrAuctionId);
      return _mapToEntity(data);
    } catch (e) {
      debugPrint('[BuyerTransactionDS] Error getting transaction: $e');
      return null;
    }
  }

  /// Map Supabase data to BuyerTransactionEntity
  BuyerTransactionEntity _mapToEntity(Map<String, dynamic> data) {
    final auctions = data['auctions'] as Map<String, dynamic>?;
    final vehiclesList = auctions != null
        ? auctions['auction_vehicles'] as List?
        : null;
    final vehicle = (vehiclesList != null && vehiclesList.isNotEmpty)
        ? vehiclesList.first
        : null;

    final carName = vehicle != null
        ? '${vehicle['year'] ?? ''} ${vehicle['brand'] ?? ''} ${vehicle['model'] ?? ''}'
              .trim()
        : (auctions?['title'] ?? 'Unknown Vehicle');

    // Get cover photo URL
    String carImageUrl = '';
    // We'd need another join for photos if we want them here,
    // but for now we'll use a placeholder or empty string

    return BuyerTransactionEntity(
      id: data['id'] as String,
      auctionId: data['auction_id'] as String,
      sellerId: data['seller_id'] as String,
      buyerId: data['buyer_id'] as String,
      carName: carName,
      carImageUrl: carImageUrl,
      agreedPrice: (data['agreed_price'] as num?)?.toDouble() ?? 0,
      depositPaid: 0, // In newer schema, deposit is separate
      status: _mapTransactionStatus(data['status'] as String?),
      createdAt: DateTime.parse(data['created_at'] as String),
      completedAt: data['completed_at'] != null
          ? DateTime.parse(data['completed_at'] as String)
          : null,
      buyerFormSubmitted: data['buyer_form_submitted'] as bool? ?? false,
      sellerFormSubmitted: data['seller_form_submitted'] as bool? ?? false,
      buyerConfirmed: data['buyer_confirmed'] as bool? ?? false,
      sellerConfirmed: data['seller_confirmed'] as bool? ?? false,
      adminApproved: data['admin_approved'] as bool? ?? false,
      adminApprovedAt: data['admin_approved_at'] != null
          ? DateTime.parse(data['admin_approved_at'] as String)
          : null,
      deliveryStatus: _mapDeliveryStatus(data['delivery_status'] as String?),
      deliveryStartedAt: data['delivery_started_at'] != null
          ? DateTime.parse(data['delivery_started_at'] as String)
          : null,
      deliveryCompletedAt: data['delivery_completed_at'] != null
          ? DateTime.parse(data['delivery_completed_at'] as String)
          : null,
      buyerAcceptanceStatus: _mapAcceptanceStatus(
        data['buyer_acceptance_status'] as String?,
      ),
      buyerAcceptedAt: data['buyer_accepted_at'] != null
          ? DateTime.parse(data['buyer_accepted_at'] as String)
          : null,
      buyerRejectionReason: data['buyer_rejection_reason'] as String?,
    );
  }

  TransactionStatus _mapTransactionStatus(String? status) {
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

  DeliveryStatus _mapDeliveryStatus(String? status) {
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

  BuyerAcceptanceStatus _mapAcceptanceStatus(String? status) {
    switch (status) {
      case 'accepted':
        return BuyerAcceptanceStatus.accepted;
      case 'rejected':
        return BuyerAcceptanceStatus.rejected;
      default:
        return BuyerAcceptanceStatus.pending;
    }
  }

  /// Accept vehicle after delivery
  /// Calls RPC function to handle buyer acceptance
  Future<bool> acceptVehicle(String transactionId, String buyerId) async {
    try {
      await _supabase.rpc(
        'handle_buyer_acceptance',
        params: {
          'p_transaction_id': transactionId,
          'p_buyer_id': buyerId,
          'p_accepted': true,
          'p_rejection_reason': null,
        },
      );

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Failed to accept vehicle: ${e.message}');
    } catch (e) {
      throw Exception('Failed to accept vehicle: $e');
    }
  }

  /// Reject vehicle after delivery
  /// Calls RPC function with rejection reason
  Future<bool> rejectVehicle(
    String transactionId,
    String buyerId,
    String reason,
  ) async {
    try {
      await _supabase.rpc(
        'handle_buyer_acceptance',
        params: {
          'p_transaction_id': transactionId,
          'p_buyer_id': buyerId,
          'p_accepted': false,
          'p_rejection_reason': reason,
        },
      );

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Failed to reject vehicle: ${e.message}');
    } catch (e) {
      throw Exception('Failed to reject vehicle: $e');
    }
  }

  /// Get chat messages for transaction
  Future<List<TransactionChatMessage>> getChatMessages(
    String transactionId,
  ) async {
    try {
      final response = await _supabase
          .from('transaction_chat_messages')
          .select('*')
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response).map((data) {
        return TransactionChatMessage(
          id: data['id'] as String,
          transactionId: data['transaction_id'] as String,
          senderId: data['sender_id'] as String,
          senderName: data['sender_name'] as String? ?? 'Unknown',
          message: data['message'] as String,
          timestamp: DateTime.parse(data['created_at'] as String),
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get chat messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get chat messages: $e');
    }
  }

  /// Send chat message
  Future<bool> sendMessage(
    String transactionId,
    String senderId,
    String senderName,
    String message,
  ) async {
    try {
      await _supabase.from('transaction_chat_messages').insert({
        'transaction_id': transactionId,
        'sender_id': senderId,
        'sender_name': senderName,
        'message': message,
        'message_type': 'text',
      });
      return true;
    } on PostgrestException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Get transaction form (buyer or seller)
  Future<BuyerTransactionFormEntity?> getTransactionForm(
    String transactionId,
    FormRole role,
  ) async {
    try {
      final roleStr = role == FormRole.buyer ? 'buyer' : 'seller';
      final response = await _supabase
          .from('transaction_forms')
          .select('*')
          .eq('transaction_id', transactionId)
          .eq('role', roleStr)
          .maybeSingle();

      if (response == null) return null;

      return BuyerTransactionFormEntity(
        id: response['id'] as String,
        transactionId: response['transaction_id'] as String,
        role: role,
        fullName:
            response['full_name'] as String? ??
            '', // Maps to old field if still exists or fallback
        email: response['email'] as String? ?? '',
        phone: response['contact_number'] as String? ?? '',
        address: response['delivery_address'] as String? ?? '',
        city: '',
        province: '',
        zipCode: '',
        idType: '',
        idNumber: '',
        idPhotoUrl: null,
        paymentMethod: response['payment_method'] as String? ?? '',
        bankName: response['bank_name'] as String?,
        accountNumber: response['account_number'] as String?,
        deliveryMethod: response['pickup_or_delivery'] as String? ?? '',
        deliveryAddress: response['delivery_address'] as String?,
        agreedToTerms: true,
        submittedAt: response['submitted_at'] != null
            ? DateTime.parse(response['submitted_at'] as String)
            : null,
        isConfirmed: response['status'] == 'confirmed',
      );
    } on PostgrestException catch (e) {
      throw Exception('Failed to get transaction form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get transaction form: $e');
    }
  }

  /// Submit buyer form
  Future<bool> submitForm(BuyerTransactionFormEntity form) async {
    try {
      // Note: This logic might need to be refined to match the newer transaction_forms schema
      // which uses more specific fields.
      await _supabase.from('transaction_forms').upsert({
        'transaction_id': form.transactionId,
        'role': 'buyer',
        'status': 'submitted',
        'payment_method': form.paymentMethod,
        'bank_name': form.bankName,
        'account_number': form.accountNumber,
        'pickup_or_delivery': form.deliveryMethod,
        'delivery_address': form.deliveryAddress,
        'contact_number': form.phone,
        'submitted_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'transaction_id,role');

      // Update transaction to mark buyer form submitted
      await _supabase
          .from('auction_transactions')
          .update({'buyer_form_submitted': true})
          .eq('id', form.transactionId);

      return true;
    } on PostgrestException catch (e) {
      throw Exception('Failed to submit form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to submit form: $e');
    }
  }

  /// Get timeline events
  Future<List<TransactionTimelineEvent>> getTimeline(
    String transactionId,
  ) async {
    try {
      final response = await _supabase
          .from('transaction_timeline')
          .select('*')
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response).map((data) {
        return TransactionTimelineEvent(
          id: data['id'] as String,
          transactionId: data['transaction_id'] as String,
          title: data['title'] as String,
          description: data['description'] as String? ?? '',
          timestamp: DateTime.parse(data['created_at'] as String),
          type: _mapTimelineEventType(data['event_type'] as String?),
          actorName: data['actor_name'] as String? ?? 'System',
        );
      }).toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to get timeline: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get timeline: $e');
    }
  }

  TimelineEventType _mapTimelineEventType(String? type) {
    switch (type) {
      case 'created':
        return TimelineEventType.created;
      case 'form_submitted':
        return TimelineEventType.formSubmitted;
      case 'form_confirmed':
        return TimelineEventType.formConfirmed;
      case 'admin_review':
        return TimelineEventType.adminReview;
      case 'admin_approved':
        return TimelineEventType.adminApproved;
      case 'completed':
        return TimelineEventType.completed;
      case 'cancelled':
        return TimelineEventType.cancelled;
      default:
        return TimelineEventType.created;
    }
  }

  /// Confirm buyer form (after reviewing seller's form)
  Future<void> confirmBuyerForm(String transactionId) async {
    try {
      await _supabase
          .from('auction_transactions')
          .update({'buyer_confirmed': true})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Buyer Confirmed',
        'description': 'Buyer has confirmed transaction details',
        'event_type': 'form_confirmed',
        'actor_name': 'Buyer',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to confirm buyer form: ${e.message}');
    } catch (e) {
      throw Exception('Failed to confirm buyer form: $e');
    }
  }

  /// Get user's won bids
  Future<List<Map<String, dynamic>>> getWonBids(String userId) async {
    try {
      final response = await _supabase
          .from('bids')
          .select(
            'id, bid_amount, created_at, vehicles!vehicle_id(id, brand, model, year, main_image_url, status, end_time, current_bid)',
          )
          .eq('bidder_id', userId)
          .eq('status', 'won')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get won bids: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get won bids: $e');
    }
  }

  /// Cancel transaction (buyer side)
  Future<void> cancelTransaction({
    required String transactionId,
    String reason = '',
  }) async {
    try {
      await _supabase
          .from('auction_transactions')
          .update({'status': 'cancelled'})
          .eq('id', transactionId);

      // Add timeline event
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': 'Transaction Cancelled',
        'description':
            'Transaction was cancelled by buyer. ${reason.isNotEmpty ? "Reason: $reason" : ""}',
        'event_type': 'cancelled',
        'actor_name': 'Buyer',
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to cancel transaction: ${e.message}');
    } catch (e) {
      throw Exception('Failed to cancel transaction: $e');
    }
  }
}
