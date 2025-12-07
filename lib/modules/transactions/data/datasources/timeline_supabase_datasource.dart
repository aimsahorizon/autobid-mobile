import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase datasource for transaction timeline events
/// Tracks transaction progress history
class TimelineSupabaseDataSource {
  final SupabaseClient _supabase;

  TimelineSupabaseDataSource(this._supabase);

  /// Get timeline events for a transaction
  /// Ordered by most recent first
  Future<List<Map<String, dynamic>>> getTimeline(String transactionId) async {
    try {
      final response = await _supabase
          .from('transaction_timeline')
          .select()
          .eq('transaction_id', transactionId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      throw Exception('Failed to get timeline: ${e.message}');
    } catch (e) {
      throw Exception('Failed to get timeline: $e');
    }
  }

  /// Add a timeline event
  /// Creates new event in transaction history
  Future<void> addTimelineEvent({
    required String transactionId,
    required String title,
    required String description,
    required String eventType,
    String? actorId,
    String? actorName,
  }) async {
    try {
      await _supabase.from('transaction_timeline').insert({
        'transaction_id': transactionId,
        'title': title,
        'description': description,
        'event_type': eventType,
        'actor_id': actorId,
        'actor_name': actorName,
      });
    } on PostgrestException catch (e) {
      throw Exception('Failed to add timeline event: ${e.message}');
    } catch (e) {
      throw Exception('Failed to add timeline event: $e');
    }
  }
}
