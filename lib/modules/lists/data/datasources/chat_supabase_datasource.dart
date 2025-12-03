import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for chat/messaging in transactions
/// Handles real-time messaging between buyer and seller
class ChatSupabaseDataSource {
  final SupabaseClient _supabase;

  ChatSupabaseDataSource(this._supabase);

  /// Get all messages for a transaction
  /// Ordered by timestamp ascending (oldest first)
  Future<List<Map<String, dynamic>>> getMessages(String transactionId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select('id, sender_id, message, message_type, attachment_url, is_read, created_at, user_profiles!sender_id(username, profile_photo_url)')
          .eq('transaction_id', transactionId)
          .order('created_at');

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get messages: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Send a text message
  /// Inserts into chat_messages table
  Future<void> sendMessage({
    required String transactionId,
    required String senderId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
  }) async {
    try {
      await _supabase.from('chat_messages').insert({
        'transaction_id': transactionId,
        'sender_id': senderId,
        'message': message,
        'message_type': messageType,
        'attachment_url': attachmentUrl,
        'is_read': false,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to send message: ${e.message}');
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark messages as read for a specific user
  /// Updates all unread messages from other party
  Future<void> markAsRead(String transactionId, String currentUserId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('transaction_id', transactionId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);
    } on PostgrestException catch (e) {
      throw Exception('Failed to mark messages as read: ${e.message}');
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Get unread message count for a transaction
  /// Counts messages from other party that are unread
  Future<int> getUnreadCount(String transactionId, String currentUserId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('transaction_id', transactionId)
          .neq('sender_id', currentUserId)
          .eq('is_read', false);

      return (response as List).length;
    } on PostgrestException catch (e) {
      throw Exception('Failed to get unread count: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get unread count: $e');
    }
  }

  /// Stream messages in real-time
  /// Listen for new messages as they arrive
  Stream<List<Map<String, dynamic>>> streamMessages(String transactionId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('transaction_id', transactionId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }
}
