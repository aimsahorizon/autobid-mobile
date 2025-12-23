import '../../domain/entities/transaction_entity.dart';

/// Mock datasource for transaction-related data
/// TODO: Replace with Supabase implementation
/// - Use supabase.from('transactions') for CRUD operations
/// - Use supabase.from('chat_messages') for real-time chat
/// - Use supabase.from('transaction_forms') for form data
/// - Use supabase.from('transaction_timeline') for timeline events
/// - Implement real-time subscriptions for chat and status updates
class TransactionMockDataSource {
  // Toggle to switch between mock and real backend
  // Set to true for mock data, false when backend is ready
  static const bool useMockData = true;

  // Simulated delay for network requests
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 800));

  /// Get all transactions for a seller
  /// TODO: Implement Supabase query:
  /// await supabase.from('transactions')
  ///   .select()
  ///   .eq('seller_id', sellerId)
  ///   .order('created_at', ascending: false);
  Future<List<TransactionEntity>> getSellerTransactions(String sellerId) async {
    await _delay();
    return _mockTransactions.where((t) => t.sellerId == sellerId).toList();
  }

  /// Get single transaction by ID
  /// TODO: Implement Supabase query:
  /// await supabase.from('transactions')
  ///   .select()
  ///   .eq('id', transactionId)
  ///   .single();
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    await _delay();

    // Try to find existing transaction by ID
    try {
      return _mockTransactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      // If not found, create dynamic transaction for the listing
      // This allows any listing ID to have a transaction (mock fallback)
      return _createDynamicTransaction(transactionId);
    }
  }

  /// Creates a dynamic mock transaction for any listing ID
  /// This ensures UI works even if transaction doesn't exist in mock data
  TransactionEntity _createDynamicTransaction(String listingId) {
    return TransactionEntity(
      id: listingId, // Use listing ID as transaction ID
      listingId: listingId,
      sellerId: 'seller_001',
      buyerId: 'buyer_001',
      carName: '2020 Chevrolet Corvette C8',
      carImageUrl:
          'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
      agreedPrice: 720000,
      status: TransactionStatus.discussion,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      sellerFormSubmitted: false,
      buyerFormSubmitted: false,
    );
  }

  /// Get chat messages for a transaction
  /// TODO: Implement Supabase query with real-time subscription:
  /// await supabase.from('chat_messages')
  ///   .select()
  ///   .eq('transaction_id', transactionId)
  ///   .order('timestamp', ascending: true);
  Future<List<ChatMessageEntity>> getChatMessages(String transactionId) async {
    await _delay();

    final messages = _mockChatMessages
        .where((m) => m.transactionId == transactionId)
        .toList();

    // If no messages exist, create sample messages for any transaction
    if (messages.isEmpty) {
      return _createDynamicChatMessages(transactionId);
    }

    return messages;
  }

  /// Creates sample chat messages for dynamic transactions
  List<ChatMessageEntity> _createDynamicChatMessages(String transactionId) {
    return [
      ChatMessageEntity(
        id: 'msg_${transactionId}_1',
        transactionId: transactionId,
        senderId: 'buyer_001',
        senderName: 'Juan Dela Cruz',
        message: 'Hi! I\'m interested in purchasing your car.',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      ChatMessageEntity(
        id: 'msg_${transactionId}_2',
        transactionId: transactionId,
        senderId: 'seller_001',
        senderName: 'Maria Santos',
        message:
            'Hello! Thank you for your interest. The car is in excellent condition.',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      ),
      ChatMessageEntity(
        id: 'msg_${transactionId}_3',
        transactionId: transactionId,
        senderId: 'buyer_001',
        senderName: 'Juan Dela Cruz',
        message: 'Can we schedule a viewing?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Send a chat message
  /// TODO: Implement Supabase insert:
  /// await supabase.from('chat_messages').insert({
  ///   'transaction_id': transactionId,
  ///   'sender_id': senderId,
  ///   'message': message,
  ///   'timestamp': DateTime.now().toIso8601String(),
  /// });
  Future<bool> sendMessage(
    String transactionId,
    String senderId,
    String senderName,
    String message,
  ) async {
    await _delay();
    final newMessage = ChatMessageEntity(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      transactionId: transactionId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
    );
    _mockChatMessages.add(newMessage);
    return true;
  }

  /// Get transaction form (seller or buyer)
  /// TODO: Implement Supabase query:
  /// await supabase.from('transaction_forms')
  ///   .select()
  ///   .eq('transaction_id', transactionId)
  ///   .eq('role', role.name)
  ///   .maybeSingle();
  Future<TransactionFormEntity?> getTransactionForm(
    String transactionId,
    FormRole role,
  ) async {
    await _delay();
    try {
      return _mockForms.firstWhere(
        (f) => f.transactionId == transactionId && f.role == role,
      );
    } catch (e) {
      return null;
    }
  }

  /// Submit or update transaction form
  /// TODO: Implement Supabase upsert:
  /// await supabase.from('transaction_forms').upsert(formData);
  Future<bool> submitForm(TransactionFormEntity form) async {
    await _delay();
    final index = _mockForms.indexWhere(
      (f) => f.transactionId == form.transactionId && f.role == form.role,
    );
    if (index >= 0) {
      _mockForms[index] = form;
    } else {
      _mockForms.add(form);
    }
    return true;
  }

  /// Confirm a form (seller confirms buyer form or vice versa)
  /// TODO: Implement Supabase update:
  /// await supabase.from('transactions').update({
  ///   'seller_confirmed': true / 'buyer_confirmed': true
  /// }).eq('id', transactionId);
  Future<bool> confirmForm(String transactionId, FormRole role) async {
    await _delay();
    final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
    if (index >= 0) {
      final transaction = _mockTransactions[index];
      _mockTransactions[index] = TransactionEntity(
        id: transaction.id,
        listingId: transaction.listingId,
        sellerId: transaction.sellerId,
        buyerId: transaction.buyerId,
        carName: transaction.carName,
        carImageUrl: transaction.carImageUrl,
        agreedPrice: transaction.agreedPrice,
        status: transaction.status,
        createdAt: transaction.createdAt,
        completedAt: transaction.completedAt,
        sellerFormSubmitted: transaction.sellerFormSubmitted,
        buyerFormSubmitted: transaction.buyerFormSubmitted,
        sellerConfirmed: role == FormRole.buyer
            ? true
            : transaction.sellerConfirmed,
        buyerConfirmed: role == FormRole.seller
            ? true
            : transaction.buyerConfirmed,
        adminApproved: transaction.adminApproved,
        adminApprovedAt: transaction.adminApprovedAt,
      );
      return true;
    }
    return false;
  }

  /// Get transaction timeline events
  /// TODO: Implement Supabase query:
  /// await supabase.from('transaction_timeline')
  ///   .select()
  ///   .eq('transaction_id', transactionId)
  ///   .order('timestamp', ascending: false);
  Future<List<TransactionTimelineEntity>> getTimeline(
    String transactionId,
  ) async {
    await _delay();

    final timeline = _mockTimeline
        .where((t) => t.transactionId == transactionId)
        .toList();

    // If no timeline exists, create sample timeline for any transaction
    if (timeline.isEmpty) {
      return _createDynamicTimeline(transactionId);
    }

    return timeline;
  }

  /// Creates sample timeline for dynamic transactions
  List<TransactionTimelineEntity> _createDynamicTimeline(String transactionId) {
    return [
      TransactionTimelineEntity(
        id: 'timeline_${transactionId}_1',
        transactionId: transactionId,
        title: 'Transaction Started',
        description: 'Pre-transaction discussion phase initiated',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: TimelineEventType.created,
        actorName: 'System',
      ),
      TransactionTimelineEntity(
        id: 'timeline_${transactionId}_2',
        transactionId: transactionId,
        title: 'First Contact',
        description: 'Buyer sent initial inquiry',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
        type: TimelineEventType.created,
        actorName: 'Juan Dela Cruz',
      ),
    ];
  }

  /// Submit transaction to admin for approval
  /// TODO: Implement Supabase update + notification:
  /// await supabase.from('transactions').update({
  ///   'status': 'pendingApproval'
  /// }).eq('id', transactionId);
  Future<bool> submitToAdmin(String transactionId) async {
    await _delay();
    final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
    if (index >= 0) {
      final transaction = _mockTransactions[index];
      _mockTransactions[index] = TransactionEntity(
        id: transaction.id,
        listingId: transaction.listingId,
        sellerId: transaction.sellerId,
        buyerId: transaction.buyerId,
        carName: transaction.carName,
        carImageUrl: transaction.carImageUrl,
        agreedPrice: transaction.agreedPrice,
        status: TransactionStatus.pendingApproval,
        createdAt: transaction.createdAt,
        sellerFormSubmitted: transaction.sellerFormSubmitted,
        buyerFormSubmitted: transaction.buyerFormSubmitted,
        sellerConfirmed: transaction.sellerConfirmed,
        buyerConfirmed: transaction.buyerConfirmed,
        adminApproved: transaction.adminApproved,
        deliveryStatus: transaction.deliveryStatus,
      );
      return true;
    }
    return false;
  }

  /// Simulate admin approval (for demo purposes)
  /// TODO: In production, this would be an admin-only operation
  Future<bool> simulateAdminApproval(String transactionId) async {
    await _delay();
    final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
    if (index >= 0) {
      final transaction = _mockTransactions[index];
      final now = DateTime.now();

      _mockTransactions[index] = TransactionEntity(
        id: transaction.id,
        listingId: transaction.listingId,
        sellerId: transaction.sellerId,
        buyerId: transaction.buyerId,
        carName: transaction.carName,
        carImageUrl: transaction.carImageUrl,
        agreedPrice: transaction.agreedPrice,
        status: TransactionStatus.approved,
        createdAt: transaction.createdAt,
        sellerFormSubmitted: transaction.sellerFormSubmitted,
        buyerFormSubmitted: transaction.buyerFormSubmitted,
        sellerConfirmed: transaction.sellerConfirmed,
        buyerConfirmed: transaction.buyerConfirmed,
        adminApproved: true,
        adminApprovedAt: now,
        deliveryStatus: transaction.deliveryStatus,
      );

      // Add timeline event
      _mockTimeline.add(
        TransactionTimelineEntity(
          id: 'timeline_${transactionId}_${now.millisecondsSinceEpoch}',
          transactionId: transactionId,
          title: 'Admin Approved',
          description:
              'Transaction approved by admin - deposit will be refunded',
          timestamp: now,
          type: TimelineEventType.adminApproved,
          actorName: 'Admin',
        ),
      );

      return true;
    }
    return false;
  }

  /// Update delivery status (seller manages)
  /// TODO: Implement Supabase update:
  /// await supabase.from('transactions').update({
  ///   'delivery_status': status.name,
  ///   'delivery_started_at': deliveryStartedAt?.toIso8601String(),
  ///   'delivery_completed_at': deliveryCompletedAt?.toIso8601String(),
  /// }).eq('id', transactionId);
  Future<bool> updateDeliveryStatus(
    String transactionId,
    String sellerId,
    DeliveryStatus status,
  ) async {
    await _delay();
    final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
    if (index >= 0) {
      final transaction = _mockTransactions[index];
      final now = DateTime.now();

      _mockTransactions[index] = TransactionEntity(
        id: transaction.id,
        listingId: transaction.listingId,
        sellerId: transaction.sellerId,
        buyerId: transaction.buyerId,
        carName: transaction.carName,
        carImageUrl: transaction.carImageUrl,
        agreedPrice: transaction.agreedPrice,
        status: status == DeliveryStatus.completed
            ? TransactionStatus.completed
            : transaction.status,
        createdAt: transaction.createdAt,
        completedAt: status == DeliveryStatus.completed
            ? now
            : transaction.completedAt,
        sellerFormSubmitted: transaction.sellerFormSubmitted,
        buyerFormSubmitted: transaction.buyerFormSubmitted,
        sellerConfirmed: transaction.sellerConfirmed,
        buyerConfirmed: transaction.buyerConfirmed,
        adminApproved: transaction.adminApproved,
        adminApprovedAt: transaction.adminApprovedAt,
        deliveryStatus: status,
        deliveryStartedAt: status != DeliveryStatus.pending
            ? (transaction.deliveryStartedAt ?? now)
            : null,
        deliveryCompletedAt: status == DeliveryStatus.completed ? now : null,
      );

      // Add timeline event
      _mockTimeline.add(
        TransactionTimelineEntity(
          id: 'timeline_${transactionId}_${now.millisecondsSinceEpoch}',
          transactionId: transactionId,
          title: _getDeliveryStatusTitle(status),
          description: _getDeliveryStatusDescription(status),
          timestamp: now,
          type: status == DeliveryStatus.completed
              ? TimelineEventType.completed
              : TimelineEventType.transactionStarted,
          actorName: 'Seller',
        ),
      );

      return true;
    }
    return false;
  }

  String _getDeliveryStatusTitle(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Delivery Pending';
      case DeliveryStatus.preparing:
        return 'Preparing Vehicle';
      case DeliveryStatus.inTransit:
        return 'Vehicle In Transit';
      case DeliveryStatus.delivered:
        return 'Vehicle Delivered';
      case DeliveryStatus.completed:
        return 'Transaction Completed';
    }
  }

  String _getDeliveryStatusDescription(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.pending:
        return 'Awaiting delivery preparation';
      case DeliveryStatus.preparing:
        return 'Seller is preparing the vehicle for handover';
      case DeliveryStatus.inTransit:
        return 'Vehicle is being transported to buyer';
      case DeliveryStatus.delivered:
        return 'Vehicle has been delivered to buyer - awaiting buyer confirmation';
      case DeliveryStatus.completed:
        return 'Buyer confirmed receipt - transaction complete';
    }
  }

  /// Buyer accepts the vehicle - transaction successful
  /// TODO: Implement Supabase RPC call:
  /// await supabase.rpc('handle_buyer_acceptance', params: {
  ///   'p_transaction_id': transactionId,
  ///   'p_buyer_id': buyerId,
  ///   'p_accepted': true,
  /// });
  Future<bool> acceptVehicle(String transactionId, String buyerId) async {
    await _delay();
    final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
    if (index >= 0) {
      final transaction = _mockTransactions[index];
      final now = DateTime.now();

      // Verify it's the buyer and vehicle is delivered
      if (transaction.buyerId != buyerId) return false;
      if (transaction.deliveryStatus != DeliveryStatus.delivered) return false;

      _mockTransactions[index] = transaction.copyWith(
        buyerAcceptanceStatus: BuyerAcceptanceStatus.accepted,
        buyerAcceptedAt: now,
        deliveryStatus: DeliveryStatus.completed,
        deliveryCompletedAt: now,
        status: TransactionStatus.completed,
        completedAt: now,
      );

      // Add timeline event
      _mockTimeline.add(
        TransactionTimelineEntity(
          id: 'timeline_${transactionId}_${now.millisecondsSinceEpoch}',
          transactionId: transactionId,
          title: 'Vehicle Accepted',
          description:
              'Buyer confirmed receipt and accepted the vehicle - Transaction successful!',
          timestamp: now,
          type: TimelineEventType.completed,
          actorName: 'Buyer',
        ),
      );

      return true;
    }
    return false;
  }

  /// Buyer rejects the vehicle - deal failed
  /// TODO: Implement Supabase RPC call:
  /// await supabase.rpc('handle_buyer_acceptance', params: {
  ///   'p_transaction_id': transactionId,
  ///   'p_buyer_id': buyerId,
  ///   'p_accepted': false,
  ///   'p_rejection_reason': reason,
  /// });
  Future<bool> rejectVehicle(
    String transactionId,
    String buyerId,
    String reason,
  ) async {
    await _delay();
    final index = _mockTransactions.indexWhere((t) => t.id == transactionId);
    if (index >= 0) {
      final transaction = _mockTransactions[index];
      final now = DateTime.now();

      // Verify it's the buyer and vehicle is delivered
      if (transaction.buyerId != buyerId) return false;
      if (transaction.deliveryStatus != DeliveryStatus.delivered) return false;

      _mockTransactions[index] = transaction.copyWith(
        buyerAcceptanceStatus: BuyerAcceptanceStatus.rejected,
        buyerAcceptedAt: now,
        buyerRejectionReason: reason,
        status: TransactionStatus.cancelled,
        completedAt: now,
      );

      // Add timeline event
      _mockTimeline.add(
        TransactionTimelineEntity(
          id: 'timeline_${transactionId}_${now.millisecondsSinceEpoch}',
          transactionId: transactionId,
          title: 'Vehicle Rejected',
          description: 'Buyer rejected the vehicle. Reason: $reason',
          timestamp: now,
          type: TimelineEventType.cancelled,
          actorName: 'Buyer',
        ),
      );

      return true;
    }
    return false;
  }

  // Mock data storage
  static final List<TransactionEntity> _mockTransactions = [
    TransactionEntity(
      id: 'txn_001',
      listingId: 'listing_001',
      sellerId: 'seller_001',
      buyerId: 'buyer_001',
      carName: '2020 Toyota Corolla Altis',
      carImageUrl: 'https://picsum.photos/seed/car1/400/300',
      agreedPrice: 850000,
      status: TransactionStatus.discussion,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      sellerFormSubmitted: false,
      buyerFormSubmitted: false,
    ),
    TransactionEntity(
      id: 'txn_002',
      listingId: 'listing_002',
      sellerId: 'seller_001',
      buyerId: 'buyer_002',
      carName: '2019 Honda Civic RS',
      carImageUrl: 'https://picsum.photos/seed/car2/400/300',
      agreedPrice: 950000,
      status: TransactionStatus.formReview,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      sellerFormSubmitted: true,
      buyerFormSubmitted: true,
    ),
  ];

  static final List<ChatMessageEntity> _mockChatMessages = [
    ChatMessageEntity(
      id: 'msg_001',
      transactionId: 'txn_001',
      senderId: 'buyer_001',
      senderName: 'Juan Dela Cruz',
      message: 'Hi! I\'m interested in purchasing your car.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    ChatMessageEntity(
      id: 'msg_002',
      transactionId: 'txn_001',
      senderId: 'seller_001',
      senderName: 'Maria Santos',
      message:
          'Hello! Thank you for your interest. The car is in excellent condition.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
    ),
    ChatMessageEntity(
      id: 'msg_003',
      transactionId: 'txn_001',
      senderId: 'buyer_001',
      senderName: 'Juan Dela Cruz',
      message: 'Can we discuss the payment terms?',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static final List<TransactionFormEntity> _mockForms = [];

  static final List<TransactionTimelineEntity> _mockTimeline = [
    TransactionTimelineEntity(
      id: 'timeline_001',
      transactionId: 'txn_001',
      title: 'Transaction Started',
      description: 'Pre-transaction discussion phase initiated',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: TimelineEventType.created,
      actorName: 'System',
    ),
  ];
}
