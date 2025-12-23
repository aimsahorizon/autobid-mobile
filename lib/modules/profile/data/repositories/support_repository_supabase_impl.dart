import '../../domain/entities/support_ticket_entity.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/support_supabase_datasource.dart';

class SupportRepositorySupabaseImpl implements SupportRepository {
  final SupportSupabaseDatasource datasource;

  SupportRepositorySupabaseImpl(this.datasource);

  @override
  Future<List<SupportCategoryEntity>> getCategories() async {
    try {
      return await datasource.getCategories();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  @override
  Future<List<SupportTicketEntity>> getUserTickets({
    TicketStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      return await datasource.getUserTickets(
        status: status,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      throw Exception('Failed to get user tickets: $e');
    }
  }

  @override
  Future<SupportTicketEntity> getTicketById(String ticketId) async {
    try {
      return await datasource.getTicketById(ticketId);
    } catch (e) {
      throw Exception('Failed to get ticket: $e');
    }
  }

  @override
  Future<SupportTicketEntity> createTicket({
    required String categoryId,
    required String subject,
    required String description,
    required TicketPriority priority,
  }) async {
    try {
      return await datasource.createTicket(
        categoryId: categoryId,
        subject: subject,
        description: description,
        priority: priority,
      );
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  @override
  Future<SupportMessageEntity> addMessage({
    required String ticketId,
    required String message,
    List<String>? attachmentPaths,
  }) async {
    try {
      return await datasource.addMessage(
        ticketId: ticketId,
        message: message,
        attachmentPaths: attachmentPaths,
      );
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  @override
  Future<SupportTicketEntity> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    try {
      return await datasource.updateTicketStatus(
        ticketId: ticketId,
        status: status,
      );
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  @override
  Future<SupportTicketEntity> updateTicketPriority({
    required String ticketId,
    required TicketPriority priority,
  }) async {
    try {
      return await datasource.updateTicketPriority(
        ticketId: ticketId,
        priority: priority,
      );
    } catch (e) {
      throw Exception('Failed to update ticket priority: $e');
    }
  }

  @override
  Future<SupportTicketEntity> closeTicket(String ticketId) async {
    try {
      return await datasource.closeTicket(ticketId);
    } catch (e) {
      throw Exception('Failed to close ticket: $e');
    }
  }

  @override
  Future<SupportTicketEntity> reopenTicket(String ticketId) async {
    try {
      return await datasource.reopenTicket(ticketId);
    } catch (e) {
      throw Exception('Failed to reopen ticket: $e');
    }
  }

  @override
  Future<Map<String, int>> getUserTicketStats() async {
    try {
      return await datasource.getUserTicketStats();
    } catch (e) {
      throw Exception('Failed to get ticket stats: $e');
    }
  }

  @override
  Future<SupportAttachmentEntity> uploadAttachment({
    required String ticketId,
    required String filePath,
    String? messageId,
  }) async {
    try {
      return await datasource.uploadAttachment(
        ticketId: ticketId,
        filePath: filePath,
        messageId: messageId,
      );
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  @override
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      return await datasource.deleteAttachment(attachmentId);
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }
}
