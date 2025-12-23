import '../entities/support_ticket_entity.dart';

abstract class SupportRepository {
  /// Get all support categories
  Future<List<SupportCategoryEntity>> getCategories();

  /// Get all tickets for the current user
  Future<List<SupportTicketEntity>> getUserTickets({
    TicketStatus? status,
    int? limit,
    int? offset,
  });

  /// Get a specific ticket by ID with all messages
  Future<SupportTicketEntity> getTicketById(String ticketId);

  /// Create a new support ticket
  Future<SupportTicketEntity> createTicket({
    required String categoryId,
    required String subject,
    required String description,
    required TicketPriority priority,
  });

  /// Add a message to an existing ticket
  Future<SupportMessageEntity> addMessage({
    required String ticketId,
    required String message,
    List<String>? attachmentPaths,
  });

  /// Update ticket status
  Future<SupportTicketEntity> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  });

  /// Update ticket priority
  Future<SupportTicketEntity> updateTicketPriority({
    required String ticketId,
    required TicketPriority priority,
  });

  /// Close a ticket
  Future<SupportTicketEntity> closeTicket(String ticketId);

  /// Reopen a closed ticket
  Future<SupportTicketEntity> reopenTicket(String ticketId);

  /// Get ticket statistics for the current user
  Future<Map<String, int>> getUserTicketStats();

  /// Upload an attachment
  Future<SupportAttachmentEntity> uploadAttachment({
    required String ticketId,
    required String filePath,
    String? messageId,
  });

  /// Delete an attachment
  Future<void> deleteAttachment(String attachmentId);
}
