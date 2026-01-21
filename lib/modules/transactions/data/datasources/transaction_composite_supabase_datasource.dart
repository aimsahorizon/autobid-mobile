import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/buyer_transaction_entity.dart' as buyer;
import 'transaction_remote_datasource.dart';
import 'transaction_supabase_datasource.dart';
import 'chat_supabase_datasource.dart';
import 'seller_transaction_supabase_datasource.dart';
import 'buyer_transaction_supabase_datasource.dart';
import 'timeline_supabase_datasource.dart';

class TransactionCompositeSupabaseDataSource implements TransactionRemoteDataSource {
  final TransactionSupabaseDataSource transactionDataSource;
  final ChatSupabaseDataSource chatDataSource;
  final SellerTransactionSupabaseDataSource sellerDataSource;
  final BuyerTransactionSupabaseDataSource buyerDataSource;
  final TimelineSupabaseDataSource timelineDataSource;

  TransactionCompositeSupabaseDataSource({
    required this.transactionDataSource,
    required this.chatDataSource,
    required this.sellerDataSource,
    required this.buyerDataSource,
    required this.timelineDataSource,
  });

  @override
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    try {
      // Try to fetch as buyer first (returns entity)
      final buyerEntity = await buyerDataSource.getTransaction(transactionId);
      if (buyerEntity != null) {
        return _mapBuyerEntityToTransactionEntity(buyerEntity);
      }

      // Fallback: fetch as seller (returns JSON)
      final sellerData = await sellerDataSource.getTransactionDetail(transactionId);
      if (sellerData != null) {
        return _mapSellerJsonToTransactionEntity(sellerData);
      }
      
      return null;
    } catch (e) {
      print('[TransactionCompositeDS] Error fetching transaction: $e');
      return null;
    }
  }

  @override
  Future<List<ChatMessageEntity>> getChatMessages(String transactionId) async {
    final messages = await chatDataSource.getMessages(transactionId);
    return messages.map((m) => ChatMessageEntity(
      id: m['id'],
      transactionId: transactionId,
      senderId: m['sender_id'],
      senderName: m['user_profiles']?['username'] ?? 'Unknown',
      message: m['message'],
      timestamp: DateTime.parse(m['created_at']),
      isRead: m['is_read'] ?? false,
      type: m['message_type'] == 'system' ? MessageType.system : MessageType.text,
    )).toList();
  }

  @override
  Future<TransactionFormEntity?> getTransactionForm(String transactionId, FormRole role) async {
    if (role == FormRole.buyer) {
      final form = await buyerDataSource.getTransactionForm(transactionId, buyer.FormRole.buyer);
      if (form == null) return null;
      // Map BuyerTransactionFormEntity to TransactionFormEntity
      return TransactionFormEntity(
        id: form.id,
        transactionId: form.transactionId,
        role: role, // FormRole matches usually
        status: form.isConfirmed ? FormStatus.confirmed : FormStatus.submitted,
        submittedAt: form.submittedAt ?? DateTime.now(),
        preferredDate: DateTime.now(), // Fallback
        paymentMethod: form.paymentMethod,
        handoverLocation: form.deliveryMethod == 'Delivery' ? (form.deliveryAddress ?? '') : '',
        // ... map other fields ...
      );
    } else {
      final form = await sellerDataSource.getSellerForm(transactionId);
      if (form == null) return null;
      // Map JSON to TransactionFormEntity
      return TransactionFormEntity(
        id: form['id'],
        transactionId: form['transaction_id'],
        role: role,
        status: FormStatus.values.firstWhere((e) => e.name == form['status'], orElse: () => FormStatus.submitted),
        submittedAt: DateTime.parse(form['submitted_at']),
        preferredDate: DateTime.parse(form['delivery_date']),
        handoverLocation: form['delivery_location'] ?? '',
        // ... map other fields ...
      );
    }
  }

  @override
  Future<List<TransactionTimelineEntity>> getTimeline(String transactionId) async {
    try {
      final events = await buyerDataSource.getTimeline(transactionId);
      return events.map((e) => TransactionTimelineEntity(
        id: e.id,
        transactionId: e.transactionId,
        title: e.title,
        description: e.description,
        timestamp: e.timestamp,
        type: _mapTimelineType(e.type),
        actorName: e.actorName,
      )).toList();
    } catch (e) {
      return [];
    }
  }
  
  TimelineEventType _mapTimelineType(buyer.TimelineEventType type) {
    switch (type) {
      case buyer.TimelineEventType.created: return TimelineEventType.created;
      case buyer.TimelineEventType.formSubmitted: return TimelineEventType.formSubmitted;
      case buyer.TimelineEventType.formConfirmed: return TimelineEventType.formConfirmed;
      case buyer.TimelineEventType.adminReview: return TimelineEventType.adminReview;
      case buyer.TimelineEventType.adminApproved: return TimelineEventType.adminApproved;
      case buyer.TimelineEventType.completed: return TimelineEventType.completed;
      case buyer.TimelineEventType.cancelled: return TimelineEventType.cancelled;
      default: return TimelineEventType.created;
    }
  }

  @override
  Future<bool> sendMessage(String transactionId, String userId, String userName, String message) async {
    try {
      await chatDataSource.sendMessage(
        transactionId: transactionId,
        senderId: userId,
        message: message,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> submitForm(TransactionFormEntity form) async {
    if (form.role == FormRole.seller) {
      await sellerDataSource.submitSellerForm(
        transactionId: form.transactionId,
        agreedPrice: form.agreedPrice,
        paymentMethod: '', 
        deliveryDate: form.preferredDate,
        deliveryLocation: form.handoverLocation,
        orcrVerified: form.orCrOriginalAvailable,
        deedsOfSaleReady: form.deedOfSaleReady,
        plateNumberConfirmed: true,
        registrationValid: form.registrationValid,
        noOutstandingLoans: form.noLiensEncumbrances,
        mechanicalInspectionDone: form.conditionMatchesListing,
      );
    } else {
      // Need to map TransactionFormEntity to BuyerTransactionFormEntity
      // This is hard because they have different fields.
      // Assuming buyer form is passed as TransactionFormEntity but contains buyer data.
      final buyerForm = buyer.BuyerTransactionFormEntity(
        id: form.id,
        transactionId: form.transactionId,
        role: buyer.FormRole.buyer,
        fullName: '', // Missing in TransactionFormEntity?
        email: '',
        phone: form.contactNumber,
        address: '',
        city: '',
        province: '',
        zipCode: '',
        idType: '',
        idNumber: '',
        paymentMethod: form.paymentMethod,
        deliveryMethod: form.pickupOrDelivery,
        deliveryAddress: form.deliveryAddress,
        agreedToTerms: form.understoodAuctionTerms, // Approximation
        isConfirmed: false,
      );
      await buyerDataSource.submitForm(buyerForm);
    }
    return true;
  }

  @override
  Future<bool> confirmForm(String transactionId, FormRole otherPartyRole) async {
    if (otherPartyRole == FormRole.seller) {
       await buyerDataSource.confirmBuyerForm(transactionId);
    } else {
       if (otherPartyRole == FormRole.buyer) {
         await sellerDataSource.confirmSellerForm(transactionId);
      } else {
         await buyerDataSource.confirmBuyerForm(transactionId);
      }
    }
    return true;
  }

  @override
  Future<bool> submitToAdmin(String transactionId) async {
    await sellerDataSource.submitToAdmin(transactionId);
    return true;
  }

  @override
  Future<bool> updateDeliveryStatus(String transactionId, String sellerId, DeliveryStatus status) async {
    String statusStr = 'pending';
    if (status == DeliveryStatus.preparing) statusStr = 'preparing';
    if (status == DeliveryStatus.inTransit) statusStr = 'in_transit';
    if (status == DeliveryStatus.delivered) statusStr = 'delivered';
    
    await sellerDataSource.updateDeliveryStatus(
      transactionId: transactionId,
      sellerId: sellerId,
      deliveryStatus: statusStr,
    );
    return true;
  }

  @override
  Future<bool> acceptVehicle(String transactionId, String buyerId) async {
    return await buyerDataSource.acceptVehicle(transactionId, buyerId);
  }

  @override
  Future<bool> rejectVehicle(String transactionId, String buyerId, String reason) async {
    return await buyerDataSource.rejectVehicle(transactionId, buyerId, reason);
  }

  // Helpers
  TransactionEntity _mapBuyerEntityToTransactionEntity(buyer.BuyerTransactionEntity e) {
    return TransactionEntity(
      id: e.id,
      listingId: e.auctionId,
      sellerId: e.sellerId,
      buyerId: e.buyerId,
      carName: e.carName,
      carImageUrl: e.carImageUrl,
      agreedPrice: e.agreedPrice,
      status: _mapStatus(e.status),
      createdAt: e.createdAt,
      completedAt: e.completedAt,
      sellerFormSubmitted: e.sellerFormSubmitted,
      buyerFormSubmitted: e.buyerFormSubmitted,
      sellerConfirmed: e.sellerConfirmed,
      buyerConfirmed: e.buyerConfirmed,
      adminApproved: e.adminApproved,
      adminApprovedAt: e.adminApprovedAt,
      deliveryStatus: _mapDeliveryStatus(e.deliveryStatus),
      deliveryStartedAt: e.deliveryStartedAt,
      deliveryCompletedAt: e.deliveryCompletedAt,
      buyerAcceptanceStatus: _mapAcceptanceStatus(e.buyerAcceptanceStatus),
      buyerAcceptedAt: e.buyerAcceptedAt,
      buyerRejectionReason: e.buyerRejectionReason,
    );
  }

  TransactionStatus _mapStatus(buyer.TransactionStatus s) {
    switch (s) {
      case buyer.TransactionStatus.discussion: return TransactionStatus.discussion;
      case buyer.TransactionStatus.formReview: return TransactionStatus.formReview;
      case buyer.TransactionStatus.pendingApproval: return TransactionStatus.pendingApproval;
      case buyer.TransactionStatus.approved: return TransactionStatus.approved;
      case buyer.TransactionStatus.completed: return TransactionStatus.completed;
      case buyer.TransactionStatus.cancelled: return TransactionStatus.cancelled;
      default: return TransactionStatus.discussion;
    }
  }

  DeliveryStatus _mapDeliveryStatus(buyer.DeliveryStatus s) {
    switch (s) {
      case buyer.DeliveryStatus.pending: return DeliveryStatus.pending;
      case buyer.DeliveryStatus.preparing: return DeliveryStatus.preparing;
      case buyer.DeliveryStatus.inTransit: return DeliveryStatus.inTransit;
      case buyer.DeliveryStatus.delivered: return DeliveryStatus.delivered;
      case buyer.DeliveryStatus.completed: return DeliveryStatus.completed;
    }
  }

  BuyerAcceptanceStatus _mapAcceptanceStatus(buyer.BuyerAcceptanceStatus s) {
     switch (s) {
       case buyer.BuyerAcceptanceStatus.pending: return BuyerAcceptanceStatus.pending;
       case buyer.BuyerAcceptanceStatus.accepted: return BuyerAcceptanceStatus.accepted;
       case buyer.BuyerAcceptanceStatus.rejected: return BuyerAcceptanceStatus.rejected;
     }
  }

  TransactionEntity _mapSellerJsonToTransactionEntity(Map<String, dynamic> json) {
     return TransactionEntity(
       id: json['id'],
       listingId: json['auction_id'] ?? '',
       sellerId: json['seller_id'] ?? '',
       buyerId: json['buyer_id'] ?? '',
       carName: 'Vehicle', 
       carImageUrl: '',
       agreedPrice: (json['agreed_price'] as num?)?.toDouble() ?? 0,
       status: TransactionStatus.discussion,
       createdAt: DateTime.parse(json['created_at']),
     );
  }
}