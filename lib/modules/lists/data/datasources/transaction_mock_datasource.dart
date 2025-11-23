import '../../domain/entities/transaction_entity.dart';

/// Mock datasource for transaction-related data
/// TODO: Replace with Supabase implementation
/// - Use supabase.from('transactions') for CRUD operations
/// - Use supabase.from('chat_messages') for real-time chat
/// - Use supabase.from('transaction_forms') for form data
/// - Use supabase.from('transaction_timeline') for timeline events
/// - Implement real-time subscriptions for chat and status updates
class TransactionMockDataSource {
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
    try {
      return _mockTransactions.firstWhere((t) => t.id == transactionId);
    } catch (e) {
      return null;
    }
  }

  /// Get chat messages for a transaction
  /// TODO: Implement Supabase query with real-time subscription:
  /// await supabase.from('chat_messages')
  ///   .select()
  ///   .eq('transaction_id', transactionId)
  ///   .order('timestamp', ascending: true);
  Future<List<ChatMessageEntity>> getChatMessages(String transactionId) async {
    await _delay();
    return _mockChatMessages
        .where((m) => m.transactionId == transactionId)
        .toList();
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
        sellerConfirmed: role == FormRole.buyer ? true : transaction.sellerConfirmed,
        buyerConfirmed: role == FormRole.seller ? true : transaction.buyerConfirmed,
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
  Future<List<TransactionTimelineEntity>> getTimeline(String transactionId) async {
    await _delay();
    return _mockTimeline
        .where((t) => t.transactionId == transactionId)
        .toList();
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
      message: 'Hello! Thank you for your interest. The car is in excellent condition.',
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
