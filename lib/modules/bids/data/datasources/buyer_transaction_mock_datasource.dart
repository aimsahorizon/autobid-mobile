import '../../domain/entities/buyer_transaction_entity.dart';

/// Mock datasource for buyer's won auction transactions
/// Provides transaction data, forms, chat, and timeline from buyer perspective
///
/// TODO: Replace with Supabase implementation
/// - Query: transactions table WHERE buyer_id = current_user
/// - Join: transaction_forms, chat_messages, timeline_events
/// - Real-time: Subscribe to chat and status updates
class BuyerTransactionMockDataSource {
  // Toggle to switch between mock and real backend
  // Set to true for mock data, false when backend is ready
  static const bool useMockData = true;

  // Simulated network delay
  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 800));

  /// Get transaction by ID (buyer perspective)
  Future<BuyerTransactionEntity?> getTransaction(String transactionId) async {
    await _delay();

    try {
      return _mockTransactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      // Create dynamic transaction for won auction
      return _createDynamicTransaction(transactionId);
    }
  }

  /// Creates dynamic transaction for any auction/transaction ID
  BuyerTransactionEntity _createDynamicTransaction(String transactionId) {
    return BuyerTransactionEntity(
      id: transactionId,
      auctionId: transactionId,
      sellerId: 'seller_001',
      buyerId: 'buyer_current',
      carName: '2020 Chevrolet Corvette C8',
      carImageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
      agreedPrice: 720000,
      depositPaid: 72000,
      status: TransactionStatus.discussion,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      buyerFormSubmitted: false,
      sellerFormSubmitted: false,
      buyerConfirmed: false,
      sellerConfirmed: false,
      adminApproved: false,
    );
  }

  /// Get chat messages for transaction
  Future<List<TransactionChatMessage>> getChatMessages(String transactionId) async {
    await _delay();

    final messages = _mockChatMessages
        .where((m) => m.transactionId == transactionId)
        .toList();

    if (messages.isEmpty) {
      return _createDynamicChatMessages(transactionId);
    }

    return messages;
  }

  /// Creates sample chat messages
  List<TransactionChatMessage> _createDynamicChatMessages(String transactionId) {
    return [
      TransactionChatMessage(
        id: 'msg_${transactionId}_1',
        transactionId: transactionId,
        senderId: 'buyer_current',
        senderName: 'You',
        message: 'Hi! I won the auction. Looking forward to completing the transaction.',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
      ),
      TransactionChatMessage(
        id: 'msg_${transactionId}_2',
        transactionId: transactionId,
        senderId: 'seller_001',
        senderName: 'John Seller',
        message: 'Congratulations! Let\'s proceed with the documentation.',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
      ),
      TransactionChatMessage(
        id: 'msg_${transactionId}_3',
        transactionId: transactionId,
        senderId: 'buyer_current',
        senderName: 'You',
        message: 'When can we schedule the inspection?',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  /// Send chat message
  Future<bool> sendMessage(
    String transactionId,
    String senderId,
    String senderName,
    String message,
  ) async {
    await _delay();

    final newMessage = TransactionChatMessage(
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

  /// Get transaction form (buyer or seller)
  Future<BuyerTransactionFormEntity?> getTransactionForm(
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

  /// Submit transaction form
  Future<bool> submitForm(BuyerTransactionFormEntity form) async {
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

  /// Get timeline events
  Future<List<TransactionTimelineEvent>> getTimeline(String transactionId) async {
    await _delay();

    final timeline = _mockTimeline
        .where((t) => t.transactionId == transactionId)
        .toList();

    if (timeline.isEmpty) {
      return _createDynamicTimeline(transactionId);
    }

    return timeline;
  }

  /// Creates sample timeline
  List<TransactionTimelineEvent> _createDynamicTimeline(String transactionId) {
    return [
      TransactionTimelineEvent(
        id: 'timeline_${transactionId}_1',
        transactionId: transactionId,
        title: 'Auction Won',
        description: 'You won the auction with the highest bid',
        timestamp: DateTime.now().subtract(const Duration(days: 2)),
        type: TimelineEventType.created,
        actorName: 'System',
      ),
      TransactionTimelineEvent(
        id: 'timeline_${transactionId}_2',
        transactionId: transactionId,
        title: 'Transaction Started',
        description: 'Pre-transaction discussion initiated',
        timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
        type: TimelineEventType.created,
        actorName: 'System',
      ),
    ];
  }

  // Mock data storage
  static final List<BuyerTransactionEntity> _mockTransactions = [
    BuyerTransactionEntity(
      id: 'auction_004',
      auctionId: 'auction_004',
      sellerId: 'seller_001',
      buyerId: 'buyer_current',
      carName: '2020 Chevrolet Corvette C8',
      carImageUrl: 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=800',
      agreedPrice: 720000,
      depositPaid: 72000,
      status: TransactionStatus.discussion,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      buyerFormSubmitted: false,
      sellerFormSubmitted: false,
      buyerConfirmed: false,
      sellerConfirmed: false,
      adminApproved: false,
    ),
  ];

  static final List<TransactionChatMessage> _mockChatMessages = [
    TransactionChatMessage(
      id: 'msg_004_1',
      transactionId: 'auction_004',
      senderId: 'buyer_current',
      senderName: 'You',
      message: 'Hi! I won the auction. Looking forward to completing the transaction.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    TransactionChatMessage(
      id: 'msg_004_2',
      transactionId: 'auction_004',
      senderId: 'seller_001',
      senderName: 'John Seller',
      message: 'Congratulations! Let\'s proceed with the documentation.',
      timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 2)),
    ),
  ];

  static final List<BuyerTransactionFormEntity> _mockForms = [];

  static final List<TransactionTimelineEvent> _mockTimeline = [
    TransactionTimelineEvent(
      id: 'timeline_004_1',
      transactionId: 'auction_004',
      title: 'Auction Won',
      description: 'You won the auction with the highest bid',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: TimelineEventType.created,
      actorName: 'System',
    ),
  ];
}
