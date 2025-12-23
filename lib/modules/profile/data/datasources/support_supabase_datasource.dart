import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_ticket_model.dart';
import '../../domain/entities/support_ticket_entity.dart';
import 'dart:io';

class SupportSupabaseDatasource {
  final SupabaseClient supabase;

  SupportSupabaseDatasource(this.supabase);

  /// Get all active support categories
  Future<List<SupportCategoryModel>> getCategories() async {
    try {
      final response = await supabase
          .from('support_categories')
          .select()
          .eq('is_active', true)
          .order('name');

      return (response as List)
          .map((json) => SupportCategoryModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch support categories: $e');
    }
  }

  /// Get tickets for the current user
  Future<List<SupportTicketModel>> getUserTickets({
    TicketStatus? status,
    int? limit,
    int? offset,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      var queryBuilder = supabase
          .from('support_tickets')
          .select('*, support_categories!inner(name)')
          .eq('user_id', userId);

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.toJson());
      }

      // Apply ordering and pagination
      var query = queryBuilder.order('created_at', ascending: false);

      if (offset != null && limit != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;

      return (response as List).map((json) {
        // Add category name from the joined table
        final categoryName = json['support_categories']['name'] as String;
        final ticketJson = Map<String, dynamic>.from(json);
        ticketJson['category_name'] = categoryName;
        ticketJson.remove('support_categories');

        return SupportTicketModel.fromJson(ticketJson);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user tickets: $e');
    }
  }

  /// Get a specific ticket by ID with all messages
  Future<SupportTicketModel> getTicketById(String ticketId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Fetch ticket with category name
      final ticketResponse = await supabase
          .from('support_tickets')
          .select('''
            *,
            support_categories!inner(name)
          ''')
          .eq('id', ticketId)
          .single();

      // Fetch messages for this ticket
      final messagesResponse = await supabase
          .from('support_ticket_messages')
          .select('''
            *,
            user_profiles!inner(full_name)
          ''')
          .eq('ticket_id', ticketId)
          .order('created_at', ascending: true);

      // Fetch attachments for messages
      final messageIds = (messagesResponse as List)
          .map((m) => m['id'] as String)
          .toList();

      List<dynamic> attachmentsResponse = [];
      if (messageIds.isNotEmpty) {
        attachmentsResponse = await supabase
            .from('support_ticket_attachments')
            .select()
            .inFilter('message_id', messageIds);
      }

      // Build messages with attachments
      final messages = messagesResponse.map((msgJson) {
        final messageId = msgJson['id'] as String;
        final messageAttachments = (attachmentsResponse as List)
            .where((a) => a['message_id'] == messageId)
            .map((a) => SupportAttachmentModel.fromJson(a))
            .toList();

        final senderName = msgJson['user_profiles']['full_name'] as String? ?? 'Unknown';
        final messageMap = Map<String, dynamic>.from(msgJson);
        messageMap['sender_name'] = senderName;
        messageMap['attachments'] = messageAttachments.map((a) => a.toJson()).toList();
        messageMap.remove('user_profiles');

        return SupportMessageModel.fromJson(messageMap);
      }).toList();

      // Build ticket
      final categoryName = ticketResponse['support_categories']['name'] as String;
      final ticketMap = Map<String, dynamic>.from(ticketResponse);
      ticketMap['category_name'] = categoryName;
      ticketMap['messages'] = messages.map((m) => m.toJson()).toList();
      ticketMap.remove('support_categories');

      return SupportTicketModel.fromJson(ticketMap);
    } catch (e) {
      throw Exception('Failed to fetch ticket details: $e');
    }
  }

  /// Create a new support ticket
  Future<SupportTicketModel> createTicket({
    required String categoryId,
    required String subject,
    required String description,
    required TicketPriority priority,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('support_tickets')
          .insert({
            'user_id': userId,
            'category_id': categoryId,
            'subject': subject,
            'description': description,
            'priority': priority.toJson(),
            'status': 'open',
          })
          .select('''
            *,
            support_categories!inner(name)
          ''')
          .single();

      final categoryName = response['support_categories']['name'] as String;
      final ticketMap = Map<String, dynamic>.from(response);
      ticketMap['category_name'] = categoryName;
      ticketMap.remove('support_categories');

      return SupportTicketModel.fromJson(ticketMap);
    } catch (e) {
      throw Exception('Failed to create ticket: $e');
    }
  }

  /// Add a message to a ticket
  Future<SupportMessageModel> addMessage({
    required String ticketId,
    required String message,
    List<String>? attachmentPaths,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Insert message
      final messageResponse = await supabase
          .from('support_ticket_messages')
          .insert({
            'ticket_id': ticketId,
            'user_id': userId,
            'message': message,
            'is_internal': false,
          })
          .select('''
            *,
            user_profiles!inner(full_name)
          ''')
          .single();

      // Update ticket's updated_at timestamp
      await supabase
          .from('support_tickets')
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', ticketId);

      final senderName = messageResponse['user_profiles']['full_name'] as String? ?? 'Unknown';
      final messageMap = Map<String, dynamic>.from(messageResponse);
      messageMap['sender_name'] = senderName;
      messageMap.remove('user_profiles');

      return SupportMessageModel.fromJson(messageMap);
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  /// Update ticket status
  Future<SupportTicketModel> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    try {
      final updateData = {
        'status': status.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == TicketStatus.resolved) {
        updateData['resolved_at'] = DateTime.now().toIso8601String();
      } else if (status == TicketStatus.closed) {
        updateData['closed_at'] = DateTime.now().toIso8601String();
      }

      final response = await supabase
          .from('support_tickets')
          .update(updateData)
          .eq('id', ticketId)
          .select('''
            *,
            support_categories!inner(name)
          ''')
          .single();

      final categoryName = response['support_categories']['name'] as String;
      final ticketMap = Map<String, dynamic>.from(response);
      ticketMap['category_name'] = categoryName;
      ticketMap.remove('support_categories');

      return SupportTicketModel.fromJson(ticketMap);
    } catch (e) {
      throw Exception('Failed to update ticket status: $e');
    }
  }

  /// Update ticket priority
  Future<SupportTicketModel> updateTicketPriority({
    required String ticketId,
    required TicketPriority priority,
  }) async {
    try {
      final response = await supabase
          .from('support_tickets')
          .update({
            'priority': priority.toJson(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', ticketId)
          .select('''
            *,
            support_categories!inner(name)
          ''')
          .single();

      final categoryName = response['support_categories']['name'] as String;
      final ticketMap = Map<String, dynamic>.from(response);
      ticketMap['category_name'] = categoryName;
      ticketMap.remove('support_categories');

      return SupportTicketModel.fromJson(ticketMap);
    } catch (e) {
      throw Exception('Failed to update ticket priority: $e');
    }
  }

  /// Close a ticket
  Future<SupportTicketModel> closeTicket(String ticketId) async {
    return updateTicketStatus(
      ticketId: ticketId,
      status: TicketStatus.closed,
    );
  }

  /// Reopen a closed ticket
  Future<SupportTicketModel> reopenTicket(String ticketId) async {
    return updateTicketStatus(
      ticketId: ticketId,
      status: TicketStatus.open,
    );
  }

  /// Get ticket statistics for current user
  Future<Map<String, int>> getUserTicketStats() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .rpc('get_user_ticket_stats', params: {'p_user_id': userId});

      if (response == null || response.isEmpty) {
        return {
          'total_tickets': 0,
          'open_tickets': 0,
          'in_progress_tickets': 0,
          'resolved_tickets': 0,
          'closed_tickets': 0,
        };
      }

      final stats = (response as List).first as Map<String, dynamic>;
      return {
        'total_tickets': stats['total_tickets'] as int? ?? 0,
        'open_tickets': stats['open_tickets'] as int? ?? 0,
        'in_progress_tickets': stats['in_progress_tickets'] as int? ?? 0,
        'resolved_tickets': stats['resolved_tickets'] as int? ?? 0,
        'closed_tickets': stats['closed_tickets'] as int? ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to fetch ticket statistics: $e');
    }
  }

  /// Upload an attachment
  Future<SupportAttachmentModel> uploadAttachment({
    required String ticketId,
    required String filePath,
    String? messageId,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File not found: $filePath');
      }

      final fileName = file.uri.pathSegments.last;
      final fileBytes = await file.readAsBytes();
      final fileSize = await file.length();

      // Upload to Supabase Storage
      final storagePath = 'support_attachments/$ticketId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await supabase.storage
          .from('support-files')
          .uploadBinary(storagePath, fileBytes);

      // Get public URL
      final publicUrl = supabase.storage
          .from('support-files')
          .getPublicUrl(storagePath);

      // Create attachment record
      final response = await supabase
          .from('support_ticket_attachments')
          .insert({
            'ticket_id': ticketId,
            'message_id': messageId,
            'file_name': fileName,
            'file_path': publicUrl,
            'file_size': fileSize,
            'mime_type': _getMimeType(fileName),
            'uploaded_by': userId,
          })
          .select()
          .single();

      return SupportAttachmentModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to upload attachment: $e');
    }
  }

  /// Delete an attachment
  Future<void> deleteAttachment(String attachmentId) async {
    try {
      // Get attachment details first
      final attachment = await supabase
          .from('support_ticket_attachments')
          .select()
          .eq('id', attachmentId)
          .single();

      final filePath = attachment['file_path'] as String;

      // Extract storage path from public URL
      final uri = Uri.parse(filePath);
      final pathSegments = uri.pathSegments;
      final storagePathIndex = pathSegments.indexOf('support-files') + 1;
      final storagePath = pathSegments.sublist(storagePathIndex).join('/');

      // Delete from storage
      await supabase.storage
          .from('support-files')
          .remove([storagePath]);

      // Delete record
      await supabase
          .from('support_ticket_attachments')
          .delete()
          .eq('id', attachmentId);
    } catch (e) {
      throw Exception('Failed to delete attachment: $e');
    }
  }

  /// Helper to determine MIME type from file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
