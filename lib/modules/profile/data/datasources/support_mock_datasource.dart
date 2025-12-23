import '../../domain/entities/support_ticket_entity.dart';

/// Mock data source for customer support
/// Provides sample tickets and FAQ data
/// TODO: Replace with Supabase implementation:
/// - Create 'support_tickets' table with user_id foreign key
/// - Create 'support_messages' table with ticket_id foreign key
/// - Use Supabase realtime for live chat updates
class SupportMockDataSource {
  /// Fetch all tickets for current user
  /// TODO: Implement with Supabase:
  /// final response = await supabase
  ///   .from('support_tickets')
  ///   .select('*, messages:support_messages(*)')
  ///   .eq('user_id', userId)
  ///   .order('updated_at', ascending: false);
  Future<List<SupportTicketEntity>> getTickets() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final now = DateTime.now();

    return [
      SupportTicketEntity(
        id: 'ticket_001',
        userId: 'user_mock',
        categoryId: 'cat_payment',
        categoryName: 'Payment Issues',
        subject: 'Issue with payment processing',
        description: 'I tried to deposit for an auction but the payment failed.',
        status: TicketStatus.inProgress,
        priority: TicketPriority.high,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 3)),
        messages: [
          SupportMessageEntity(
            id: 'msg_001',
            ticketId: 'ticket_001',
            userId: 'user_mock',
            message: 'I tried to deposit for an auction but the payment failed. My GCash was debited but the deposit is not reflecting.',
            isInternal: false,
            senderName: 'You',
            createdAt: now.subtract(const Duration(days: 2)),
            updatedAt: now.subtract(const Duration(days: 2)),
          ),
          SupportMessageEntity(
            id: 'msg_002',
            ticketId: 'ticket_001',
            userId: 'support_maria',
            message: 'Hi! Thank you for reaching out. I apologize for the inconvenience. Could you please provide your GCash reference number so we can investigate?',
            isInternal: true,
            senderName: 'Support Agent Maria',
            createdAt: now.subtract(const Duration(days: 1, hours: 20)),
            updatedAt: now.subtract(const Duration(days: 1, hours: 20)),
          ),
          SupportMessageEntity(
            id: 'msg_003',
            ticketId: 'ticket_001',
            userId: 'user_mock',
            message: 'Sure, the reference number is GC1234567890. The amount was ₱10,000.',
            isInternal: false,
            senderName: 'You',
            createdAt: now.subtract(const Duration(days: 1, hours: 18)),
            updatedAt: now.subtract(const Duration(days: 1, hours: 18)),
          ),
          SupportMessageEntity(
            id: 'msg_004',
            ticketId: 'ticket_001',
            userId: 'support_maria',
            message: 'Thank you for providing the details. I have escalated this to our finance team. We will process the refund or credit within 24-48 hours. I will update you once resolved.',
            isInternal: true,
            senderName: 'Support Agent Maria',
            createdAt: now.subtract(const Duration(hours: 3)),
            updatedAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      SupportTicketEntity(
        id: 'ticket_002',
        userId: 'user_mock',
        categoryId: 'cat_listing',
        categoryName: 'Listing Problems',
        subject: 'How to edit my listing?',
        description: 'I want to update the photos on my car listing.',
        status: TicketStatus.resolved,
        priority: TicketPriority.low,
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 5)),
        resolvedAt: now.subtract(const Duration(days: 5)),
        messages: [
          SupportMessageEntity(
            id: 'msg_005',
            ticketId: 'ticket_002',
            userId: 'user_mock',
            message: 'I want to update the photos on my car listing. How do I do that?',
            isInternal: false,
            senderName: 'You',
            createdAt: now.subtract(const Duration(days: 7)),
            updatedAt: now.subtract(const Duration(days: 7)),
          ),
          SupportMessageEntity(
            id: 'msg_006',
            ticketId: 'ticket_002',
            userId: 'support_carlos',
            message: 'Hi! To edit your listing, go to My Listings > tap the listing > Edit button on top right. You can then update photos and details. Note: If the auction is already active, some fields may be locked.',
            isInternal: true,
            senderName: 'Support Agent Carlos',
            createdAt: now.subtract(const Duration(days: 6)),
            updatedAt: now.subtract(const Duration(days: 6)),
          ),
        ],
      ),
    ];
  }

  /// Create a new support ticket
  /// TODO: Implement with Supabase:
  /// final response = await supabase
  ///   .from('support_tickets')
  ///   .insert({
  ///     'user_id': userId,
  ///     'subject': subject,
  ///     'category': category,
  ///     'status': 'open',
  ///     'priority': priority,
  ///   })
  ///   .select()
  ///   .single();
  Future<SupportTicketEntity> createTicket({
    required String subject,
    required String categoryId,
    required String categoryName,
    required String description,
    TicketPriority priority = TicketPriority.medium,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final now = DateTime.now();
    final ticketId = 'ticket_new_${now.millisecondsSinceEpoch}';

    return SupportTicketEntity(
      id: ticketId,
      userId: 'user_mock',
      categoryId: categoryId,
      categoryName: categoryName,
      subject: subject,
      description: description,
      status: TicketStatus.open,
      priority: priority,
      createdAt: now,
      updatedAt: now,
      messages: [
        SupportMessageEntity(
          id: 'msg_new',
          ticketId: ticketId,
          userId: 'user_mock',
          message: description,
          isInternal: false,
          senderName: 'You',
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  /// Send a message to an existing ticket
  /// TODO: Implement with Supabase:
  /// await supabase.from('support_messages').insert({
  ///   'ticket_id': ticketId,
  ///   'message': message,
  ///   'is_from_support': false,
  ///   'sender_name': userName,
  /// });
  Future<bool> sendMessage(String ticketId, String message) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return true;
  }

  /// Get FAQ items
  Future<List<Map<String, String>>> getFAQs() async {
    await Future.delayed(const Duration(milliseconds: 300));

    return [
      {
        'question': 'How do I place a bid?',
        'answer': 'To place a bid, first deposit the required amount on the auction page. Once deposited, you can enter your bid amount and confirm.',
      },
      {
        'question': 'What happens if I win an auction?',
        'answer': 'If you win, you will be notified and connected with the seller. You have 48 hours to complete the transaction. Your deposit will be applied to the purchase.',
      },
      {
        'question': 'How do I get my deposit back?',
        'answer': 'If you don\'t win the auction, your deposit is automatically refunded within 24-48 hours after the auction ends.',
      },
      {
        'question': 'How do I list my car for auction?',
        'answer': 'Go to My Listings > tap the + button > fill in your car details > submit for review. Our team will review and approve within 24 hours.',
      },
      {
        'question': 'What fees does AutoBid charge?',
        'answer': 'Buyers pay no fees. Sellers pay a 3% success fee only when their car sells. There are no listing fees.',
      },
    ];
  }
}
